import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/repositories/bill_repository.dart';

import 'mocks/mock_services.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late MockBillRepository repository;
  late MockFirebaseDbService dbService;
  late BillProvider provider;

  setUp(() {
    repository = MockBillRepository();
    dbService = MockFirebaseDbService();
    when(() => repository.dispose()).thenAnswer((_) async {});
    when(() => dbService.currentUserId).thenReturn('user-1');
    provider = BillProvider(repository: repository, dbService: dbService);
  });

  tearDown(() {
    provider.dispose();
  });

  test('loads Drift bills immediately before attempting cloud sync', () async {
    final localBills = [
      {
        'id': 'bill-local',
        'owner_id': 'user-1',
        'shop_name': 'Local bill',
        'total_amount': 240.0,
        'status': 'completed',
      },
    ];
    when(
      () => repository.getBills(userId: 'user-1', syncInBackground: false),
    ).thenAnswer((_) async => localBills);
    when(
      () => repository.hasNetworkConnection(),
    ).thenAnswer((_) async => false);

    await provider.loadBills();

    expect(provider.bills, hasLength(1));
    expect(provider.bills.single.id, 'bill-local');
    expect(provider.bills.single.totalAmount, 240);
    expect(provider.isLoading, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(provider.isOffline, isTrue);
    verify(
      () => repository.getBills(userId: 'user-1', syncInBackground: false),
    ).called(1);
    verifyNever(() => repository.syncWithCloud(userId: any(named: 'userId')));
  });

  test(
    'syncs local bills with Firestore after displaying Drift data',
    () async {
      final localBill = {
        'id': 'bill-1',
        'owner_id': 'user-1',
        'shop_name': 'Dinner',
        'total_amount': 345.0,
      };
      when(
        () => repository.getBills(userId: 'user-1', syncInBackground: false),
      ).thenAnswer((_) async => [localBill]);
      when(
        () => repository.hasNetworkConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => repository.syncWithCloud(userId: 'user-1'),
      ).thenAnswer((_) async {});

      await provider.loadBills();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        () => repository.getBills(userId: 'user-1', syncInBackground: false),
        () => repository.hasNetworkConnection(),
        () => repository.syncWithCloud(userId: 'user-1'),
        () => repository.getBills(userId: 'user-1', syncInBackground: false),
      ]);
      expect(provider.bills.single.id, 'bill-1');
      expect(provider.isOffline, isFalse);
    },
  );

  test('keeps local bills visible when network check fails', () async {
    when(
      () => repository.getBills(userId: 'user-1', syncInBackground: false),
    ).thenAnswer(
      (_) async => [
        {
          'id': 'bill-offline',
          'owner_id': 'user-1',
          'shop_name': 'Offline dinner',
          'total_amount': 80,
        },
      ],
    );
    when(
      () => repository.hasNetworkConnection(),
    ).thenThrow(StateError('network unavailable'));

    await provider.loadBills();
    await Future<void>.delayed(Duration.zero);

    expect(provider.bills.single.id, 'bill-offline');
    expect(provider.isOffline, isTrue);
    expect(provider.error, contains('network unavailable'));
  });

  test('creates a bill in Drift before background synchronization', () async {
    when(() => dbService.newBillId()).thenReturn('bill-new');
    when(
      () => repository.createBillLocally(
        billId: 'bill-new',
        userId: 'user-1',
        bill: any(named: 'bill'),
        participantTotals: {'user-1': 125},
        imageBytes: null,
        localImagePath: null,
        items: [
          {'id': 'item-1', 'item_name': 'Noodles', 'price': 125},
        ],
      ),
    ).thenAnswer((_) async => 'bill-new');
    when(
      () => repository.hasNetworkConnection(),
    ).thenAnswer((_) async => false);

    final bill = await provider.createBill(
      'Dinner',
      125,
      items: [
        {'id': 'item-1', 'item_name': 'Noodles', 'price': 125},
      ],
      participantTotals: {'user-1': 125},
    );

    expect(bill.id, 'bill-new');
    expect(provider.bills.single.shopName, 'Dinner');
    verify(
      () => repository.createBillLocally(
        billId: 'bill-new',
        userId: 'user-1',
        bill: any(named: 'bill'),
        participantTotals: {'user-1': 125},
        imageBytes: null,
        localImagePath: null,
        items: [
          {'id': 'item-1', 'item_name': 'Noodles', 'price': 125},
        ],
      ),
    ).called(1);
  });

  test('queues participant status changes in the local repository', () async {
    when(
      () => repository.updateParticipantStatusLocally(
        billId: 'bill-1',
        userId: 'user-1',
        profileId: 'friend-1',
        status: 'paid',
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.getBills(userId: 'user-1', syncInBackground: false),
    ).thenAnswer((_) async => []);
    when(
      () => repository.hasNetworkConnection(),
    ).thenAnswer((_) async => false);

    await provider.updateParticipantStatus(
      billId: 'bill-1',
      profileId: 'friend-1',
      status: 'paid',
    );

    verify(
      () => repository.updateParticipantStatusLocally(
        billId: 'bill-1',
        userId: 'user-1',
        profileId: 'friend-1',
        status: 'paid',
      ),
    ).called(1);
  });

  test('returns empty bills when no Firebase user is signed in', () async {
    when(() => dbService.currentUserId).thenReturn(null);

    await provider.loadBills();

    expect(provider.bills, isEmpty);
    expect(provider.isOffline, isFalse);
    verifyNever(() => repository.getBills(userId: any(named: 'userId')));
  });

  test('updates bill data locally and refreshes the in-memory list', () async {
    when(
      () => repository.updateBillLocally(
        billId: 'bill-1',
        userId: 'user-1',
        data: {'status': 'paid'},
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.getBills(userId: 'user-1', syncInBackground: false),
    ).thenAnswer(
      (_) async => [
        {
          'id': 'bill-1',
          'owner_id': 'user-1',
          'shop_name': 'Dinner',
          'status': 'paid',
          'total_amount': 100,
        },
      ],
    );
    when(
      () => repository.hasNetworkConnection(),
    ).thenAnswer((_) async => false);

    await provider.updateBill(billId: 'bill-1', data: {'status': 'paid'});

    expect(provider.bills.single.status, 'paid');
    verify(
      () => repository.updateBillLocally(
        billId: 'bill-1',
        userId: 'user-1',
        data: {'status': 'paid'},
      ),
    ).called(1);
  });

  test('manages room members and claiming user without duplicate entries', () {
    final first = UserModel(
      id: 'friend-1',
      displayName: 'Nina',
      email: 'nina@example.com',
    );
    provider.setActiveRoom('room-1');
    provider.setSplitType('equal');
    final participants = provider.addRoomParticipants('room-1', [first, first]);

    expect(participants, hasLength(1));
    expect(provider.roomMembers.single.name, 'Nina');
    expect(provider.splitType, 'equal');
    provider.setClaimingUser('friend-1');
    expect(provider.currentClaimingUserId, 'friend-1');
    provider.mergeRoomMembers([
      const RoomMember(id: 'guest-1', name: 'Guest', isGuest: true),
      const RoomMember(id: 'guest-1', name: 'Duplicate', isGuest: true),
    ]);
    expect(provider.roomMembers, hasLength(2));
    expect(() => provider.setSplitType('unsupported'), throwsArgumentError);
  });

  test('loads guest room members from Firebase database service', () async {
    when(() => dbService.getRoomGuestMembers('room-1')).thenAnswer(
      (_) async => [
        const RoomMember(id: 'guest-1', name: 'Guest', isGuest: true),
      ],
    );

    await provider.loadRoomMembers('room-1');

    expect(provider.roomMembers.single.name, 'Guest');
  });

  group('bill share calculations with VAT and service charge', () {
    final billItems = [
      BillItemModel(
        id: 'item-personal',
        billId: 'bill-1',
        itemName: 'Personal meal',
        price: 100,
        quantity: 1,
        userQuantities: {'user-a': 1},
      ),
      BillItemModel(
        id: 'item-shared',
        billId: 'bill-1',
        itemName: 'Shared meal',
        price: 200,
        quantity: 1,
        sharedUsers: ['user-a', 'user-b'],
      ),
    ];

    test('allocates VAT and service charge proportionally to food totals', () {
      final shares = BillProvider.calculateUserShares(
        items: billItems,
        finalTotal: 345,
        splitType: 'proportional',
      );

      expect(shares['user-a'], closeTo(230, 0.001));
      expect(shares['user-b'], closeTo(115, 0.001));
      expect(shares.values.reduce((first, second) => first + second), 345);
    });

    test('splits VAT and service charge equally among active claimants', () {
      final shares = BillProvider.calculateUserShares(
        items: billItems,
        finalTotal: 345,
        splitType: 'equal',
      );

      expect(shares['user-a'], closeTo(222.5, 0.001));
      expect(shares['user-b'], closeTo(122.5, 0.001));
    });
  });
}
