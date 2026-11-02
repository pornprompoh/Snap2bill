import '../../models/bill_model.dart';

abstract interface class BillRepository {
  Future<List<BillModel>> getMyBills();

  Future<BillModel> createBill(String shopName, double totalAmount);

  Future<List<RoomMember>> getRoomGuestMembers(String roomCode);

  Future<RoomMember> addRoomGuestMember(String roomCode, RoomMember member);

  String? get currentUserId;
}
