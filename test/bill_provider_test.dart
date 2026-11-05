import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/domain/repositories/bill_repository.dart';
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

      expect(
        () => provider.setSplitType('invalid_split'),
        throwsA(isA<ArgumentError>()),
      );
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
      final user1 = UserModel(
        id: 'u1',
        email: 'u1@snap2bill.app',
        displayName: 'สมศักดิ์',
      );
      final user2 = UserModel(id: 'u2', email: 'friend@snap2bill.app');
      final userEmpty = UserModel(id: '', email: 'invalid@snap2bill.app');

      final result = provider.addRoomParticipants('ROOM123', [
        user1,
        user2,
        userEmpty,
        user1,
      ]);

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

    test(
      'calculateUserShares throws ArgumentError on unsupported split type',
      () {
        expect(
          () => BillProvider.calculateUserShares(
            items: [],
            finalTotal: 100,
            splitType: 'random',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

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

    test(
      'calculateUserShares with equal split distributes extra charges equally across eaters',
      () {
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
      },
    );

    test(
      'calculateUserShares rounds proportional charges for all active eaters',
      () {
        final items = [
          BillItemModel(
            id: 'item-1',
            billId: 'bill-1',
            itemName: 'Soup',
            price: 30,
            quantity: 1,
            userQuantities: const {'u1': 1},
          ),
          BillItemModel(
            id: 'item-2',
            billId: 'bill-1',
            itemName: 'Rice',
            price: 70,
            quantity: 1,
            userQuantities: const {'u2': 1},
          ),
        ];

        final shares = BillProvider.calculateUserShares(
          items: items,
          finalTotal: 110,
          splitType: 'proportional',
          participantIds: const ['u1', 'u2', 'inactive', ''],
        );

        expect(shares, {'u1': 33, 'u2': 77, 'inactive': 0});
      },
    );

    test(
      'loadMyBills publishes loading transitions and fetched bills',
      () async {
        final repository = _FakeBillRepository()
          ..bills = [
            BillModel(id: 'bill-1', ownerId: 'user-1', shopName: 'Cafe'),
          ];
        final loadedProvider = BillProvider(billRepository: repository);
        final loadingStates = <bool>[];
        loadedProvider.addListener(
          () => loadingStates.add(loadedProvider.isLoading),
        );

        await loadedProvider.loadMyBills();

        expect(loadingStates, [true, false]);
        expect(loadedProvider.isLoading, isFalse);
        expect(loadedProvider.bills.single.shopName, 'Cafe');
      },
    );

    test(
      'createBill inserts new bills first and blocks concurrent creation',
      () async {
        final repository = _FakeBillRepository()
          ..bills = [BillModel(id: 'old', ownerId: 'user-1', shopName: 'Old')];
        final pendingCreate = Completer<BillModel>();
        repository.createCompleter = pendingCreate;
        final createdProvider = BillProvider(billRepository: repository);

        final createFuture = createdProvider.createBill('New', 50);
        expect(
          () => createdProvider.createBill('Duplicate', 25),
          throwsA(isA<StateError>()),
        );
        pendingCreate.complete(
          BillModel(id: 'new', ownerId: 'user-1', shopName: 'New'),
        );

        final created = await createFuture;
        expect(created.id, 'new');
        expect(createdProvider.bills.map((bill) => bill.id), ['new']);
      },
    );

    test('createBill resets its guard after repository errors', () async {
      final repository = _FakeBillRepository()
        ..createError = StateError('failed');
      final createdProvider = BillProvider(billRepository: repository);

      await expectLater(
        createdProvider.createBill('Broken', 10),
        throwsA(isA<StateError>()),
      );
      repository.createError = null;
      final created = await createdProvider.createBill('Recovered', 10);

      expect(created.shopName, 'Recovered');
      expect(createdProvider.bills, [created]);
    });
  });
}

class _FakeBillRepository implements BillRepository {
  List<BillModel> bills = [];
  Completer<BillModel>? createCompleter;
  Object? createError;

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<List<BillModel>> getMyBills() async => bills;

  @override
  Future<BillModel> createBill(String shopName, double totalAmount) async {
    if (createError != null) throw createError!;
    final completer = createCompleter;
    if (completer != null) return completer.future;
    return BillModel(
      id: 'created-${bills.length}',
      ownerId: 'user-1',
      shopName: shopName,
      totalAmount: totalAmount,
      finalTotal: totalAmount,
    );
  }

  @override
  Future<List<RoomMember>> getRoomGuestMembers(String roomCode) async => [];

  @override
  Future<RoomMember> addRoomGuestMember(
    String roomCode,
    RoomMember member,
  ) async => member;
}
