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
    return ContactModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'].toString(),
      note: json['note']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
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