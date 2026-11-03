import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';

void main() {
  test(
    'extractBillTotal tries receipt values, item totals and participant sums',
    () {
      expect(
        BillProgressHelper.extractBillTotal({
          'total_amount': 'not a number',
          'sub_total': 0,
          'receipt_json': jsonEncode({
            'final_total': 'invalid',
            'total_amount': 0,
            'sub_total': '125.50',
          }),
        }),
        125.5,
      );

      expect(
        BillProgressHelper.extractBillTotal({
          'receipt_json': {
            'items': [
              {'qty': 'bad', 'unit_price': '10'},
              {'quantity': 2, 'price': '5', 'total_price': '12'},
              'not an item',
            ],
          },
        }),
        22,
      );

      expect(
        BillProgressHelper.extractBillTotal({
          'receipt_json': {
            'items': [
              {'qty': 1, 'price': 0},
            ],
          },
          'bill_participants': [
            {'amount_owed': '30.25'},
            {'amount_owed': 'invalid'},
            'not a participant',
          ],
        }),
        30.25,
      );
      expect(
        BillProgressHelper.extractBillTotal({'receipt_json': '{invalid'}),
        0,
      );
    },
  );

  test('normalizes shop and owner identity fallbacks from receipt data', () {
    expect(
      BillProgressHelper.extractShopName({
        'shop_name': '  Shop from bill  ',
        'receipt_json': {'shop_name': 'Receipt shop'},
      }),
      'Shop from bill',
    );
    expect(
      BillProgressHelper.extractShopName({
        'shop_name': 'null',
        'receipt_json': '{"shop_name":"  Receipt shop  "}',
      }),
      'ไม่ระบุชื่อร้าน',
    );
    expect(
      BillProgressHelper.extractShopName({'receipt_json': '{broken'}),
      'ไม่ระบุชื่อร้าน',
    );

    expect(
      BillProgressHelper.extractOwnerId({'user_id': 'owner-from-user'}),
      'owner-from-user',
    );
    expect(
      BillProgressHelper.extractOwnerId({
        'receipt_json': {'owner_id': 'receipt-owner'},
      }),
      'receipt-owner',
    );
    expect(BillProgressHelper.extractOwnerId({'receipt_json': '{broken'}), '');
  });

  test('builds statuses from legacy aliases, guests and malformed data', () {
    final summary = BillProgressHelper.calculate({
      'user_id': 'bill-owner',
      'total_amount': 300,
      'receipt_json': jsonEncode({
        'paid_statuses': {'guest_paid': 'PAID', 'guest_pending': 'pending'},
        'items': [
          {
            'user_quantities': {'friend-a': 1, '': 1},
            'shared_users': ['friend-b', '', null],
          },
          {
            'userQuantities': {'friend-c': 2},
            'sharedUsers': ['friend-c'],
          },
          'invalid-item',
        ],
      }),
      'bill_participants': [
        {'profile_id': 'bill-owner', 'status': 'pending', 'amount_owed': 50},
        {'friend_id': 'friend-a', 'status': 'PAID', 'amount_owed': 'bad'},
        {'id': 'friend-b', 'status': 'reviewing', 'amount_owed': 0},
        {'profile_id': '', 'amount_owed': 10},
        'invalid participant',
      ],
      'sharers_json': {
        'one': [
          {'id': 'friend-a', 'name': 'เอ'},
          {'userId': 'friend-b', 'displayName': 'บี'},
          {'user_id': 'guest_from_sharer', 'user_name': 'Guest C'},
          'legacy-friend',
          {'name': 'missing id'},
        ],
        'not-a-list': 42,
      },
    });

    final membersById = {
      for (final member in summary.allMembers) member.id: member,
    };
    expect(membersById['bill-owner']!.isOwner, isTrue);
    expect(membersById['bill-owner']!.isPaid, isTrue);
    expect(membersById['friend-a']!.name, 'เอ');
    expect(membersById['friend-a']!.isPaid, isTrue);
    expect(membersById['friend-a']!.amount, 37.5);
    expect(membersById['friend-b']!.name, 'บี');
    expect(membersById['friend-b']!.isPaid, isFalse);
    expect(membersById['guest_from_sharer']!.isGuest, isTrue);
    expect(membersById['legacy-friend']!.name, 'เพื่อน');
    expect(membersById['guest_paid']!.isPaid, isTrue);
    expect(summary.totalPayingCount, summary.allMembers.length - 1);
    expect(summary.unpaidCount, greaterThan(0));
    expect(summary.isSettled, isFalse);
    expect(summary.percentage, lessThan(100));
    expect(summary.progressPercentageText, contains('%'));
    expect(summary.waitingText, contains('รออีก'));
    expect(summary.paidCountText, contains('จ่ายแล้ว'));
  });

  test(
    'uses private payment records ahead of participant and legacy statuses',
    () {
      final summary = BillProgressHelper.calculate({
        'owner_id': 'owner',
        'total_amount': 200,
        'receipt_json': {
          'paid_statuses': {'friend': 'paid'},
        },
        'bill_participants': [
          {'profile_id': 'owner', 'amount_owed': 0},
          {'profile_id': 'friend', 'status': 'paid', 'amount_owed': 100},
        ],
        'bill_payments': [
          {'profile_id': 'friend', 'status': 'reviewing'},
          {'profile_id': 'guest_1', 'status': 'paid'},
        ],
      });

      final membersById = {
        for (final member in summary.allMembers) member.id: member,
      };
      expect(membersById['friend']!.isPaid, isFalse);
      expect(membersById['guest_1']!.isPaid, isTrue);
      expect(summary.isSettled, isFalse);
    },
  );
}
