import '../../domain/repositories/user_repository.dart';
import '../../models/user_model.dart';
import '../../services/data/supabase_db_service.dart';

class SupabaseUserRepository implements UserRepository {
  final SupabaseDbService _service;

  SupabaseUserRepository({SupabaseDbService? service})
      : _service = service ?? SupabaseDbService();

  @override
  Future<UserModel?> getMyProfile() => _service.getMyProfile();

  @override
  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) {
    return _service.updateUserProfile(
      displayName: displayName,
      paymentInfo: paymentInfo,
    );
  }

  @override
  Future<List<FriendModel>> getMyFriends() => _service.getMyFriends();

  @override
  Future<void> addFriend(String friendName) => _service.addFriend(friendName);
}
