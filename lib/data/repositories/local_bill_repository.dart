import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/bill_model.dart';
import '../../models/user_model.dart';
import '../../utils/bill_progress_helper.dart';

class LocalBillRepository {
  static final AppDatabase _sharedDatabase = AppDatabase();
  final AppDatabase _db;

  LocalBillRepository({AppDatabase? db}) : _db = db ?? _sharedDatabase;

  AppDatabase get db => _db;

  Future<void> cacheSupabaseBills(List<Map<String, dynamic>> rawBills) async {
    final companions = <CachedBillsCompanion>[];
    for (final b in rawBills) {
      final id = b['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final total = BillProgressHelper.extractBillTotal(b);
      final receiptJsonStr = b['receipt_json'] != null
          ? (b['receipt_json'] is String
                ? b['receipt_json'] as String
                : jsonEncode(b['receipt_json']))
          : null;
      final sharersJsonStr = b['sharers_json'] != null
          ? (b['sharers_json'] is String
                ? b['sharers_json'] as String
                : jsonEncode(b['sharers_json']))
          : null;
      final payload = Map<String, dynamic>.from(b)
        ..remove('is_cached')
        ..remove('local_image_path')
        ..remove('sync_status');
      final existing = await _db.getCachedBill(id);

      companions.add(
        CachedBillsCompanion(
          id: Value(id),
          shopName: Value(b['shop_name']?.toString()),
          totalAmount: Value(total),
          receiptDate: Value(
            b['receipt_date']?.toString() ?? b['created_at']?.toString(),
          ),
          status: Value(b['status']?.toString() ?? 'completed'),
          receiptJson: Value(receiptJsonStr),
          sharersJson: Value(sharersJsonStr),
          payloadJson: Value(jsonEncode(payload)),
          localImagePath: Value(
            b['local_image_path']?.toString() ?? existing?.localImagePath,
          ),
          syncStatus: const Value('synced'),
          cachedAt: Value(DateTime.now()),
        ),
      );
    }
    if (companions.isNotEmpty) await _db.cacheBills(companions);
  }

  Future<List<Map<String, dynamic>>> getCachedBills({
    required String userId,
  }) async {
    final rows = await _db.getAllCachedBills();
    return rows
        .map(_billToMap)
        .where((bill) => _billBelongsToUser(bill, userId))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchCachedBills({
    required String userId,
  }) {
    return _db.watchAllCachedBills().map(
      (rows) => rows
          .map(_billToMap)
          .where((bill) => _billBelongsToUser(bill, userId))
          .toList(),
    );
  }

  Future<Map<String, dynamic>?> getCachedBillData(String id) async {
    final row = await _db.getCachedBill(id);
    return row == null ? null : _billToMap(row);
  }

  Future<void> saveLocalBill({
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> participants,
    String? localImagePath,
    String syncStatus = 'pending',
  }) async {
    final id = bill['id']?.toString() ?? '';
    if (id.isEmpty) throw ArgumentError.value(id, 'bill.id');
    final payload = Map<String, dynamic>.from(bill)
      ..['bill_participants'] = participants
      ..['bill_payments'] = <Map<String, dynamic>>[]
      ..['local_image_path'] = localImagePath
      ..['sync_status'] = syncStatus;
    await _db.cacheBills([
      CachedBillsCompanion(
        id: Value(id),
        shopName: Value(bill['shop_name']?.toString()),
        totalAmount: Value(BillProgressHelper.extractBillTotal(bill)),
        receiptDate: Value(bill['created_at']?.toString()),
        status: Value(bill['status']?.toString() ?? 'pending'),
        receiptJson: Value(_jsonColumn(bill['receipt_json'])),
        sharersJson: Value(_jsonColumn(bill['sharers_json'])),
        payloadJson: Value(jsonEncode(payload)),
        localImagePath: Value(localImagePath),
        syncStatus: Value(syncStatus),
        cachedAt: Value(DateTime.now()),
      ),
    ]);
  }

  Future<void> markBillSynced(String id) async {
    final row = await _db.getCachedBill(id);
    if (row == null) return;
    final bill = _billToMap(row)..['sync_status'] = 'synced';
    await _db.cacheBills([
      CachedBillsCompanion(
        id: Value(id),
        shopName: Value(row.shopName),
        totalAmount: Value(row.totalAmount),
        receiptDate: Value(row.receiptDate),
        status: Value(row.status),
        receiptJson: Value(row.receiptJson),
        sharersJson: Value(row.sharersJson),
        payloadJson: Value(jsonEncode(bill)),
        localImagePath: Value(row.localImagePath),
        syncStatus: const Value('synced'),
        cachedAt: Value(DateTime.now()),
      ),
    ]);
  }

  Future<void> replaceCachedBillId(String oldId, String newId) async {
    if (oldId == newId) {
      await markBillSynced(oldId);
      return;
    }
    final oldRow = await _db.getCachedBill(oldId);
    if (oldRow == null) return;
    final updated = _billToMap(oldRow)
      ..['id'] = newId
      ..['sync_status'] = 'synced';
    await _db.transaction(() async {
      await _db.cacheBills([
        CachedBillsCompanion(
          id: Value(newId),
          shopName: Value(oldRow.shopName),
          totalAmount: Value(oldRow.totalAmount),
          receiptDate: Value(oldRow.receiptDate),
          status: Value(oldRow.status),
          receiptJson: Value(oldRow.receiptJson),
          sharersJson: Value(oldRow.sharersJson),
          payloadJson: Value(jsonEncode(updated)),
          localImagePath: Value(oldRow.localImagePath),
          syncStatus: const Value('synced'),
          cachedAt: Value(DateTime.now()),
        ),
      ]);
      await _db.deleteCachedBill(oldId);
    });
  }

  Future<void> deleteCachedBill(String id) => _db.deleteCachedBill(id);

  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final id = profile['id']?.toString() ?? '';
    if (id.isEmpty) return;
    await _db.cacheProfile(
      CachedProfilesCompanion.insert(id: id, payloadJson: jsonEncode(profile)),
    );
  }

  Future<Map<String, dynamic>?> getCachedProfile(String id) async {
    final profile = await _db.getCachedProfile(id);
    if (profile == null) return null;
    final decoded = jsonDecode(profile.payloadJson);
    if (decoded is! Map) {
      throw FormatException('Cached profile is not a JSON object: $id');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> cacheRoomMembers(
    String roomCode,
    Iterable<RoomMember> members,
  ) async {
    await _db.cacheRoom(
      CachedRoomsCompanion.insert(
        roomCode: roomCode,
        payloadJson: jsonEncode(
          members
              .map(
                (member) => {
                  ...member.toMap(),
                  'local_avatar_path': member.localAvatarPath,
                },
              )
              .toList(),
        ),
      ),
    );
  }

  Future<List<RoomMember>> getCachedRoomMembers(String roomCode) async {
    final room = await _db.getCachedRoom(roomCode);
    if (room == null) return [];
    final decoded = jsonDecode(room.payloadJson);
    if (decoded is! List) {
      throw FormatException(
        'Cached room members are not a JSON list: $roomCode',
      );
    }
    return decoded
        .whereType<Map>()
        .map((member) => RoomMember.fromMap(Map<String, dynamic>.from(member)))
        .where((member) => member.id.isNotEmpty)
        .toList();
  }

  Future<List<UserModel>> getCachedPastParticipants(
    String currentUserId,
  ) async {
    final participantIds = <String>{};
    final namesById = <String, String>{};
    for (final bill in await getCachedBills(userId: currentUserId)) {
      final members = <String>{};
      final ownerId = bill['owner_id']?.toString();
      if (ownerId != null && ownerId.isNotEmpty) members.add(ownerId);
      for (final row in _asList(bill['bill_participants'])) {
        final id = _asMap(row)['profile_id']?.toString();
        if (id != null && id.isNotEmpty) members.add(id);
      }

      final sharers = _asMap(bill['sharers_json']);
      for (final rows in sharers.values) {
        for (final rawSharer in _asList(rows)) {
          final sharer = _asMap(rawSharer);
          final id = sharer['user_id']?.toString();
          if (id == null || id.isEmpty) continue;
          members.add(id);
          final name = sharer['user_name']?.toString().trim();
          if (name?.isNotEmpty == true) namesById[id] = name!;
        }
      }
      if (!members.contains(currentUserId)) continue;
      participantIds.addAll(
        members.where(
          (id) =>
              id != currentUserId &&
              !id.toLowerCase().startsWith('guest_') &&
              !id.toLowerCase().startsWith('guest-') &&
              id.toLowerCase() != 'guest',
        ),
      );
    }

    final cachedProfiles = participantIds.isEmpty
        ? <CachedProfile>[]
        : await _db.getCachedProfiles(participantIds);
    final profilesById = {
      for (final row in cachedProfiles)
        row.id: _asMap(_decodeJson(row.payloadJson)),
    };

    return participantIds.map((id) {
      final profile = profilesById[id] ?? const <String, dynamic>{};
      return UserModel(
        id: id,
        displayName: profile['display_name']?.toString() ?? namesById[id],
        email: profile['email']?.toString(),
        avatarUrl: profile['avatar_url']?.toString(),
        localAvatarPath: profile['local_avatar_path']?.toString(),
      );
    }).toList();
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  List<dynamic> _asList(Object? value) => value is List ? value : const [];

  bool _billBelongsToUser(Map<String, dynamic> bill, String userId) {
    if (userId.isEmpty) return false;
    if (bill['owner_id']?.toString() == userId) return true;

    for (final row in _asList(bill['bill_participants'])) {
      if (_asMap(row)['profile_id']?.toString() == userId) return true;
    }

    final sharers = _asMap(bill['sharers_json']);
    for (final rows in sharers.values) {
      for (final rawSharer in _asList(rows)) {
        if (_asMap(rawSharer)['user_id']?.toString() == userId) return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _billToMap(CachedBill row) {
    Map<String, dynamic>? payload;
    final payloadJson = row.payloadJson;
    if (payloadJson != null && payloadJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(payloadJson);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } on FormatException catch (error, stackTrace) {
        debugPrint(
          'Invalid cached bill payload (${row.id}): $error\n$stackTrace',
        );
      }
    }
    return {
      ...?payload,
      'id': row.id,
      'shop_name': row.shopName ?? 'ไม่ระบุชื่อร้าน',
      'total_amount': row.totalAmount,
      'created_at': row.receiptDate ?? row.cachedAt.toIso8601String(),
      'status': row.status,
      'receipt_json': _decodeJson(row.receiptJson),
      'sharers_json': _decodeJson(row.sharersJson),
      'local_image_path': row.localImagePath,
      'sync_status': row.syncStatus,
      'is_cached': true,
    };
  }

  dynamic _decodeJson(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } on FormatException catch (error, stackTrace) {
      debugPrint('Invalid cached bill JSON: $error\n$stackTrace');
      return null;
    }
  }

  String? _jsonColumn(dynamic value) {
    if (value == null) return null;
    return value is String ? value : jsonEncode(value);
  }

  // Save an offline draft bill
  Future<int> saveDraft({
    required String shopName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) {
    return _db.insertDraft(
      OfflineDraftsCompanion(
        shopName: Value(shopName),
        totalAmount: Value(totalAmount),
        itemsJson: Value(jsonEncode(items)),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<OfflineDraft>> getDrafts() => _db.getAllDrafts();

  Future<int> deleteDraft(int id) => _db.deleteDraft(id);
}
