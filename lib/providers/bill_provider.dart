import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/bill_model.dart';
import '../models/user_model.dart';
import 'contact_provider.dart';
import '../services/supabase_db_service.dart';

class BillProvider with ChangeNotifier {
  final SupabaseDbService _dbService = SupabaseDbService();
  ContactProvider? _contactProvider;

  void setContactProvider(ContactProvider contactProvider) {
    _contactProvider = contactProvider;
  }

  List<BillModel> _bills = [];
  String? _activeRoomCode;
  final List<UserModel> _roomParticipants = [];
  final List<RoomMember> _roomMembers = [];
  bool _isLoading = false;
  bool _isCreatingBill = false;
  String _splitType = 'proportional';
  String? _currentClaimingUserId;

  List<BillModel> get bills => _bills;
  List<UserModel> get roomParticipants => List.unmodifiable(_roomParticipants);
  List<RoomMember> get roomMembers => List.unmodifiable(_roomMembers);
  String get currentClaimingUserId =>
      _currentClaimingUserId ?? _dbService.currentUserId ?? '';
  bool get isLoading => _isLoading;
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
      throw ArgumentError.value(splitType, 'splitType', 'Unsupported split type.');
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
    final equalShareCount = itemTotalsByUser.length;
    return {
      for (final entry in itemTotalsByUser.entries)
        entry.key:
            entry.value +
            (splitType == 'equal'
                ? (equalShareCount > 0 ? extraAmount / equalShareCount : 0)
                : (totalMenuValue > 0
                      ? extraAmount * entry.value / totalMenuValue
                      : 0)),
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
    final index = _roomMembers.indexWhere((existing) => existing.id == member.id);
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

  // ดึงประวัติบิลของเรามาแสดง
  Future<void> loadMyBills() async {
    _isLoading = true;
    notifyListeners();

    _bills = await _dbService.getMyBills();

    _isLoading = false;
    notifyListeners();
  }

  // สร้างบิลใหม่ แล้วยัดใส่บนสุดของลิสต์ให้ผู้ใช้เห็นทันที
  Future<BillModel> createBill(String shopName, double totalAmount) async {
    if (_isCreatingBill) {
      throw StateError('Bill creation is already in progress.');
    }

    _isCreatingBill = true;
    try {
      final newBill = await _dbService.createBill(shopName, totalAmount);
      _bills.insert(0, newBill);
      notifyListeners();
      return newBill;
    } finally {
      _isCreatingBill = false;
    }
  }
}
