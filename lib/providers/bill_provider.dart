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

  List<BillModel> get bills => _bills;
  List<UserModel> get roomParticipants => List.unmodifiable(_roomParticipants);
  bool get isLoading => _isLoading;

  void setActiveRoom(String roomCode) {
    if (_activeRoomCode == roomCode) return;
    _activeRoomCode = roomCode;
    _roomParticipants.clear();
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
    final newBill = await _dbService.createBill(shopName, totalAmount);
    _bills.insert(0, newBill);
    notifyListeners();
    return newBill;
  }
}
