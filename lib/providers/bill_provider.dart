import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bill_model.dart';
import '../models/user_model.dart';
import 'contact_provider.dart';
import '../services/firebase_db_service.dart';
import '../repositories/bill_repository.dart';

class BillProvider with ChangeNotifier {
  final FirebaseDbService _dbService;
  final BillRepository _repository;
  ContactProvider? _contactProvider;

  BillProvider({BillRepository? repository, FirebaseDbService? dbService})
    : _repository = repository ?? BillRepository(),
      _dbService = dbService ?? FirebaseDbService();

  void setContactProvider(ContactProvider contactProvider) {
    _contactProvider = contactProvider;
  }

  List<BillModel> _bills = [];
  String? _activeRoomCode;
  final List<UserModel> _roomParticipants = [];
  final List<RoomMember> _roomMembers = [];
  bool _isLoading = false;
  bool _isCreatingBill = false;
  bool _isOffline = false;
  String? _error;
  String _splitType = 'proportional';
  String? _currentClaimingUserId;

  List<BillModel> get bills => _bills;
  List<UserModel> get roomParticipants => List.unmodifiable(_roomParticipants);
  List<RoomMember> get roomMembers => List.unmodifiable(_roomMembers);
  String get currentClaimingUserId =>
      _currentClaimingUserId ?? _dbService.currentUserId ?? '';
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;
  String get splitType => _splitType;

  void setSplitType(String type) {
    if (type != 'equal' && type != 'proportional') {
      throw ArgumentError.value(type, 'type', 'Unsupported split type.');
    }
    if (_splitType == type) return;
    _splitType = type;
    notifyListeners();
  }

  static Map<String, double> calculateUserShares({
    required Iterable<BillItemModel> items,
    required double finalTotal,
    required String splitType,
    Iterable<String> participantIds = const [],
  }) {
    if (splitType != 'equal' && splitType != 'proportional') {
      throw ArgumentError.value(
        splitType,
        'splitType',
        'Unsupported split type.',
      );
    }

    final itemTotalsByUser = <String, double>{
      for (final id in participantIds)
        if (id.isNotEmpty) id: 0,
    };
    var totalMenuValue = 0.0;

    for (final item in items) {
      totalMenuValue += item.price * item.quantity;
      final personalClaims = item.userQuantities.isNotEmpty
          ? item.userQuantities
          : {
              for (final userId in item.claimedBy.toSet())
                if (userId.isNotEmpty) userId: 1,
            };
      var unallocatedQuantity = item.quantity;

      for (final claim in personalClaims.entries) {
        if (claim.key.isEmpty || unallocatedQuantity <= 0) continue;
        final claimedQuantity = claim.value.clamp(0, unallocatedQuantity);
        if (claimedQuantity == 0) continue;
        itemTotalsByUser[claim.key] =
            (itemTotalsByUser[claim.key] ?? 0) + item.price * claimedQuantity;
        unallocatedQuantity -= claimedQuantity;
      }

      final sharedUsers = item.sharedUsers.where((id) => id.isNotEmpty).toSet();
      if (unallocatedQuantity > 0 && sharedUsers.isNotEmpty) {
        final sharedAmount =
            item.price * unallocatedQuantity / sharedUsers.length;
        for (final userId in sharedUsers) {
          itemTotalsByUser[userId] =
              (itemTotalsByUser[userId] ?? 0) + sharedAmount;
        }
      }
    }

    final extraAmount = finalTotal - totalMenuValue;
    final activeEaterIds = itemTotalsByUser.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toSet();
    final activeCount = activeEaterIds.isNotEmpty
        ? activeEaterIds.length
        : itemTotalsByUser.length;

    return {
      for (final entry in itemTotalsByUser.entries)
        entry.key:
            activeEaterIds.isNotEmpty && !activeEaterIds.contains(entry.key)
            ? 0.0
            : entry.value +
                  (splitType == 'equal'
                      ? (activeCount > 0 ? extraAmount / activeCount : 0.0)
                      : (totalMenuValue > 0
                            ? extraAmount * entry.value / totalMenuValue
                            : 0.0)),
    };
  }

