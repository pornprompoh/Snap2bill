import '../../models/user_model.dart';

abstract interface class UserRepository {
  Future<UserModel?> getMyProfile();

  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  });

  Future<List<FriendModel>> getMyFriends();

  Future<void> addFriend(String friendName);
}
