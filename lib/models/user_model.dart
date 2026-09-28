import 'dart:convert';

class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final Map<String, dynamic>? paymentInfo;

  UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.paymentInfo,
  });

  String? get promptPayNumber => paymentInfo?['number']?.toString();

  String? get promptPayType => paymentInfo?['type']?.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'payment_info': paymentInfo,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> json) {
    final rawPaymentInfo = json['payment_info'];
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      paymentInfo: _parsePaymentInfo(rawPaymentInfo),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  static Map<String, dynamic>? _parsePaymentInfo(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is! String || value.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? paymentInfo,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      paymentInfo: paymentInfo ?? this.paymentInfo,
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