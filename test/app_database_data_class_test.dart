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
    'CachedBill data class serializes, copies, and compares all fields',
    () async {
      final createdAt = DateTime.utc(2026, 11, 1);
      final cachedAt = DateTime.utc(2026, 11, 2);
      await database.cacheBills([
        CachedBillsCompanion.insert(
          id: 'bill-1',
          shopName: const Value('Cafe'),
          totalAmount: const Value(125),
          receiptDate: const Value('2026-11-01'),
          status: const Value('open'),
          receiptJson: const Value('{"items":[]}'),
          sharersJson: const Value('{}'),
          payloadJson: const Value('{"revision":1}'),
          localImagePath: const Value('receipt.jpg'),
          syncStatus: const Value('pending'),
          createdAt: Value(createdAt),
          cachedAt: Value(cachedAt),
        ),
      ]);

      final bill = (await database.getCachedBill('bill-1'))!;
      final restored = CachedBill.fromJson(bill.toJson());
      expect(restored, bill);
      expect(restored.hashCode, bill.hashCode);
      expect(identical(bill, bill), isTrue);
      expect(bill.toString(), contains('CachedBill('));
      expect(CachedBill.fromJson(bill.toJson()), bill);
      expect(bill.toColumns(true).keys, containsAll(['id', 'total_amount']));
      expect(
        bill.toColumns(false).keys,
        containsAll(['shop_name', 'receipt_json']),
      );
      expect(bill.toCompanion(true).shopName.present, isTrue);
      expect(bill.copyWith(shopName: const Value(null)).shopName, isNull);
      expect(
        bill
            .copyWithCompanion(
              const CachedBillsCompanion(status: Value('settled')),
            )
            .status,
        'settled',
      );
      expect(
        bill,
        isNot(CachedBill.fromJson({...bill.toJson(), 'id': 'other'})),
      );

      final nullFields = CachedBill(
        id: 'null-fields',
        totalAmount: 0,
        status: 'draft',
        syncStatus: 'synced',
        createdAt: createdAt,
        cachedAt: cachedAt,
      );
      expect(nullFields.toColumns(true).containsKey('shop_name'), isFalse);
      expect(nullFields.toColumns(false).containsKey('shop_name'), isTrue);
      expect(nullFields.toCompanion(true).shopName.present, isFalse);
      expect(nullFields.toCompanion(false).shopName.value, isNull);
    },
  );

  test(
    'CachedProfile data class supports round trips and companion updates',
    () async {
      final cachedAt = DateTime.utc(2026, 11, 3);
      await database.cacheProfile(
        CachedProfilesCompanion.insert(
          id: 'profile-1',
          payloadJson: '{"name":"Mina"}',
          cachedAt: Value(cachedAt),
        ),
      );

      final profile = (await database.getCachedProfile('profile-1'))!;
      expect(CachedProfile.fromJson(profile.toJson()), profile);
      expect(profile.toString(), contains('CachedProfile('));
      expect(profile.toColumns(true).keys, {'id', 'payload_json', 'cached_at'});
      expect(profile.toCompanion(true).payloadJson.value, '{"name":"Mina"}');
      expect(profile.copyWith(payloadJson: '{}').payloadJson, '{}');
      expect(
        profile
            .copyWithCompanion(
              const CachedProfilesCompanion(
                payloadJson: Value('{"updated":true}'),
              ),
            )
            .payloadJson,
        '{"updated":true}',
      );
      expect(
        profile,
        isNot(
          CachedProfile(
            id: 'different',
            payloadJson: profile.payloadJson,
            cachedAt: cachedAt,
          ),
        ),
      );
      expect(profile.hashCode, profile.hashCode);
    },
  );

  test(
    'CachedRoom data class supports round trips and immutable copies',
    () async {
      final cachedAt = DateTime.utc(2026, 11, 4);
      await database.cacheRoom(
        CachedRoomsCompanion.insert(
          roomCode: 'ROOM01',
          payloadJson: '{"members":2}',
          cachedAt: Value(cachedAt),
        ),
      );

      final room = (await database.getCachedRoom('ROOM01'))!;
      expect(CachedRoom.fromJson(room.toJson()), room);
      expect(room.toString(), contains('CachedRoom('));
      expect(room.toColumns(false).keys, {
        'room_code',
        'payload_json',
        'cached_at',
      });
      expect(room.toCompanion(true).roomCode.value, 'ROOM01');
      expect(room.copyWith(payloadJson: '{}').payloadJson, '{}');
      expect(
        room
            .copyWithCompanion(
              const CachedRoomsCompanion(
                payloadJson: Value('{"updated":true}'),
              ),
            )
            .payloadJson,
        '{"updated":true}',
      );
      expect(
        room,
        isNot(CachedRoom.fromJson({...room.toJson(), 'roomCode': 'OTHER'})),
      );
      expect(room.hashCode, room.hashCode);
    },
  );

  test(
    'OfflineDraft data class supports round trips and partial copies',
    () async {
      final createdAt = DateTime.utc(2026, 11, 5);
      final id = await database.insertDraft(
        OfflineDraftsCompanion.insert(
          shopName: 'Lunch',
          totalAmount: 75,
          itemsJson: '[{"name":"Rice"}]',
          createdAt: Value(createdAt),
        ),
      );

      final draft = await (database.select(
        database.offlineDrafts,
      )..where((row) => row.id.equals(id))).getSingle();
      expect(OfflineDraft.fromJson(draft.toJson()), draft);
      expect(draft.toString(), contains('OfflineDraft('));
      expect(draft.toColumns(true).keys, {
        'id',
        'shop_name',
        'total_amount',
        'items_json',
        'created_at',
      });
      expect(draft.toCompanion(false).itemsJson.value, '[{"name":"Rice"}]');
      expect(draft.copyWith(shopName: 'Dinner').shopName, 'Dinner');
      expect(
        draft
            .copyWithCompanion(
              const OfflineDraftsCompanion(shopName: Value('Supper')),
            )
            .shopName,
        'Supper',
      );
      expect(
        draft,
        isNot(OfflineDraft.fromJson({...draft.toJson(), 'itemsJson': '[]'})),
      );
      expect(draft.hashCode, draft.hashCode);
    },
  );

  test(
    'generated table managers create, filter, order, update, and delete rows',
    () async {
      await database.managers.cachedBills.create(
        (row) => row(id: 'manager-bill', shopName: const Value('Original')),
      );
      final bills = await database.managers.cachedBills
          .filter((row) => row.id.equals('manager-bill'))
          .orderBy((row) => row.createdAt.desc())
          .get();
      expect(bills.single.shopName, 'Original');
      final changedBills = await database.managers.cachedBills
          .filter((row) => row.id.equals('manager-bill'))
          .update((row) => row(shopName: const Value('Updated')));
      expect(changedBills, 1);
      expect(
        (await database.managers.cachedBills
                .filter((row) => row.id.equals('manager-bill'))
                .get())
            .single
            .shopName,
        'Updated',
      );
      expect(
        await database.managers.cachedBills
            .filter((row) => row.id.equals('manager-bill'))
            .delete(),
        1,
      );

      await database.managers.cachedProfiles.create(
        (row) => row(id: 'manager-profile', payloadJson: '{}'),
      );
      expect(
        (await database.managers.cachedProfiles
                .filter((row) => row.id.equals('manager-profile'))
                .get())
            .single
            .payloadJson,
        '{}',
      );

      await database.managers.cachedRooms.create(
        (row) => row(roomCode: 'MANAGER', payloadJson: '{"active":true}'),
      );
      expect(
        await database.managers.cachedRooms
            .filter((row) => row.roomCode.equals('MANAGER'))
            .count(),
        1,
      );

      await database.managers.offlineDrafts.create(
        (row) =>
            row(shopName: 'Manager draft', totalAmount: 12, itemsJson: '[]'),
      );
      expect(
        (await database.managers.offlineDrafts
                .filter((row) => row.shopName.equals('Manager draft'))
                .get())
            .single
            .totalAmount,
        12,
      );
    },
  );
}
