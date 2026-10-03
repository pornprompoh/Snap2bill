import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../services/supabase_db_service.dart';

class BillProvider with ChangeNotifier {
  final SupabaseDbService _dbService = SupabaseDbService();

  List<BillModel> _bills = [];
  String? _activeRoomCode;
  final List<UserModel> _roomParticipants = [];
  bool _isLoading = false;
  bool _isCreatingBill = false;
  String _splitType = 'proportional';

  List<BillModel> get bills => _bills;
  List<UserModel> get roomParticipants => List.unmodifiable(_roomParticipants);
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
      changed = true;
    }
    if (changed) notifyListeners();
    return roomParticipants;
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
