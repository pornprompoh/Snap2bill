import '../../models/bill_model.dart';
import '../repositories/bill_repository.dart';

class GetMyBills {
  final BillRepository repository;

  const GetMyBills(this.repository);

  Future<List<BillModel>> call() => repository.getMyBills();
}

class CreateBill {
  final BillRepository repository;

  const CreateBill(this.repository);

  Future<BillModel> call(String shopName, double totalAmount) =>
      repository.createBill(shopName, totalAmount);
}

class GetRoomGuestMembers {
  final BillRepository repository;

  const GetRoomGuestMembers(this.repository);

  Future<List<RoomMember>> call(String roomCode) =>
      repository.getRoomGuestMembers(roomCode);
}

class AddRoomGuestMember {
  final BillRepository repository;

  const AddRoomGuestMember(this.repository);

  Future<RoomMember> call(String roomCode, RoomMember member) =>
      repository.addRoomGuestMember(roomCode, member);
}
