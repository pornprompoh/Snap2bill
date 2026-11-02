import '../../domain/repositories/bill_repository.dart';
import '../../models/bill_model.dart';
import '../../services/data/supabase_db_service.dart';

class SupabaseBillRepository implements BillRepository {
  final SupabaseDbService _service;

  SupabaseBillRepository({SupabaseDbService? service})
      : _service = service ?? SupabaseDbService();

  @override
  String? get currentUserId => _service.currentUserId;

  @override
  Future<List<BillModel>> getMyBills() => _service.getMyBills();

  @override
  Future<BillModel> createBill(String shopName, double totalAmount) =>
      _service.createBill(shopName, totalAmount);

  @override
  Future<List<RoomMember>> getRoomGuestMembers(String roomCode) =>
      _service.getRoomGuestMembers(roomCode);

  @override
  Future<RoomMember> addRoomGuestMember(
    String roomCode,
    RoomMember member,
  ) =>
      _service.addRoomGuestMember(roomCode, member);
}
