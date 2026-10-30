import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snap2bill/database/app_database.dart';
import 'package:snap2bill/repositories/bill_repository.dart';
import 'package:snap2bill/repositories/local_bill_repository.dart';
import 'package:snap2bill/services/firebase_db_service.dart';
import 'package:snap2bill/services/supabase_storage_service.dart';

class _MockConnectivity extends Mock implements Connectivity {}

class _MockFirebaseDbService extends Mock implements FirebaseDbService {}

class _MockSupabaseStorageService extends Mock
    implements SupabaseStorageService {}

void main() {
  late AppDatabase database;
  late _MockConnectivity connectivity;
  late _MockFirebaseDbService firebaseDb;
  late _MockSupabaseStorageService storage;
  late BillRepository repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    connectivity = _MockConnectivity();
    firebaseDb = _MockFirebaseDbService();
    storage = _MockSupabaseStorageService();
    repository = BillRepository(
      database: database,
      connectivity: connectivity,
      firebaseDb: firebaseDb,
      storage: storage,
    );
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<List<ConnectivityResult>>.empty());
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test(
    'uploads pending image before writing bill and marks it synced',
    () async {
      final imageBytes = Uint8List.fromList([1, 2, 3]);
      const receiptUrl =
          'https://storage.example/storage/v1/object/public/'
          'firebase_receipts/bill-1/receipt.jpg';
      await database.saveCachedBill(
        CachedBillsCompanion.insert(
          id: 'bill-1',
          shopName: const Value('ร้านทดสอบ'),
          ownerId: const Value('user-1'),
          cachedForUserId: const Value('user-1'),
          localImageBytes: Value(imageBytes),
          receiptJson: Value(
            jsonEncode({
              'items': [
                {'id': 'item-1', 'item_name': 'อาหาร', 'price': 10},
              ],
              'participant_totals': {'user-1': 10.0},
            }),
          ),
        ),
      );
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => storage.uploadReceiptBytes(any(), 'bill-1'),
      ).thenAnswer((_) async => receiptUrl);
      when(
        () => firebaseDb.saveCompletedBill(
          billId: 'bill-1',
          bill: any(named: 'bill'),
          participantTotals: any(named: 'participantTotals'),
        ),
      ).thenAnswer((invocation) async {
        final storedBill = await database.getCachedBill('bill-1');
        expect(storedBill?.receiptImageUrl, receiptUrl);
        expect(storedBill?.syncedWithServer, isFalse);
        final bill = invocation.namedArguments[#bill] as Map<String, dynamic>;
        expect(bill['receipt_image_url'], receiptUrl);
        expect(
          (bill['receipt_json'] as Map<String, dynamic>)['items'],
          isNotEmpty,
        );
        expect(invocation.namedArguments[#participantTotals], {'user-1': 10.0});
        return 'bill-1';
      });
      when(
        () => firebaseDb.getBillsForUser('user-1'),
      ).thenAnswer((_) async => []);

      await repository.syncWithCloud(userId: 'user-1');

      final savedBill = await database.getCachedBill('bill-1');
      expect(savedBill?.receiptImageUrl, receiptUrl);
      expect(savedBill?.syncedWithServer, isTrue);
      final uploadedBytes =
          verify(
                () => storage.uploadReceiptBytes(captureAny(), 'bill-1'),
              ).captured.single
              as Uint8List;
      expect(uploadedBytes, imageBytes);
      verify(
        () => firebaseDb.saveCompletedBill(
          billId: 'bill-1',
          bill: any(named: 'bill'),
          participantTotals: any(named: 'participantTotals'),
        ),
      ).called(1);
    },
  );

  test('does not attempt cloud sync when disconnected', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);

    await repository.syncWithCloud(userId: 'user-1');

    verifyNever(() => firebaseDb.getBillsForUser(any()));
    verifyNever(
      () => firebaseDb.saveCompletedBill(
        billId: any(named: 'billId'),
        bill: any(named: 'bill'),
        participantTotals: any(named: 'participantTotals'),
      ),
    );
  });

  test('merges Firestore items and receipt URLs into local history', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => firebaseDb.getBillsForUser('user-1')).thenAnswer(
      (_) async => [
        {
          'id': 'remote-bill',
          'owner_id': 'user-1',
          'shop_name': 'Cloud bill',
          'total_amount': 25.0,
          'created_at': Timestamp.fromDate(DateTime(2026, 1, 2)),
          'receipt_image_url': 'http://127.0.0.1:1/receipt.jpg',
          'receipt_json': {'items': []},
        },
      ],
    );
    when(() => firebaseDb.getBillItems('remote-bill')).thenAnswer(
      (_) async => [
        {'id': 'item-1', 'item_name': 'ชา', 'price': 25},
      ],
    );
    when(() => firebaseDb.getBillParticipants('remote-bill')).thenAnswer(
      (_) async => [
        {'profile_id': 'user-1', 'amount_owed': 25},
      ],
    );

    await repository.syncWithCloud(userId: 'user-1');
    final bill = await database.getCachedBill('remote-bill');

    expect(bill?.receiptImageUrl, 'http://127.0.0.1:1/receipt.jpg');
    expect(
      (jsonDecode(bill!.receiptJson!) as Map<String, dynamic>)['items'],
      hasLength(1),
    );
    expect(bill.syncedWithServer, isTrue);
  });

  test(
    'stores local bill data and returns it in descending date order',
    () async {
      await repository.createBillLocally(
        billId: 'bill-old',
        userId: 'user-1',
        bill: {
          'shop_name': 'Old bill',
          'total_amount': 10,
          'receipt_date': '2026-10-01T10:00:00.000',
          'receipt_json': {'items': []},
        },
        participantTotals: {},
      );
      await repository.createBillLocally(
        billId: 'bill-new',
        userId: 'user-1',
        bill: {
          'shop_name': 'New bill',
          'total_amount': 20,
          'receipt_date': '2026-10-02T10:00:00.000',
          'receipt_json': {'items': []},
        },
        participantTotals: {},
      );

      final bills = await repository.getBills(
        userId: 'user-1',
        syncInBackground: false,
      );

      expect(bills.map((bill) => bill['id']), ['bill-new', 'bill-old']);
      expect(bills.first['synced_with_server'], isFalse);
      expect(bills.first['receipt_json'], {
        'items': [],
        'participant_totals': {},
      });
    },
  );

  test(
    'watches local Drift bills and returns an empty stream for no user',
    () async {
      await database.saveCachedBill(
        CachedBillsCompanion.insert(
          id: 'bill-watch',
          shopName: const Value('Watched bill'),
          cachedForUserId: const Value('user-1'),
          receiptDate: const Value('2026-10-01T10:00:00.000'),
        ),
      );

      final bills = await repository
          .getBillsStream(userId: 'user-1')
          .first
          .timeout(const Duration(seconds: 2));
      final noUserBills = await repository.getBillsStream(userId: null).first;

      expect(bills.single['id'], 'bill-watch');
      expect(noUserBills, isEmpty);
    },
  );

  test('updates bill claims and participant payment status locally', () async {
    await repository.createBillLocally(
      billId: 'bill-edit',
      userId: 'user-1',
      bill: {
        'shop_name': 'Editable',
        'total_amount': 50,
        'receipt_json': {'items': []},
      },
      participantTotals: {},
    );

    await repository.updateBillLocally(
      billId: 'bill-edit',
      userId: 'user-1',
      data: {
        'items': [
          {
            'id': 'item-1',
            'item_name': 'Tea',
            'claims': {'user-1': 1},
          },
        ],
        'participant_totals': {'user-1': 50},
      },
    );
    await repository.updateParticipantStatusLocally(
      billId: 'bill-edit',
      userId: 'user-1',
      profileId: 'user-1',
      status: 'paid',
    );

    final bill = await database.getCachedBill('bill-edit');
    final receiptJson = jsonDecode(bill!.receiptJson!) as Map<String, dynamic>;
    expect(receiptJson['items'], hasLength(1));
    expect(receiptJson['participant_totals'], {'user-1': 50});
    expect(receiptJson['participant_statuses'], {'user-1': 'paid'});
    expect(bill.syncedWithServer, isFalse);
  });

  test('keeps bill pending if Firestore write fails', () async {
    await repository.createBillLocally(
      billId: 'bill-retry',
      userId: 'user-1',
      bill: {'shop_name': 'Retry', 'total_amount': 10},
      participantTotals: {},
    );
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      () => firebaseDb.saveCompletedBill(
        billId: 'bill-retry',
        bill: any(named: 'bill'),
        participantTotals: any(named: 'participantTotals'),
      ),
    ).thenThrow(StateError('Firestore write failed'));

    await expectLater(
      repository.syncWithCloud(userId: 'user-1'),
      throwsA(isA<StateError>()),
    );

    final bill = await database.getCachedBill('bill-retry');
    expect(bill?.syncedWithServer, isFalse);
  });

  test(
    'syncs queued participant statuses after creating the cloud bill',
    () async {
      await repository.createBillLocally(
        billId: 'bill-status',
        userId: 'user-1',
        bill: {
          'shop_name': 'Status',
          'total_amount': 40,
          'receipt_json': {
            'participant_statuses': {'friend-1': 'paid'},
          },
        },
        participantTotals: {'friend-1': 40},
      );
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => firebaseDb.saveCompletedBill(
          billId: 'bill-status',
          bill: any(named: 'bill'),
          participantTotals: {'friend-1': 40},
        ),
      ).thenAnswer((_) async => 'bill-status');
      when(
        () => firebaseDb.updateParticipantStatus(
          'bill-status',
          'friend-1',
          'paid',
        ),
      ).thenAnswer((_) async {});
      when(
        () => firebaseDb.getBillsForUser('user-1'),
      ).thenAnswer((_) async => []);

      await repository.syncWithCloud(userId: 'user-1');

      verify(
        () => firebaseDb.updateParticipantStatus(
          'bill-status',
          'friend-1',
          'paid',
        ),
      ).called(1);
      expect(
        (await database.getCachedBill('bill-status'))?.syncedWithServer,
        isTrue,
      );
    },
  );

  test('caches Firestore bills and supports local draft operations', () async {
    final localRepository = LocalBillRepository(db: database);
    final cached = await localRepository.cacheFirebaseBills([
      {
        'id': 'bill-cached',
        'owner_id': 'user-1',
        'shop_name': 'Cached',
        'total_amount': '33.5',
        'created_at': Timestamp.fromDate(DateTime(2026, 10, 4)),
        'receipt_json': {'items': []},
        'sharers_json': {
          'user-1': ['friend-1'],
        },
        'receipt_image_url': 'http://storage.example/receipt.jpg',
      },
    ], cachedForUserId: 'user-1');
    final cachedRows = await localRepository.getCachedBills();
    final draftId = await localRepository.saveDraft(
      shopName: 'Draft',
      totalAmount: 12,
      items: [
        {'name': 'Tea'},
      ],
    );
    final drafts = await localRepository.getDrafts();

    expect(
      cached.single['receipt_image_url'],
      'http://storage.example/receipt.jpg',
    );
    expect(cachedRows.single['total_amount'], 33.5);
    expect(cachedRows.single['receipt_json'], {'items': []});
    expect(cachedRows.single['sharers_json'], {
      'user-1': ['friend-1'],
    });
    expect(drafts.single.shopName, 'Draft');
    expect(await localRepository.deleteDraft(draftId), 1);
    expect(await localRepository.getDrafts(), isEmpty);
  });
}
