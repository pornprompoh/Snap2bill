import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/bill_model.dart';
import '../models/user_model.dart';
import 'contact_provider.dart';
import '../data/repositories/local_bill_repository.dart';
import '../data/repositories/supabase_bill_repository.dart';
import '../domain/repositories/bill_repository.dart';
import '../domain/usecases/bill_use_cases.dart';
import '../services/offline/offline_service.dart';

class BillProvider with ChangeNotifier {
  final BillRepository _billRepository;
  late final GetRoomGuestMembers _getRoomGuestMembers;
  late final AddRoomGuestMember _addRoomGuestMember;
  late final GetMyBills _getMyBills;
  late final CreateBill _createBill;
  ContactProvider? _contactProvider;
  late final LocalBillRepository _localRepository = LocalBillRepository();
  late final OfflineQueue _offlineQueue = OfflineQueue();
  OfflineService? _offlineService;

  BillProvider({BillRepository? billRepository})
    : _billRepository = billRepository ?? SupabaseBillRepository() {
    _getRoomGuestMembers = GetRoomGuestMembers(_billRepository);
    _addRoomGuestMember = AddRoomGuestMember(_billRepository);
    _getMyBills = GetMyBills(_billRepository);
    _createBill = CreateBill(_billRepository);
  }

  void setContactProvider(ContactProvider contactProvider) {
    _contactProvider = contactProvider;
  }

  void setOfflineService(OfflineService offlineService) {
    _offlineService = offlineService;
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
      _currentClaimingUserId ?? _billRepository.currentUserId ?? '';
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
    final validItems = items.where(
      (it) => it.price > 0 && it.itemName.trim().isNotEmpty,
    );

    for (final item in validItems) {
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
            (item.price * unallocatedQuantity / sharedUsers.length)
                .ceilToDouble();
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
            : (entry.value +
                      (splitType == 'equal'
                          ? (activeCount > 0 ? extraAmount / activeCount : 0.0)
                          : (totalMenuValue > 0
                                ? extraAmount * entry.value / totalMenuValue
                                : 0.0)))
                  .ceilToDouble(),
    };
  }

  void setActiveRoom(String roomCode) {
    if (_activeRoomCode == roomCode) return;
    _activeRoomCode = roomCode;
    _roomParticipants.clear();
    _roomMembers.clear();
    _currentClaimingUserId = _billRepository.currentUserId;
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
        localAvatarPath: participant.localAvatarPath,
      );
      _mergeRoomMember(member);
      if (member.id != _billRepository.currentUserId) _saveContact(member.name);
      changed = true;
    }
    if (changed) notifyListeners();
    return roomParticipants;
  }

  Future<void> loadRoomMembers(String roomCode) async {
    setActiveRoom(roomCode);
    try {
      final cachedMembers = await _localRepository.getCachedRoomMembers(
        roomCode,
      );
      mergeRoomMembers(cachedMembers);
    } catch (error, stackTrace) {
      debugPrint('Failed to read cached room members: $error\n$stackTrace');
    }

    if (_offlineService?.isOffline == true) return;
    try {
      final members = await _getRoomGuestMembers(roomCode);
      await _localRepository.cacheRoomMembers(roomCode, members);
      mergeRoomMembers(members);
    } catch (error, stackTrace) {
      if (!OfflineService.isLikelyNetworkError(error)) rethrow;
      debugPrint(
        'Using cached room members while offline: $error\n$stackTrace',
      );
    }
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
    mergeRoomMembers([member]);
    await _localRepository.cacheRoomMembers(roomCode, _roomMembers);
    RoomMember savedMember;
    if (_offlineService?.isOffline == true) {
      await _offlineQueue.enqueue(
        type: 'add_room_guest_member',
        payload: {'room_code': roomCode, 'member': member.toMap()},
      );
      savedMember = member;
    } else {
      try {
        savedMember = await _addRoomGuestMember(roomCode, member);
      } catch (error) {
        if (!OfflineService.isLikelyNetworkError(error)) {
          _roomMembers.removeWhere((existing) => existing.id == member.id);
          await _localRepository.cacheRoomMembers(roomCode, _roomMembers);
          rethrow;
        }
        await _offlineQueue.enqueue(
          type: 'add_room_guest_member',
          payload: {'room_code': roomCode, 'member': member.toMap()},
        );
        savedMember = member;
      }
    }
    await _localRepository.cacheRoomMembers(roomCode, _roomMembers);
    await _saveContact(name);
    return savedMember;
  }

  Future<void> saveRoomMemberContacts(Iterable<RoomMember> members) async {
    for (final member in members) {
      if (!member.isGuest && member.id == _billRepository.currentUserId) {
        continue;
      }
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

  // ดึงประวัติบิลของเรามาแสดง
  Future<void> loadMyBills() async {
    _isLoading = true;
    notifyListeners();

    _bills = await _getMyBills();

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
      final newBill = await _createBill(shopName, totalAmount);
      _bills.insert(0, newBill);
      notifyListeners();
      return newBill;
    } finally {
      _isCreatingBill = false;
    }
  }
}
