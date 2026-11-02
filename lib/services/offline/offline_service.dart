import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineOperation {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const OfflineOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'].toString(),
      type: json['type'].toString(),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
  };
}

class OfflineQueue {
  static const _storageKey = 'snap2bill_offline_operations';
  final SharedPreferencesAsync _preferences;

  OfflineQueue({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<List<OfflineOperation>> readAll() async {
    final values = await _preferences.getStringList(_storageKey) ?? [];
    return values
        .map(
          (value) => OfflineOperation.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();
  }

  Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final operations = await readAll();
    operations.add(
      OfflineOperation(
        id: '${DateTime.now().microsecondsSinceEpoch}-$type',
        type: type,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
    await _save(operations);
  }

  Future<void> remove(String id) async {
    final operations = await readAll();
    await _save(operations.where((operation) => operation.id != id).toList());
  }

  Future<void> _save(List<OfflineOperation> operations) {
    return _preferences.setStringList(
      _storageKey,
      operations.map((operation) => jsonEncode(operation.toJson())).toList(),
    );
  }
}

class OfflineService extends ChangeNotifier {
  OfflineService({
    Connectivity? connectivity,
    OfflineQueue? queue,
    SupabaseClient? client,
  }) : _connectivity = connectivity ?? Connectivity(),
       queue = queue ?? OfflineQueue(),
       _client = client ?? Supabase.instance.client;

  final Connectivity _connectivity;
  final OfflineQueue queue;
  final SupabaseClient _client;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isSyncing => _isSyncing;

  static bool isLikelyNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('failed host lookup') ||
        message.contains('clientexception');
  }

  Future<void> start() async {
    _isOnline = _hasConnection(await _connectivity.checkConnectivity());
    notifyListeners();
    _subscription ??= _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = _hasConnection(results);
      notifyListeners();
      if (wasOffline && _isOnline) unawaited(flush());
    });
    if (_isOnline) await flush();
  }

  Future<void> disposeService() async {
    await _subscription?.cancel();
    _subscription = null;
    dispose();
  }

  Future<void> flush() async {
    if (!_isOnline || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      for (final operation in await queue.readAll()) {
        try {
          await _apply(operation);
          await queue.remove(operation.id);
        } catch (error, stackTrace) {
          debugPrint(
            'Offline operation ${operation.type} is still pending: '
            '$error\n$stackTrace',
          );
          break;
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _apply(OfflineOperation operation) async {
    switch (operation.type) {
      case 'create_bill':
        final payload = operation.payload;
        final inserted = await _client
            .from('bills')
            .insert(Map<String, dynamic>.from(payload['bill'] as Map))
            .select('id')
            .single();
        final participants = (payload['participants'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (value) => <String, dynamic>{
                ...Map<String, dynamic>.from(value),
                'bill_id': inserted['id'],
              },
            )
            .toList();
        if (participants.isNotEmpty) {
          await _client.from('bill_participants').insert(participants);
        }
        return;
      case 'update_bill':
        final payload = operation.payload;
        await _client
            .from('bills')
            .update(Map<String, dynamic>.from(payload['data'] as Map))
            .eq('id', payload['id'].toString());
        return;
      case 'update_participant':
        final payload = operation.payload;
        await _client
            .from('bill_participants')
            .update(Map<String, dynamic>.from(payload['data'] as Map))
            .eq('bill_id', payload['bill_id'].toString())
            .eq('profile_id', payload['profile_id'].toString());
        return;
      default:
        throw StateError('Unknown offline operation: ${operation.type}');
    }
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