  void setActiveRoom(String roomCode) {
    if (_activeRoomCode == roomCode) return;
    _activeRoomCode = roomCode;
    _roomParticipants.clear();
    _roomMembers.clear();
    _currentClaimingUserId = _dbService.currentUserId;
    _splitType = 'proportional';
    notifyListeners();
  }

  List<UserModel> addRoomParticipants(
    String roomCode,
    Iterable<UserModel> participants,
  ) {
    setActiveRoom(roomCode);
    final participantIds = _roomParticipants.map((user) => user.id).toSet();
    var changed = false;
    for (final participant in participants) {
      if (participant.id.isEmpty || !participantIds.add(participant.id)) {
        continue;
      }
      _roomParticipants.add(participant);
      final member = RoomMember(
        id: participant.id,
        name: participant.displayName?.trim().isNotEmpty == true
            ? participant.displayName!.trim()
            : participant.email?.split('@').first ?? 'เพื่อน',
        avatarUrl: participant.avatarUrl,
      );
      _mergeRoomMember(member);
      if (member.id != _dbService.currentUserId) _saveContact(member.name);
      changed = true;
    }
    if (changed) notifyListeners();
    return roomParticipants;
  }

  Future<void> loadRoomMembers(String roomCode) async {
    final members = await _dbService.getRoomGuestMembers(roomCode);
    mergeRoomMembers(members);
  }

  Future<RoomMember> addGuestMember(String guestName) async {
    final name = guestName.trim();
    if (name.isEmpty) throw ArgumentError.value(guestName, 'guestName');
    final roomCode = _activeRoomCode;
    if (roomCode == null || roomCode.isEmpty) {
      throw StateError('ยังไม่ได้เลือกห้อง');
    }
    final member = RoomMember(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isGuest: true,
    );
    final savedMember = await _dbService.addRoomGuestMember(roomCode, member);
    mergeRoomMembers([savedMember]);
    await _saveContact(name);
    return savedMember;
  }

  Future<void> saveRoomMemberContacts(Iterable<RoomMember> members) async {
    for (final member in members) {
      if (!member.isGuest && member.id == _dbService.currentUserId) continue;
      await _saveContact(member.name);
    }
  }

  Future<void> _saveContact(String name) async {
    final contactProvider = _contactProvider;
    if (contactProvider == null) return;
    try {
      await contactProvider.saveContactIfNotExists(name);
    } catch (error, stackTrace) {
      debugPrint('บันทึกชื่อเพื่อนในสมุดรายชื่อไม่สำเร็จ: $error\n$stackTrace');
    }
  }

  void mergeRoomMembers(Iterable<RoomMember> members) {
    var changed = false;
    for (final member in members) {
      changed = _mergeRoomMember(member) || changed;
    }
    if (changed) notifyListeners();
  }

  bool _mergeRoomMember(RoomMember member) {
    if (member.id.isEmpty) return false;
    final index = _roomMembers.indexWhere(
      (existing) => existing.id == member.id,
    );
    if (index >= 0) return false;
    _roomMembers.add(member);
    return true;
  }

  void setClaimingUser(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    if (_currentClaimingUserId == userId) return;
    _currentClaimingUserId = userId;
    notifyListeners();
  }

