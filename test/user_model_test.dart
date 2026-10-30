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

  test('parses bank account payment information correctly', () {
    final user = UserModel.fromMap({
      'id': 'user-bank',
      'display_name': 'Somchai',
      'payment_info': {
        'type': 'phone',
        'number': '0899999999',
        'bank_name': 'ธนาคารกสิกรไทย (KBANK)',
        'bank_account_number': '123-4-56789-0',
        'bank_account_name': 'นายสมชาย รวยมาก',
      },
    });

    expect(user.hasBankTransfer, isTrue);
    expect(user.bankName, 'ธนาคารกสิกรไทย (KBANK)');
    expect(user.bankAccountNumber, '123-4-56789-0');
    expect(user.bankAccountName, 'นายสมชาย รวยมาก');
  });
}

