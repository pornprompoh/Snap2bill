import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        // ignore: deprecated_member_use
        anonKey: 'mock-key',
      );
    } catch (_) {
      // Already initialized
    }
  });

  group('BillProvider State & Operations Tests', () {
    late BillProvider provider;

    setUp(() {
      provider = BillProvider();
    });

    test('initial state has default values', () {
      expect(provider.bills, isEmpty);
      expect(provider.roomParticipants, isEmpty);
      expect(provider.roomMembers, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.splitType, 'proportional');
    });

    test('setSplitType toggles between equal and proportional', () {
      provider.setSplitType('equal');
      expect(provider.splitType, 'equal');

      provider.setSplitType('proportional');
      expect(provider.splitType, 'proportional');

      expect(() => provider.setSplitType('invalid_split'), throwsA(isA<ArgumentError>()));
    });

    test('setActiveRoom resets room state and participants', () {
      provider.setActiveRoom('ROOM01');
      expect(provider.splitType, 'proportional');

      // Setting same room does not reset
      provider.setSplitType('equal');
      provider.setActiveRoom('ROOM01');
      expect(provider.splitType, 'equal');

      // Setting different room resets
      provider.setActiveRoom('ROOM02');
      expect(provider.splitType, 'proportional');
    });

    test('setClaimingUser updates claimant ID and validates non-empty', () {
      provider.setClaimingUser('user-999');
      expect(provider.currentClaimingUserId, 'user-999');

      expect(() => provider.setClaimingUser(''), throwsA(isA<ArgumentError>()));
    });

    test('addRoomParticipants merges users and creates RoomMember objects', () {
      final user1 = UserModel(id: 'u1', email: 'u1@snap2bill.app', displayName: 'สมศักดิ์');
      final user2 = UserModel(id: 'u2', email: 'friend@snap2bill.app');
      final userEmpty = UserModel(id: '', email: 'invalid@snap2bill.app');

      final result = provider.addRoomParticipants('ROOM123', [user1, user2, userEmpty, user1]);

      expect(result.length, 2);
      expect(provider.roomParticipants.length, 2);
      expect(provider.roomMembers.length, 2);
      expect(provider.roomMembers.first.name, 'สมศักดิ์');
      expect(provider.roomMembers.last.name, 'friend');
    });

    test('mergeRoomMembers avoids duplicates', () {
      const m1 = RoomMember(id: 'm1', name: 'Mina');
      const m2 = RoomMember(id: 'm2', name: 'John');
      const mEmpty = RoomMember(id: '', name: 'Ghost');

      provider.mergeRoomMembers([m1, m2, mEmpty]);
      expect(provider.roomMembers.length, 2);

      // Re-merging m1 does not duplicate
      provider.mergeRoomMembers([m1]);
      expect(provider.roomMembers.length, 2);
    });

    test('calculateUserShares throws ArgumentError on unsupported split type', () {
      expect(
        () => BillProvider.calculateUserShares(
          items: [],
          finalTotal: 100,
          splitType: 'random',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('calculateUserShares with no items returns zero shares', () {
      final shares = BillProvider.calculateUserShares(
        items: [],
        finalTotal: 0,
        splitType: 'proportional',
        participantIds: ['u1', 'u2'],
      );

      expect(shares['u1'], 0.0);
      expect(shares['u2'], 0.0);
    });

    test('calculateUserShares with equal split distributes extra charges equally across eaters', () {
      final item = BillItemModel(
        id: 'i1',
        billId: 'b1',
        itemName: 'ส้มตำ',
        price: 80,
        quantity: 1,
        userQuantities: {'u1': 1},
      );

      final shares = BillProvider.calculateUserShares(
        items: [item],
        finalTotal: 100, // +20 extra
        splitType: 'equal',
        participantIds: ['u1', 'u2'],
      );

      // u1 is the only active eater, so u1 pays 80 + 20 = 100
      expect(shares['u1'], 100.0);
      // u2 ate nothing, so pays 0
      expect(shares['u2'], 0.0);
    });
  });
}
