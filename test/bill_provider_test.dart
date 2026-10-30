import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('BillProvider calculations', () {
    final items = [
      BillItemModel(
        id: 'item-1',
        billId: 'bill-1',
        itemName: 'Noodles',
        price: 100,
        quantity: 2,
        userQuantities: {'host': 1, 'guest': 1},
      ),
    ];

    test('calculates subtotal, VAT, and service charge', () {
      expect(BillProvider.calculateSubtotal(items), 200);
      expect(
        BillProvider.calculateVat(subtotal: 200, rate: 7),
        closeTo(14, 0.001),
      );
      expect(BillProvider.calculateCharge(subtotal: 200, rate: 0), 0);
      expect(
        () => BillProvider.calculateVat(subtotal: 200, rate: -1),
        throwsArgumentError,
      );
      expect(
        () => BillProvider.calculateServiceCharge(
          subtotal: 200,
          rate: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        BillProvider.calculateServiceCharge(subtotal: 200, rate: 10),
        closeTo(20, 0.001),
      );
    });

    test('allocates a proportional final total', () {
      final shares = BillProvider.calculateUserShares(
        items: items,
        finalTotal: 234,
        splitType: 'proportional',
      );

      expect(shares['host'], closeTo(117, 0.001));
      expect(shares['guest'], closeTo(117, 0.001));
    });

    test(
      'allocates an equal final total including an unclaimed participant',
      () {
        final shares = BillProvider.calculateUserShares(
          items: items,
          finalTotal: 234,
          splitType: 'equal',
          participantIds: ['host', 'guest', 'observer'],
        );

        expect(shares['host'], closeTo(111.333, 0.001));
        expect(shares['guest'], closeTo(111.333, 0.001));
        expect(shares['observer'], closeTo(11.333, 0.001));
      },
    );
  });

  group('claiming users and guest members', () {
    test('adds a guest member after selecting a room', () async {
      final provider = BillProvider();
      provider.setActiveRoom('room-1');
      provider.mergeRoomMembers([
        const BillMemberForTest(id: 'guest-1', name: 'Mina', isGuest: true),
      ]);

      expect(provider.roomMembers.single.name, 'Mina');
    });

    test('switches the active claiming user', () {
      final provider = BillProvider();
      provider.setClaimingUser('guest-1');
      expect(provider.currentClaimingUserId, 'guest-1');
    });

    test('ignores duplicate participants and invalid member ids', () {
      final provider = BillProvider();
      final participant = UserModel(
        id: 'member-1',
        displayName: 'Alice',
        email: 'alice@example.com',
      );

      provider.addRoomParticipants('room-1', [participant, participant]);
      provider.mergeRoomMembers([const RoomMember(id: '', name: 'ignored')]);

      expect(provider.roomParticipants, hasLength(1));
      expect(provider.roomMembers, hasLength(1));
    });

    test('validates split type and guest input', () async {
      final provider = BillProvider();
      expect(() => provider.setSplitType('invalid'), throwsArgumentError);
      expect(() => provider.setClaimingUser(''), throwsArgumentError);
      expect(() => provider.addGuestMember(''), throwsArgumentError);
      expect(() => provider.addGuestMember('Bob'), throwsStateError);
      expect(BillProvider.isNetworkError(Exception('network error')), isTrue);
    });

    test('rejects unsupported share calculations', () {
      expect(
        () => BillProvider.calculateUserShares(
          items: const [],
          finalTotal: 0,
          splitType: 'unsupported',
        ),
        throwsArgumentError,
      );
      expect(
        () => BillProvider.calculateSubtotal([
          BillItemModel(
            id: 'item-1',
            billId: 'bill-1',
            itemName: 'Invalid',
            price: -1,
            quantity: 1,
          ),
        ]),
        throwsArgumentError,
      );
    });
  });
}

class BillMemberForTest extends RoomMember {
  const BillMemberForTest({
    required super.id,
    required super.name,
    super.isGuest,
  });
}
