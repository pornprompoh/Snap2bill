class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? paymentInfo;

  UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.paymentInfo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      paymentInfo: json['payment_info'] as String?,
    );
  }
}

class FriendModel {
  final String id;
  final String userId;
  final String? friendName;
  final String? linkedProfileId;

  FriendModel({
    required this.id,
    required this.userId,
    this.friendName,
    this.linkedProfileId,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendName: json['friend_name'] as String?,
      linkedProfileId: json['linked_profile_id'] as String?,
    );
  }
}