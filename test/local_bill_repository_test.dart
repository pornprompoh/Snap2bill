import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/data/repositories/local_bill_repository.dart';
import 'package:snap2bill/database/app_database.dart';
import 'package:snap2bill/models/bill_model.dart';

void main() {
  late AppDatabase database;
  late LocalBillRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalBillRepository(db: database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'local bill retains detail, participants, image path, and sync state',
    () async {
      final bill = <String, dynamic>{
        'id': 'bill-local',
        'owner_id': 'owner-1',
        'shop_name': 'ร้านทดสอบ',
        'created_at': '2026-11-05T00:00:00Z',
        'total_amount': 120,
        'status': 'pending',
        'receipt_json': {
          'items': [
            {'item_name': 'ชา', 'unit_price': 60, 'qty': 2},
          ],
        },
        'sharers_json': {
          '0': [
            {'user_id': 'friend-1', 'user_name': 'เพื่อน'},
          ],
        },
      };

      await repository.saveLocalBill(
        bill: bill,
        participants: [
          {'profile_id': 'friend-1', 'amount_owed': 120, 'status': 'pending'},
        ],
        localImagePath: 'local/receipt.jpg',
      );

      final cached = await repository.getCachedBillData('bill-local');
      expect(cached?['receipt_json']['items'], hasLength(1));
      expect(cached?['bill_participants'].single['profile_id'], 'friend-1');
      expect(cached?['local_image_path'], 'local/receipt.jpg');
      expect(cached?['sync_status'], 'pending');
    },
  );

  test(
    'online refresh stores the complete bill payload for offline detail',
    () async {
      await repository.cacheSupabaseBills([
        {
          'id': 'bill-remote',
          'shop_name': 'ร้านออนไลน์',
          'total_amount': 85,
          'receipt_json': {
            'items': [
              {'item_name': 'กาแฟ', 'unit_price': 85, 'qty': 1},
            ],
          },
          'bill_participants': [
            {'profile_id': 'friend-2', 'amount_owed': 85},
          ],
          'bill_payments': [
            {'profile_id': 'friend-2', 'status': 'paid'},
          ],
        },
      ]);

      final cached = await repository.getCachedBillData('bill-remote');
      expect(cached?['bill_participants'].single['profile_id'], 'friend-2');
      expect(cached?['bill_payments'].single['status'], 'paid');
      expect(cached?['receipt_json']['items'].single['item_name'], 'กาแฟ');
      expect(cached?['sync_status'], 'synced');
    },
  );

  test(
    'replacing a local bill id keeps its cached details and marks it synced',
    () async {
      await repository.saveLocalBill(
        bill: {
          'id': 'local-id',
          'shop_name': 'ร้าน',
          'total_amount': 50,
          'receipt_json': {'items': []},
        },
        participants: const [],
      );

      await repository.replaceCachedBillId('local-id', 'remote-id');

      expect(await repository.getCachedBillData('local-id'), isNull);
      final synced = await repository.getCachedBillData('remote-id');
      expect(synced?['sync_status'], 'synced');
      expect(synced?['shop_name'], 'ร้าน');
    },
  );

  test(
    'profiles and room members are available from the local database',
    () async {
      await repository.cacheProfile({
        'id': 'user-1',
        'display_name': 'ผู้ใช้ทดสอบ',
        'local_avatar_path': 'avatars/user-1.jpg',
      });
      await repository.cacheRoomMembers('ROOM01', const [
        RoomMember(
          id: 'guest-1',
          name: 'แขก',
          localAvatarPath: 'avatars/guest-1.jpg',
          isGuest: true,
        ),
      ]);

      expect(
        (await repository.getCachedProfile('user-1'))?['display_name'],
        'ผู้ใช้ทดสอบ',
      );
      final members = await repository.getCachedRoomMembers('ROOM01');
      expect(members.single.localAvatarPath, 'avatars/guest-1.jpg');
      expect(members.single.isGuest, isTrue);
    },
  );

  test(
    'past participants can be assembled from cached bill and profile data',
    () async {
      await repository.saveLocalBill(
        bill: {
          'id': 'bill-1',
          'owner_id': 'current-user',
          'shop_name': 'ร้าน',
          'sharers_json': {
            '0': [
              {'user_id': 'friend-user', 'user_name': 'เพื่อน'},
            ],
          },
          'receipt_json': {'items': []},
        },
        participants: const [
          {'profile_id': 'friend-user', 'amount_owed': 50},
        ],
      );
      await repository.cacheProfile({
        'id': 'friend-user',
        'display_name': 'ชื่อจากโปรไฟล์',
        'email': 'friend@example.com',
      });

      final friends = await repository.getCachedPastParticipants(
        'current-user',
      );

      expect(friends, hasLength(1));
      expect(friends.single.id, 'friend-user');
      expect(friends.single.displayName, 'ชื่อจากโปรไฟล์');
    },
  );

  test('cached bill lists are scoped to owner or participant', () async {
    await repository.saveLocalBill(
      bill: {
        'id': 'owned-bill',
        'owner_id': 'user-1',
        'shop_name': 'ของฉัน',
        'receipt_json': {'items': []},
      },
      participants: const [],
    );
    await repository.cacheSupabaseBills([
      {
        'id': 'participated-bill',
        'owner_id': 'user-2',
        'shop_name': 'บิลที่ร่วม',
        'bill_participants': [
          {'profile_id': 'user-1', 'amount_owed': 50},
        ],
      },
      {
        'id': 'other-users-bill',
        'owner_id': 'user-2',
        'shop_name': 'บิลของคนอื่น',
        'bill_participants': [
          {'profile_id': 'user-3', 'amount_owed': 50},
        ],
      },
    ]);

    final bills = await repository.getCachedBills(userId: 'user-1');
    expect(bills.map((bill) => bill['id']), {
      'owned-bill',
      'participated-bill',
    });
    expect(await repository.getCachedBills(userId: ''), isEmpty);
  });

  test(
    'cached bill lists are ordered by creation date, newest first',
    () async {
      await repository.cacheSupabaseBills([
        {
          'id': 'old-bill',
          'owner_id': 'user-1',
          'created_at': '2026-09-10T10:00:00Z',
          'receipt_date': '2026-11-04',
        },
        {
          'id': 'new-bill',
          'owner_id': 'user-1',
          'created_at': '2026-11-04T10:00:00Z',
          'receipt_date': '2026-09-10',
        },
      ]);

      final bills = await repository.getCachedBills(userId: 'user-1');
      final watchedBills = await repository
          .watchCachedBills(userId: 'user-1')
          .first;

      expect(bills.map((bill) => bill['id']), ['new-bill', 'old-bill']);
      expect(watchedBills.map((bill) => bill['id']), ['new-bill', 'old-bill']);
      expect(
        DateTime.parse(
          bills.first['created_at'] as String,
        ).isAtSameMomentAs(DateTime.utc(2026, 11, 4, 10)),
        isTrue,
      );
    },
  );

  test(
    'migration skips columns already present in an older database',
    () async {
      final legacyDatabase = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (database) {
            database.execute('''
            CREATE TABLE cached_bills (
              id TEXT NOT NULL PRIMARY KEY,
              shop_name TEXT,
              total_amount REAL NOT NULL DEFAULT 0,
              receipt_date TEXT,
              status TEXT NOT NULL DEFAULT 'draft',
              receipt_json TEXT,
              sharers_json TEXT,
              payload_json TEXT,
              cached_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
            )
          ''');
            database.execute('''
            INSERT INTO cached_bills (id, payload_json, cached_at)
            VALUES ('legacy-bill', '{"created_at":"2026-11-04T10:00:00Z"}', 1)
          ''');
            database.userVersion = 1;
          },
        ),
      );

      addTearDown(legacyDatabase.close);

      final bills = await legacyDatabase.getAllCachedBills();
      expect(bills, hasLength(1));
      expect(bills.single.id, 'legacy-bill');
      expect(
        bills.single.createdAt.isAtSameMomentAs(DateTime.utc(2026, 11, 4, 10)),
        isTrue,
      );
    },
  );
}
