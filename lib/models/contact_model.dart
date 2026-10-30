import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  final String id;
  final String userId;
  final String name;
  final String? note;
  final DateTime createdAt;

  const ContactModel({
    required this.id,
    required this.userId,
    required this.name,
    this.note,
    required this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'];
    final DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.parse(rawCreatedAt);
    } else {
      throw FormatException('Invalid contact created_at value: $rawCreatedAt');
    }
    return ContactModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'].toString(),
      note: json['note']?.toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };
}
