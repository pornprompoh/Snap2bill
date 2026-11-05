import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'cached bills support lookup, ordering, deletion, and clearing',
    () async {
      final oldest = DateTime.utc(2026, 1, 1);
      final newest = DateTime.utc(2026, 1, 3);
      final middle = DateTime.utc(2026, 1, 2);

      await database.cacheBills([
        CachedBillsCompanion.insert(
          id: 'oldest',
          shopName: const Value('Oldest'),
          createdAt: Value(oldest),
        ),
        CachedBillsCompanion.insert(
          id: 'newest',
          shopName: const Value('Newest'),
          createdAt: Value(newest),
        ),
        CachedBillsCompanion.insert(
          id: 'middle',
          shopName: const Value('Middle'),
          createdAt: Value(middle),
        ),
      ]);

      expect(
        (await database.getAllCachedBills()).map((bill) => bill.id).toList(),
        ['newest', 'middle', 'oldest'],
      );
      expect((await database.getCachedBill('middle'))?.shopName, 'Middle');
      expect(await database.getCachedBill('missing'), isNull);

      await database.deleteCachedBill('middle');
      expect(await database.getCachedBill('middle'), isNull);
      expect(await database.clearCache(), 2);
      expect(await database.getAllCachedBills(), isEmpty);
    },
  );

  test(
    'caching a bill with an existing id updates its stored values',
    () async {
      final originalDate = DateTime.utc(2026, 2, 1);
      final updatedDate = DateTime.utc(2026, 2, 2);

      await database.cacheBills([
        CachedBillsCompanion.insert(
          id: 'bill-1',
          shopName: const Value('Original shop'),
          totalAmount: const Value(12.5),
          payloadJson: const Value('{"revision":1}'),
          createdAt: Value(originalDate),
        ),
      ]);
      await database.cacheBills([
        CachedBillsCompanion.insert(
          id: 'bill-1',
          shopName: const Value('Updated shop'),
          totalAmount: const Value(25.0),
          payloadJson: const Value('{"revision":2}'),
          createdAt: Value(updatedDate),
        ),
      ]);

      final bill = await database.getCachedBill('bill-1');
      expect(bill?.shopName, 'Updated shop');
      expect(bill?.totalAmount, 25.0);
      expect(bill?.payloadJson, '{"revision":2}');
      expect(bill?.createdAt.toUtc(), updatedDate);
      expect(await database.getAllCachedBills(), hasLength(1));
    },
  );

  test('cached profiles insert, update, query by ids, and delete', () async {
    await database.cacheProfile(
      CachedProfilesCompanion.insert(
        id: 'profile-1',
        payloadJson: '{"name":"First"}',
      ),
    );
    await database.cacheProfile(
      CachedProfilesCompanion.insert(
        id: 'profile-2',
        payloadJson: '{"name":"Second"}',
      ),
    );
    await database.cacheProfile(
      CachedProfilesCompanion.insert(
        id: 'profile-1',
        payloadJson: '{"name":"Updated"}',
      ),
    );

    expect(
      (await database.getCachedProfile('profile-1'))?.payloadJson,
      '{"name":"Updated"}',
    );
    expect(
      (await database.getCachedProfiles([
        'profile-1',
        'profile-2',
      ])).map((profile) => profile.id).toSet(),
      {'profile-1', 'profile-2'},
    );
    expect(await database.getCachedProfiles([]), isEmpty);

    await (database.delete(
      database.cachedProfiles,
    )..where((profile) => profile.id.equals('profile-2'))).go();
    expect(await database.getCachedProfile('profile-2'), isNull);
  });

  test('cached rooms insert, update on conflict, and can be removed', () async {
    await database.cacheRoom(
      CachedRoomsCompanion.insert(
        roomCode: 'ROOM01',
        payloadJson: '{"members":1}',
      ),
    );
    await database.cacheRoom(
      CachedRoomsCompanion.insert(
        roomCode: 'ROOM01',
        payloadJson: '{"members":3}',
      ),
    );

    expect(
      (await database.getCachedRoom('ROOM01'))?.payloadJson,
      '{"members":3}',
    );
    expect(await database.getCachedRoom('missing'), isNull);

    await (database.delete(
      database.cachedRooms,
    )..where((room) => room.roomCode.equals('ROOM01'))).go();
    expect(await database.getCachedRoom('ROOM01'), isNull);
  });

  test('offline drafts insert in created order and delete by id', () async {
    final older = DateTime.utc(2026, 3, 1);
    final newer = DateTime.utc(2026, 3, 2);
    final olderId = await database.insertDraft(
      OfflineDraftsCompanion.insert(
        shopName: 'Older receipt',
        totalAmount: 10,
        itemsJson: '[]',
        createdAt: Value(older),
      ),
    );
    final newerId = await database.insertDraft(
      OfflineDraftsCompanion.insert(
        shopName: 'Newer receipt',
        totalAmount: 20,
        itemsJson: '[{"name":"Tea"}]',
        createdAt: Value(newer),
      ),
    );

    final drafts = await database.getAllDrafts();
    expect(drafts.map((draft) => draft.id), [newerId, olderId]);
    expect(drafts.first.shopName, 'Newer receipt');
    expect(drafts.first.itemsJson, '[{"name":"Tea"}]');

    expect(await database.deleteDraft(olderId), 1);
    expect((await database.getAllDrafts()).map((draft) => draft.id), [newerId]);
    expect(await database.deleteDraft(olderId), 0);
  });

  test('cached bill stream emits a snapshot after a cache write', () async {
    final firstSnapshot = database.watchAllCachedBills().first;

    await database.cacheBills([CachedBillsCompanion.insert(id: 'watched')]);
    final bills = await firstSnapshot;
    expect(bills, hasLength(1));
    expect(bills.single.id, 'watched');
  });

  test(
    'cached bill writes apply defaults and preserve all optional fields',
    () async {
      final date = DateTime.utc(2026, 4, 5);
      await database.cacheBills([
        CachedBillsCompanion.insert(
          id: 'full',
          shopName: const Value('Tea shop'),
          totalAmount: const Value(125.5),
          receiptDate: const Value('2026-04-05'),
          status: const Value('settled'),
          receiptJson: const Value('{"items":[]}'),
          sharersJson: const Value('{"u1":50}'),
          payloadJson: const Value('{"sync":true}'),
          localImagePath: const Value('receipts/full.jpg'),
          syncStatus: const Value('pending'),
          createdAt: Value(date),
          cachedAt: Value(date),
        ),
        CachedBillsCompanion.insert(id: 'defaults'),
      ]);

      final full = await database.getCachedBill('full');
      final defaults = await database.getCachedBill('defaults');
      expect(full, isNotNull);
      expect(full!.shopName, 'Tea shop');
      expect(full.totalAmount, 125.5);
      expect(full.receiptDate, '2026-04-05');
      expect(full.status, 'settled');
      expect(full.receiptJson, '{"items":[]}');
      expect(full.sharersJson, '{"u1":50}');
      expect(full.payloadJson, '{"sync":true}');
      expect(full.localImagePath, 'receipts/full.jpg');
      expect(full.syncStatus, 'pending');
      expect(full.createdAt.toUtc(), date);
      expect(full.cachedAt.toUtc(), date);
      expect(defaults!.totalAmount, 0);
      expect(defaults.status, 'draft');
      expect(defaults.syncStatus, 'synced');
    },
  );

  test(
    'cache clearing removes bills without touching other cached data',
    () async {
      await database.cacheBills([CachedBillsCompanion.insert(id: 'bill')]);
      await database.cacheProfile(
        CachedProfilesCompanion.insert(id: 'profile', payloadJson: '{}'),
      );
      await database.cacheRoom(
        CachedRoomsCompanion.insert(roomCode: 'ROOM01', payloadJson: '{}'),
      );
      await database.insertDraft(
        OfflineDraftsCompanion.insert(
          shopName: 'Draft',
          totalAmount: 10,
          itemsJson: '[]',
        ),
      );

      expect(await database.clearCache(), 1);
      expect(await database.getAllCachedBills(), isEmpty);
      expect(await database.getCachedProfile('profile'), isNotNull);
      expect(await database.getCachedRoom('ROOM01'), isNotNull);
      expect(await database.getAllDrafts(), hasLength(1));
    },
  );

  test('a failed transaction rolls back cache writes', () async {
    await expectLater(
      database.transaction(() async {
        await database.cacheBills([
          CachedBillsCompanion.insert(id: 'rolled-back'),
        ]);
        throw StateError('abort');
      }),
      throwsA(isA<StateError>()),
    );

    expect(await database.getCachedBill('rolled-back'), isNull);
  });
}
