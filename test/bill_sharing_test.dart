import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';

void main() {
  test('serializes guest room members with their simulated identity', () {
    const guest = RoomMember(id: 'guest_123', name: 'Mina', isGuest: true);

    expect(RoomMember.fromMap(guest.toMap()).id, 'guest_123');
    expect(RoomMember.fromMap(guest.toMap()).name, 'Mina');
    expect(RoomMember.fromMap(guest.toMap()).isGuest, isTrue);
  });

  group('BillItemModel claimedBy', () {
    Map<String, dynamic> itemJson(Object? claimedBy) => {
      'id': 'item-1',
      'bill_id': 'bill-1',
      'item_name': 'Noodles',
      'price': 120.0,
      'quantity': 2,
      'claimed_by': claimedBy,
    };

    test('converts legacy single claimant string into a list', () {
      final item = BillItemModel.fromJson(itemJson('user-1'));

      expect(item.claimedBy, ['user-1']);
    });

    test('converts claimant arrays to strings and serializes as an array', () {
      final item = BillItemModel.fromJson(itemJson(['user-1', 2]));

      expect(item.claimedBy, ['user-1', '2']);
      expect(item.toJson()['claimed_by'], ['user-1', '2']);
    });

    test('defaults to an empty claimant list', () {
      final item = BillItemModel.fromJson(itemJson(null));

      expect(item.claimedBy, isEmpty);
    });

    test('reads personal quantities and shared users from JSON', () {
      final item = BillItemModel.fromJson({
        ...itemJson(null),
        'quantity': 16,
        'claims': {'user-a': 5, 'user-b': '5'},
        'shared_claims': ['user-a', 'user-b', 'user-c'],
      });

      expect(item.userQuantities, {'user-a': 5, 'user-b': 5});
      expect(item.sharedUsers, ['user-a', 'user-b', 'user-c']);
      expect(item.toJson()['claims'], {'user-a': 5, 'user-b': 5});
      expect(item.toJson()['shared_claims'], ['user-a', 'user-b', 'user-c']);
    });

    test('converts the legacy claimant list to one personal piece each', () {
      final item = BillItemModel.fromJson(itemJson(['user-a', 'user-b']));

      expect(item.userQuantities, {'user-a': 1, 'user-b': 1});
    });
  });

  test('splits the extra amount proportional to selected food totals', () {
    final shares = BillProvider.calculateUserShares(
      items: [
        BillItemModel(
          id: 'item-1',
          billId: 'bill-1',
          itemName: 'Noodles',
          price: 120,
          quantity: 2,
          userQuantities: {'user-1': 1, 'user-2': 1},
        ),
      ],
      finalTotal: 258,
      splitType: 'proportional',
    );

    expect(shares['user-1'], closeTo(129, 0.001));
    expect(shares['user-2'], closeTo(129, 0.001));
  });

  test('splits the extra amount equally across every room participant', () {
    final shares = BillProvider.calculateUserShares(
      items: [
        BillItemModel(
          id: 'item-1',
          billId: 'bill-1',
          itemName: 'Noodles',
          price: 120,
          quantity: 2,
          userQuantities: {'user-1': 1, 'user-2': 1},
        ),
      ],
      finalTotal: 258,
      splitType: 'equal',
      participantIds: ['user-1', 'user-2', 'user-3'],
    );

    expect(shares['user-1'], closeTo(126, 0.001));
    expect(shares['user-2'], closeTo(126, 0.001));
    expect(shares['user-3'], closeTo(6, 0.001));
  });

  test('calculates a separate share for a guest room member', () {
    final shares = BillProvider.calculateUserShares(
      items: [
        BillItemModel(
          id: 'item-1',
          billId: 'bill-1',
          itemName: 'Tea',
          price: 60,
          quantity: 1,
          userQuantities: {'guest_123': 1},
        ),
      ],
      finalTotal: 60,
      splitType: 'proportional',
      participantIds: ['host-1', 'guest_123'],
    );

    expect(shares['guest_123'], 60);
    expect(shares['host-1'], 0);
  });

  test('splits personal pieces and the remaining shared pieces per user', () {
    final shares = BillProvider.calculateUserShares(
      items: [
        BillItemModel(
          id: 'sushi',
          billId: 'bill-1',
          itemName: '40B Sushi',
          price: 40,
          quantity: 16,
          userQuantities: {'user-a': 5, 'user-b': 5},
          sharedUsers: ['user-a', 'user-b', 'user-c'],
        ),
      ],
      finalTotal: 640,
      splitType: 'proportional',
    );

    expect(shares['user-a'], closeTo(280, 0.001));
    expect(shares['user-b'], closeTo(280, 0.001));
    expect(shares['user-c'], closeTo(80, 0.001));
  });

  test('reads and serializes final total and split type', () {
    final bill = BillModel.fromJson({
      'id': 'bill-1',
      'owner_id': 'user-1',
      'total_amount': 125,
      'final_total': 125,
      'split_type': 'equal',
    });

    expect(bill.finalTotal, 125);
    expect(bill.splitType, 'equal');
    expect(bill.toJson()['final_total'], 125);
    expect(bill.toJson()['split_type'], 'equal');
  });
}
