import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../services/firebase_db_service.dart';
import '../services/supabase_storage_service.dart';
import 'local_bill_repository.dart';

class BillRepository {
  static final AppDatabase _sharedDatabase = AppDatabase();

  final AppDatabase _db;
  final FirebaseDbService _firebaseDb;
  final SupabaseStorageService _storage;
  final Connectivity _connectivity;
  final Set<String> _syncingUsers = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _watchedUserId;

  BillRepository({
    AppDatabase? database,
    FirebaseDbService? firebaseDb,
    SupabaseStorageService? storage,
    Connectivity? connectivity,
  }) : _db = database ?? _sharedDatabase,
       _firebaseDb = firebaseDb ?? FirebaseDbService(),
       _storage = storage ?? SupabaseStorageService(),
       _connectivity = connectivity ?? Connectivity();

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _watchedUserId = null;
  }

  Future<bool> hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
  }

  Stream<List<Map<String, dynamic>>> getBillsStream({required String? userId}) {
    if (userId == null || userId.isEmpty) return Stream.value([]);
    _watchConnectivity(userId);
    _syncInBackground(userId);
    return _db.watchCachedBillsForUser(userId).map((rows) => _mapRows(rows));
  }

  Future<List<Map<String, dynamic>>> getBills({
    required String? userId,
    bool syncInBackground = true,
  }) async {
    if (userId == null || userId.isEmpty) return [];
    _watchConnectivity(userId);
    await _db.assignLegacyBillsToUser(userId);
    if (syncInBackground) _syncInBackground(userId);
    return _mapRows(await _db.getCachedBillsForUser(userId));
  }

  Future<String> createBillLocally({
    required String billId,
    required String userId,
    required Map<String, dynamic> bill,
    required Map<String, double> participantTotals,
    Uint8List? imageBytes,
    String? localImagePath,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final image = imageBytes != null
        ? await _saveImageLocally(billId, imageBytes)
        : (path: localImagePath, bytes: null);
    final receiptJson = _mapFromJson(bill['receipt_json']);
    if (items.isNotEmpty) receiptJson['items'] = items;
    receiptJson['participant_totals'] = participantTotals;

    await _db.saveCachedBill(
      CachedBillsCompanion(
        id: Value(billId),
        shopName: Value(bill['shop_name']?.toString()),
        totalAmount: Value(
          _asDouble(bill['total_amount'] ?? bill['sub_total']),
        ),
        receiptDate: Value(
          _dateString(bill['receipt_date']) ?? DateTime.now().toIso8601String(),
        ),
        status: Value(bill['status']?.toString() ?? 'completed'),
        receiptJson: Value(jsonEncode(receiptJson)),
        sharersJson: Value(_jsonString(bill['sharers_json'])),
        localImagePath: Value(image.path),
        localImageBytes: Value(image.bytes),
        receiptImageUrl: Value(bill['receipt_image_url']?.toString()),
        ownerId: Value(userId),
        cachedForUserId: Value(userId),
        syncedWithServer: const Value(false),
        cachedAt: Value(DateTime.now()),
      ),
    );
    return billId;
  }

  Future<void> updateBillLocally({
    required String billId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final existing = await _db.getCachedBill(billId);
    if (existing == null || existing.cachedForUserId != userId) {
      throw StateError('ไม่พบบิลในเครื่องที่ต้องการแก้ไข');
    }

    final receiptJson = _mapFromJson(existing.receiptJson)
      ..addAll(_mapFromJson(data['receipt_json']));
    if (data['items'] is List) receiptJson['items'] = data['items'];
    if (data['participant_totals'] is Map) {
      receiptJson['participant_totals'] = data['participant_totals'];
    }
    if (data['participant_statuses'] is Map) {
      receiptJson['participant_statuses'] = data['participant_statuses'];
    }

    await _db.updateCachedBill(
      billId,
      CachedBillsCompanion(
        shopName: data.containsKey('shop_name')
            ? Value(data['shop_name']?.toString())
            : const Value.absent(),
        totalAmount:
            data.containsKey('total_amount') || data.containsKey('sub_total')
            ? Value(_asDouble(data['total_amount'] ?? data['sub_total']))
            : const Value.absent(),
        status: data.containsKey('status')
            ? Value(data['status']?.toString() ?? 'draft')
            : const Value.absent(),
        receiptJson: Value(jsonEncode(receiptJson)),
        sharersJson: data.containsKey('sharers_json')
            ? Value(_jsonString(data['sharers_json']))
            : const Value.absent(),
        syncedWithServer: const Value(false),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateParticipantStatusLocally({
    required String billId,
    required String userId,
    required String profileId,
    required String status,
  }) async {
    final bill = await _db.getCachedBill(billId);
    if (bill == null || bill.cachedForUserId != userId) {
      throw StateError('ไม่พบบิลในเครื่องที่ต้องการแก้ไข');
    }
    final receiptJson = _mapFromJson(bill.receiptJson);
    final statuses = _mapFromJson(receiptJson['participant_statuses']);
    statuses[profileId] = status;
    await updateBillLocally(
      billId: billId,
      userId: userId,
      data: {'participant_statuses': statuses},
    );
  }

  Future<void> syncWithCloud({required String userId}) async {
    if (_syncingUsers.contains(userId)) return;
    _syncingUsers.add(userId);
    try {
      await _db.assignLegacyBillsToUser(userId);
      debugPrint('[Sync] Checking internet connectivity...');
      final List<ConnectivityResult> connectivity;
      try {
        connectivity = await _connectivity.checkConnectivity();
      } catch (error, stackTrace) {
        debugPrint(
          '[Sync] Checking internet connectivity: FAILED: $error\n$stackTrace',
        );
        rethrow;
      }
      if (connectivity.isEmpty ||
          connectivity.every((result) => result == ConnectivityResult.none)) {
        debugPrint('[Sync] No internet connection; cloud sync skipped.');
        return;
      }

      final pendingBills = await _db.getUnsyncedBills(userId);
      debugPrint(
        '[Sync] Found ${pendingBills.length} bills pending sync in Drift',
      );
      for (final bill in pendingBills) {
        var imageUrl = bill.receiptImageUrl;
        if ((imageUrl == null || imageUrl.isEmpty) &&
            (bill.localImagePath != null || bill.localImageBytes != null)) {
          debugPrint(
            '[Sync] Uploading receipt to Supabase Storage for bill ${bill.id}...',
          );
          try {
            final imageBytes = await _readLocalImage(bill);
            imageUrl = await _storage.uploadReceiptBytes(imageBytes, bill.id);
            await _db.updateCachedBill(
              bill.id,
              CachedBillsCompanion(
                receiptImageUrl: Value(imageUrl),
                cachedAt: Value(DateTime.now()),
              ),
            );
            debugPrint(
              '[Sync] Uploading receipt to Supabase Storage: SUCCESS '
              '(bill ${bill.id})',
            );
          } catch (error, stackTrace) {
            debugPrint(
              '[Sync] Uploading receipt to Supabase Storage: FAILED '
              '(bill ${bill.id}): $error\n$stackTrace',
            );
            rethrow;
          }
        }

        final receiptJson = _mapFromJson(bill.receiptJson);
        final participantTotals = _doubleMap(
          receiptJson.remove('participant_totals'),
        );
        final participantStatuses = _mapFromJson(
          receiptJson.remove('participant_statuses'),
        );
        debugPrint(
          '[Sync] Pushing document to Cloud Firestore for bill ${bill.id}...',
        );
        try {
          await _firebaseDb.saveCompletedBill(
            billId: bill.id,
            bill: {
              'owner_id': bill.ownerId ?? userId,
              'shop_name': bill.shopName,
              'sub_total': bill.totalAmount,
              'total_amount': bill.totalAmount,
              'status': bill.status,
              'receipt_date': bill.receiptDate,
              'receipt_image_url': imageUrl,
              'receipt_json': receiptJson,
              'sharers_json': _mapFromJson(bill.sharersJson),
            },
            participantTotals: participantTotals,
          );
          for (final entry in participantStatuses.entries) {
            await _firebaseDb.updateParticipantStatus(
              bill.id,
              entry.key,
              entry.value.toString(),
            );
          }
          debugPrint(
            '[Sync] Pushing document to Cloud Firestore: SUCCESS '
            '(bill ${bill.id})',
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[Sync] Pushing document to Cloud Firestore: FAILED '
            '(bill ${bill.id}): $error\n$stackTrace',
          );
          rethrow;
        }
        try {
          await _db.updateCachedBill(
            bill.id,
            CachedBillsCompanion(
              syncedWithServer: const Value(true),
              cachedAt: Value(DateTime.now()),
            ),
          );
          debugPrint(
            '[Sync] Updated local Drift status: syncedWithServer = true '
            '(bill ${bill.id})',
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[Sync] Updating local Drift status: FAILED '
            '(bill ${bill.id}): $error\n$stackTrace',
          );
          rethrow;
        }
      }

      final cloudBills = await _firebaseDb.getBillsForUser(userId);
      for (final bill in cloudBills) {
        final billId = bill['id']?.toString();
        if (billId == null || billId.isEmpty) continue;

        final receiptJson = _mapFromJson(bill['receipt_json']);
        final items = await _firebaseDb.getBillItems(billId);
        if (items.isNotEmpty) receiptJson['items'] = items;

        final participants = await _firebaseDb.getBillParticipants(billId);
        final participantTotals = <String, double>{};
        final participantStatuses = <String, String>{};
        for (final participant in participants) {
          final participantId = participant['profile_id']?.toString();
          if (participantId == null || participantId.isEmpty) continue;
          participantTotals[participantId] = _asDouble(
            participant['amount_owed'],
          );
          final status = participant['status']?.toString();
          if (status != null) participantStatuses[participantId] = status;
        }
        if (participantTotals.isNotEmpty) {
          receiptJson['participant_totals'] = participantTotals;
        }
        if (participantStatuses.isNotEmpty) {
          receiptJson['participant_statuses'] = participantStatuses;
        }

        bill['receipt_json'] = receiptJson;
        bill['created_at'] =
            _dateString(bill['created_at'] ?? bill['createdAt']) ??
            DateTime.now().toIso8601String();
        bill['total_amount'] ??= bill['sub_total'];
      }
      await LocalBillRepository(
        db: _db,
      ).cacheFirebaseBills(cloudBills, cachedForUserId: userId);
    } finally {
      _syncingUsers.remove(userId);
    }
  }

  void _watchConnectivity(String userId) {
    _watchedUserId = userId;
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen(
      (results) {
        final activeUserId = _watchedUserId;
        if (activeUserId == null ||
            results.isEmpty ||
            results.every((result) => result == ConnectivityResult.none)) {
          return;
        }
        _syncInBackground(activeUserId);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Bill sync connectivity listener failed: $error');
      },
    );
  }

  void _syncInBackground(String userId) {
    unawaited(
      syncWithCloud(userId: userId).catchError((
        Object error,
        StackTrace stack,
      ) {
        debugPrint('Bill sync failed for user $userId: $error\n$stack');
      }),
    );
  }

  Future<({String? path, Uint8List? bytes})> _saveImageLocally(
    String billId,
    Uint8List bytes,
  ) async {
    if (kIsWeb) return (path: null, bytes: bytes);

    final directory = await getApplicationSupportDirectory();
    final cacheDirectory = Directory(p.join(directory.path, 'receipt_cache'));
    await cacheDirectory.create(recursive: true);
    final fileName = '${base64Url.encode(utf8.encode(billId))}.image';
    final imageFile = File(p.join(cacheDirectory.path, fileName));
    await imageFile.writeAsBytes(bytes, flush: true);
    return (path: imageFile.path, bytes: null);
  }

  Future<Uint8List> _readLocalImage(CachedBill bill) async {
    final bytes = bill.localImageBytes;
    if (bytes != null) return bytes;
    final path = bill.localImagePath;
    if (path == null || path.isEmpty) {
      throw StateError('ไม่พบไฟล์รูปภาพในเครื่องสำหรับบิล ${bill.id}');
    }
    return File(path).readAsBytes();
  }

  List<Map<String, dynamic>> _mapRows(List<CachedBill> rows) {
    final bills = rows.map((row) {
      return <String, dynamic>{
        'id': row.id,
        'owner_id': row.ownerId,
        'shop_name': row.shopName ?? 'ไม่ระบุชื่อร้าน',
        'total_amount': row.totalAmount,
        'sub_total': row.totalAmount,
        'created_at': row.receiptDate ?? row.cachedAt.toIso8601String(),
        'status': row.status,
        'receipt_json': _decodedJson(row.receiptJson),
        'sharers_json': _decodedJson(row.sharersJson),
        'receipt_image_url': row.receiptImageUrl,
        'receipt_image_local_path': row.localImagePath,
        'receipt_image_bytes': row.localImageBytes,
        'is_cached': true,
        'synced_with_server': row.syncedWithServer,
      };
    }).toList();
    bills.sort(
      (first, second) =>
          _date(first['created_at']).compareTo(_date(second['created_at'])),
    );
    return bills.reversed.toList();
  }

  dynamic _decodedJson(String? value) {
    if (value == null || value.isEmpty) return null;
    return jsonDecode(value);
  }

  Map<String, dynamic> _mapFromJson(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return {};
  }

  Map<String, double> _doubleMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): _asDouble(entry.value),
    };
  }

  String? _jsonString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return jsonEncode(value);
  }

  String? _dateString(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Timestamp) return value.toDate().toIso8601String();
    return value.toString();
  }

  DateTime _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  double _asDouble(Object? value) =>
      value == null ? 0 : double.tryParse(value.toString()) ?? 0;
}