  Future<void> loadBills({String? userId}) async {
    final activeUserId = userId ?? _dbService.currentUserId;
    if (activeUserId == null || activeUserId.isEmpty) {
      _bills = [];
      _isOffline = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final localBills = await _repository.getBills(
        userId: activeUserId,
        syncInBackground: false,
      );
      _replaceBills(localBills);
      _isLoading = false;
      notifyListeners();
      unawaited(_syncAndRefresh(activeUserId));
    } catch (error, stackTrace) {
      debugPrint('Failed to load local bills: $error\n$stackTrace');
      _error = 'โหลดประวัติบิลจากเครื่องไม่สำเร็จ: $error';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyBills() => loadBills();

  Future<void> _syncAndRefresh(String userId) async {
    try {
      _isOffline = !await _repository.hasNetworkConnection();
      notifyListeners();
      if (_isOffline) return;
      await _repository.syncWithCloud(userId: userId);
      _replaceBills(
        await _repository.getBills(userId: userId, syncInBackground: false),
      );
      _error = null;
    } catch (error, stackTrace) {
      debugPrint('Failed to sync bills with cloud: $error\n$stackTrace');
      _isOffline = true;
      _error = 'ซิงค์บิลไม่สำเร็จ จะแสดงข้อมูลในเครื่อง: $error';
    }
    notifyListeners();
  }

  void _replaceBills(Iterable<Map<String, dynamic>> rows) {
    _bills = rows
        .map((row) {
          final normalized = <String, dynamic>{
            ...row,
            'id': row['id']?.toString() ?? '',
            'owner_id':
                row['owner_id']?.toString() ??
                row['userId']?.toString() ??
                _dbService.currentUserId ??
                '',
          };
          return BillModel.fromJson(normalized);
        })
        .where((bill) => bill.id.isNotEmpty)
        .toList();
  }

  Future<BillModel> createBill(
    String shopName,
    double totalAmount, {
    List<Map<String, dynamic>> items = const [],
    Map<String, dynamic>? receiptData,
    Map<String, dynamic>? sharers,
    Map<String, double> participantTotals = const {},
    Uint8List? imageBytes,
    String? localImagePath,
    String status = 'draft',
  }) async {
    if (_isCreatingBill) {
      throw StateError('Bill creation is already in progress.');
    }
    final userId = _dbService.currentUserId;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนสร้างบิล');

    _isCreatingBill = true;
    _error = null;
    notifyListeners();
    try {
      final billId = _dbService.newBillId();
      final receiptJson = {
        ...?receiptData,
        if (items.isNotEmpty) 'items': items,
      };
      await _repository.createBillLocally(
        billId: billId,
        userId: userId,
        bill: {
          'owner_id': userId,
          'shop_name': shopName,
          'total_amount': totalAmount,
          'sub_total': totalAmount,
          'status': status,
          'receipt_date': DateTime.now().toIso8601String(),
          'receipt_json': receiptJson,
          'sharers_json': sharers,
        },
        participantTotals: participantTotals,
        imageBytes: imageBytes,
        localImagePath: localImagePath,
        items: items,
      );
      final newBill = BillModel.fromJson({
        'id': billId,
        'owner_id': userId,
        'shop_name': shopName,
        'total_amount': totalAmount,
        'final_total': totalAmount,
        'receipt_date': DateTime.now().toIso8601String(),
        'status': status,
        'split_type': receiptJson['split_type'],
      });
      _bills.insert(0, newBill);
      notifyListeners();
      unawaited(_syncAndRefresh(userId));
      return newBill;
    } catch (error, stackTrace) {
      debugPrint('Failed to create local bill: $error\n$stackTrace');
      _error = 'บันทึกบิลในเครื่องไม่สำเร็จ: $error';
      rethrow;
    } finally {
      _isCreatingBill = false;
      notifyListeners();
    }
  }

  Future<void> updateBill({
    required String billId,
    required Map<String, dynamic> data,
  }) async {
    final userId = _dbService.currentUserId;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนแก้ไขบิล');
    await _repository.updateBillLocally(
      billId: billId,
      userId: userId,
      data: data,
    );
    _replaceBills(
      await _repository.getBills(userId: userId, syncInBackground: false),
    );
    notifyListeners();
    unawaited(_syncAndRefresh(userId));
  }

  Future<void> updateParticipantStatus({
    required String billId,
    required String profileId,
    required String status,
  }) async {
    final userId = _dbService.currentUserId;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนแก้ไขสถานะบิล');
    await _repository.updateParticipantStatusLocally(
      billId: billId,
      userId: userId,
      profileId: profileId,
      status: status,
    );
    _replaceBills(
      await _repository.getBills(userId: userId, syncInBackground: false),
    );
    notifyListeners();
    unawaited(_syncAndRefresh(userId));
  }

  @override
  void dispose() {
    unawaited(_repository.dispose());
    super.dispose();
  }
}
