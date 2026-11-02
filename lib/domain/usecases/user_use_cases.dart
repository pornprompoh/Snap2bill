import '../../models/user_model.dart';
import '../repositories/user_repository.dart';

class GetMyProfile {
  final UserRepository repository;

  const GetMyProfile(this.repository);

  Future<UserModel?> call() => repository.getMyProfile();
}

class UpdateUserProfile {
  final UserRepository repository;

  const UpdateUserProfile(this.repository);

  Future<UserModel> call({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) {
    return repository.updateUserProfile(
      displayName: displayName,
      paymentInfo: paymentInfo,
    );
  }
}

class GetMyFriends {
  final UserRepository repository;

  const GetMyFriends(this.repository);

  Future<List<FriendModel>> call() => repository.getMyFriends();
}

class AddFriend {
  final UserRepository repository;

  const AddFriend(this.repository);

  Future<void> call(String friendName) => repository.addFriend(friendName);
}
