import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/local_bill_repository.dart';
import '../storage/local_receipt_storage.dart';
import '../storage/supabase_storage_service.dart';

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
        final participants = (payload['participants'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (value) => Map<String, dynamic>.from(value)
                ..remove('bill_id')
                ..remove('status'),
            )
            .toList();
        final bill = Map<String, dynamic>.from(payload['bill'] as Map);
        final localId =
            payload['local_id']?.toString() ?? bill['id']?.toString();
        final localImagePath = payload['local_image_path']?.toString();
        if (localImagePath != null && localImagePath.isNotEmpty) {
          final imageBytes = await readLocalReceipt(localImagePath);
          if (imageBytes == null) {
            throw StateError('ไม่พบรูปใบเสร็จที่บันทึกไว้ในเครื่อง');
          }
          bill['image_url'] = await SupabaseStorageService(client: _client)
              .uploadReceiptBytes(
                imageBytes,
                localId ?? 'offline',
                fileName: 'receipt.jpg',
              );
        }
        final createdId = await _client.rpc(
          'create_bill_with_participants',
          params: {'p_bill': bill, 'p_participants': participants},
        );
        if (localId != null && createdId is String && createdId.isNotEmpty) {
          await LocalBillRepository().replaceCachedBillId(localId, createdId);
        } else {
          throw StateError('Supabase did not return the created bill ID');
        }
        return;
      case 'update_bill':
        final payload = operation.payload;
        await _client
            .from('bills')
            .update(Map<String, dynamic>.from(payload['data'] as Map))
            .eq('id', payload['id'].toString());
        return;
      case 'update_profile':
        final payload = operation.payload;
        await _client
            .from('profiles')
            .update(Map<String, dynamic>.from(payload['data'] as Map))
            .eq('id', payload['id'].toString());
        return;
      case 'add_room_guest_member':
        final payload = operation.payload;
        final roomCode = payload['room_code'].toString();
        final lobby = await _client
            .from('lobbies')
            .select('receipt_json')
            .eq('room_code', roomCode)
            .maybeSingle();
        if (lobby == null) throw StateError('ไม่พบห้องที่รอซิงก์สมาชิก');
        final rawReceipt = lobby['receipt_json'];
        final receipt = rawReceipt is Map
            ? Map<String, dynamic>.from(rawReceipt)
            : <String, dynamic>{};
        final rawMembers = receipt['room_members'];
        final members = rawMembers is Iterable
            ? rawMembers
                  .whereType<Map>()
                  .map((member) => Map<String, dynamic>.from(member))
                  .toList()
            : <Map<String, dynamic>>[];
        final member = Map<String, dynamic>.from(payload['member'] as Map);
        final memberId = member['id']?.toString();
        if (!members.any((item) => item['id']?.toString() == memberId)) {
          members.add(member);
        }
        receipt['room_members'] = members;
        await _client
            .from('lobbies')
            .update({'receipt_json': receipt})
            .eq('room_code', roomCode);
        return;
      case 'update_participant':
        final payload = operation.payload;
        await _client
            .from('bill_participants')
            .update(Map<String, dynamic>.from(payload['data'] as Map))
            .eq('bill_id', payload['bill_id'].toString())
            .eq('profile_id', payload['profile_id'].toString());
        return;
      case 'submit_bill_payment':
        final payload = operation.payload;
        var slipData = payload['slip_data'].toString();
        const localFilePrefix = 'local-file:';
        if (slipData.startsWith(localFilePrefix)) {
          final localPath = slipData.substring(localFilePrefix.length);
          final imageBytes = await readLocalReceipt(localPath);
          if (imageBytes == null) {
            throw StateError('ไม่พบสลิปที่บันทึกไว้ในเครื่อง');
          }
          slipData = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
        }
        await _client.rpc(
          'submit_bill_payment',
          params: {
            'p_bill_id': payload['bill_id'].toString(),
            'p_profile_id': payload['profile_id'].toString(),
            'p_slip_data': slipData,
          },
        );
        return;
      case 'set_bill_payment_status':
        final payload = operation.payload;
        await _client.rpc(
          'set_bill_payment_status',
          params: {
            'p_bill_id': payload['bill_id'].toString(),
            'p_profile_id': payload['profile_id'].toString(),
            'p_status': payload['status'].toString(),
          },
        );
        return;
      default:
        throw StateError('Unknown offline operation: ${operation.type}');
    }
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
