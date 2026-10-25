import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/user_model.dart';

void main() {
  test('parses profile and prompt-pay information', () {
    final user = UserModel.fromJson({
      'id': 'user-1',
      'display_name': 'Alice',
      'email': 'alice@example.com',
      'payment_info': '{"type":"phone","number":"0812345678"}',
    });

    expect(user.displayName, 'Alice');
    expect(user.promptPayType, 'phone');
    expect(user.promptPayNumber, '0812345678');
    expect(user.copyWith(displayName: 'A').displayName, 'A');
  });

  test('ignores malformed payment information', () {
    final user = UserModel.fromMap({
      'id': 'user-1',
      'payment_info': 'not-json',
    });

    expect(user.paymentInfo, isNull);
    expect(user.toMap()['id'], 'user-1');
  });

  test('supports map payment information and friend profiles', () {
    final user = UserModel.fromMap({
      'id': 'user-2',
      'payment_info': {'type': 'id_card', 'number': '123'},
    });
    final friend = FriendModel.fromJson({
      'id': 'friend-1',
      'user_id': 'user-2',
      'friend_name': 'Bob',
      'linked_profile_id': 'user-3',
    });

    expect(user.promptPayType, 'id_card');
    expect(friend.friendName, 'Bob');
    expect(friend.linkedProfileId, 'user-3');
  });
}
