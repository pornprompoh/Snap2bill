import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/contact_model.dart';

void main() {
  test('parses and serializes a saved contact', () {
    final createdAt = DateTime.parse('2026-10-04T08:00:00.000Z');
    final contact = ContactModel.fromJson({
      'id': 'contact-1',
      'user_id': 'user-1',
      'name': 'Mina',
      'note': 'Work friend',
      'created_at': createdAt.toIso8601String(),
    });

    expect(contact.id, 'contact-1');
    expect(contact.userId, 'user-1');
    expect(contact.name, 'Mina');
    expect(contact.note, 'Work friend');
    expect(contact.createdAt, createdAt);
    expect(contact.toJson()['user_id'], 'user-1');
    expect(contact.toJson()['created_at'], createdAt.toIso8601String());
  });
}
