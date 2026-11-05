import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';

void main() {
  group('BillModel', () {
    test('parses numeric strings, defaults, and legacy total fields', () {
      final bill = BillModel.fromJson({
        'id': 'bill-1',
        'owner_id': 'owner-1',
        'sub_total': '120.50',
        'vat_amount': 8,
        'service_charge': '12',
        'final_total': '140.50',
        'split_type': 'equal',
      });

      expect(bill.subTotal, 120.5);
      expect(bill.vatAmount, 8);
      expect(bill.serviceCharge, 12);
      expect(bill.totalAmount, 140.5);
      expect(bill.finalTotal, 140.5);
      expect(bill.splitType, 'equal');
      expect(bill.status, 'draft');

      final defaults = BillModel.fromJson({
        'id': 'bill-2',
        'owner_id': 'owner-1',
        'total_amount': 25,
        'split_type': 'unknown',
        'sub_total': 'invalid',
      });
      expect(defaults.totalAmount, 25);
      expect(defaults.finalTotal, 25);
      expect(defaults.subTotal, 0);
      expect(defaults.splitType, 'proportional');
    });

    test('serializes totalAmount as final total when finalTotal is zero', () {
      final bill = BillModel(id: 'bill-1', ownerId: 'owner-1', totalAmount: 99);

      expect(bill.toJson()['total_amount'], 99);
      expect(bill.toJson()['final_total'], 99);
    });
  });

  group('RoomMember', () {
    test(
      'supports current and legacy field names and serializes canonical keys',
      () {
        final member = RoomMember.fromMap({
          'user_id': 42,
          'display_name': 'Mina',
          'avatarUrl': 'https://example.test/avatar.png',
          'local_avatar_path': '/tmp/avatar.png',
          'isGuest': true,
        });

        expect(member.id, '42');
        expect(member.name, 'Mina');
        expect(member.avatarUrl, 'https://example.test/avatar.png');
        expect(member.localAvatarPath, '/tmp/avatar.png');
        expect(member.isGuest, isTrue);
        expect(member.toMap(), {
          'id': '42',
          'name': 'Mina',
          'avatar_url': 'https://example.test/avatar.png',
          'is_guest': true,
        });
      },
    );

    test('uses fallback identity and name for incomplete member data', () {
      final member = RoomMember.fromMap({'is_guest': false});
      expect(member.id, isEmpty);
      expect(member.name, 'เพื่อน');
      expect(member.isGuest, isFalse);
    });
  });

  group('BillItemModel', () {
    test('parses legacy claimant lists and de-duplicates shared users', () {
      final item = BillItemModel.fromJson({
        'id': 'item-1',
        'bill_id': 'bill-1',
        'item_name': 'Tea',
        'price': 35,
        'qty': '2',
        'claimed_by': ['user-1', 2],
        'shared_claims': ['user-1', 'user-1', 'user-2'],
        'total_price': '70',
      });

      expect(item.price, 35);
      expect(item.quantity, 2);
      expect(item.totalPrice, 70);
      expect(item.claimedBy, ['user-1', '2']);
      expect(item.userQuantities, {'user-1': 1, '2': 1});
      expect(item.sharedUsers, ['user-1', 'user-2']);
      expect(
        item.toJson()['claimed_by'],
        containsAll(['user-1', '2', 'user-2']),
      );
    });

    test(
      'handles map and list claim formats and rejects invalid quantities',
      () {
        final mapClaims = BillItemModel.fromJson({
          'id': 'item-2',
          'bill_id': 'bill-1',
          'item_name': 'Rice',
          'claims': {'user-1': '2', 'user-2': '0', 'user-3': 'bad'},
          'shared_users': 'user-4',
        });
        expect(mapClaims.userQuantities, {'user-1': 2});
        expect(mapClaims.claimedBy, ['user-1']);
        expect(mapClaims.sharedUsers, ['user-4']);

        final listClaims = BillItemModel.fromJson({
          'id': 'item-3',
          'bill_id': 'bill-1',
          'item_name': 'Water',
          'user_quantities': ['user-1', 'user-2'],
          'shared_claims': '',
          'quantity': 'not-a-number',
        });
        expect(listClaims.userQuantities, {'user-1': 1, 'user-2': 1});
        expect(listClaims.claimedBy, ['user-1', 'user-2']);
        expect(listClaims.sharedUsers, isEmpty);
        expect(listClaims.quantity, 1);
        expect(listClaims.totalPrice, isNull);
      },
    );

    test('supports map-shaped legacy claims and missing item defaults', () {
      final item = BillItemModel.fromJson({
        'id': 'item-4',
        'bill_id': 'bill-1',
        'item_name': 'Cake',
        'claimed_by': {'user-1': 3, 'user-2': 1},
      });

      expect(item.claimedBy, ['user-1', 'user-2']);
      expect(item.userQuantities, {'user-1': 3, 'user-2': 1});
      expect(item.quantity, 1);
      expect(item.price, 0);
      expect(item.totalPrice, isNull);
    });
  });

  test('BillParticipantModel parses fields and applies optional defaults', () {
    final participant = BillParticipantModel.fromJson({
      'id': 'participant-1',
      'bill_id': 'bill-1',
      'friend_id': 'friend-1',
      'amount_owed': 42.5,
    });
    expect(participant.profileId, isNull);
    expect(participant.friendId, 'friend-1');
    expect(participant.amountOwed, 42.5);
    expect(participant.status, 'pending');
  });
}
