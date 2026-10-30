import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snap2bill/database/app_database.dart';
import 'package:snap2bill/repositories/bill_repository.dart';
import 'package:snap2bill/models/bill_model.dart';

void main() {
  late AppDatabase database;
  late BillRepository repository;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BillRepository(database: database);
  });

  tearDown(() => database.close());

  test(
    'saves a bill graph transactionally and reads it offline-first',
    () async {
      await repository.saveOrUpdateBill(
        BillModel(
          id: 'bill-1',
          ownerId: 'host-1',
          shopName: 'Cafe',
          subTotal: 100,
          vatAmount: 7,
          serviceCharge: 10,
          finalTotal: 117,
        ),
        items: [
          BillItemModel(
            id: 'item-1',
            billId: 'bill-1',
            itemName: 'Coffee',
            price: 100,
            quantity: 1,
            userQuantities: {'host-1': 1},
          ),
        ],
      );

      final bills = await repository.getBills();
      final items = await database.getBillItems('bill-1');
      final claims = await database.getItemClaims('item-1');

      expect(bills.single.shopName, 'Cafe');
      expect(items.single.name, 'Coffee');
      expect(claims.single.userId, 'host-1');
      expect(bills.single.status, 'offline');
    },
  );

  test('maps synchronized bills and computes their subtotal', () async {
    await repository.saveOrUpdateBill(
      BillModel(
        id: 'synced-bill',
        ownerId: 'host-1',
        shopName: 'Lunch',
        totalAmount: 117,
        finalTotal: 117,
        vatAmount: 7,
        serviceCharge: 10,
      ),
      syncedWithServer: true,
    );

    final bill = (await repository.getBills()).single;
    expect(bill.status, 'synced');
    expect(bill.subTotal, 100);
    expect(bill.finalTotal, 117);
  });

  test('caches remote bill data and decodes cached JSON', () async {
    await repository.cacheSupabaseBills([
      {
        'id': 'cached-1',
        'shop_name': 'Cafe',
        'total_amount': 125.5,
        'created_at': '2026-10-25T12:00:00Z',
        'receipt_json': {
          'items': [
            {'name': 'Coffee'},
          ],
        },
        'sharers_json': '{"host":["guest"]}',
      },
      {'shop_name': 'Missing id', 'total_amount': 10},
    ]);

    final cachedBills = await repository.getCachedBills();
    expect(cachedBills, hasLength(1));
    expect(cachedBills.single['id'], 'cached-1');
    expect(cachedBills.single['total_amount'], 125.5);
    expect(cachedBills.single['receipt_json'], {
      'items': [
        {'name': 'Coffee'},
      ],
    });
    expect(cachedBills.single['sharers_json'], {
      'host': ['guest'],
    });
    expect(cachedBills.single['is_cached'], isTrue);
  });

  test('keeps malformed cached JSON unavailable instead of throwing', () async {
    await database.cacheBills([
      CachedBillsCompanion.insert(
        id: 'malformed-cache',
        receiptJson: const Value('{'),
        sharersJson: const Value('not-json'),
      ),
    ]);

    final cachedBill = (await repository.getCachedBills()).single;
    expect(cachedBill['receipt_json'], isNull);
    expect(cachedBill['sharers_json'], isNull);
  });

  test('creates, lists, and deletes offline drafts', () async {
    final id = await repository.saveDraft(
      shopName: 'Dinner',
      totalAmount: 90,
      items: [
        {'name': 'Soup', 'price': 90},
      ],
    );

    final drafts = await repository.getDrafts();
    expect(drafts, hasLength(1));
    expect(drafts.single.id, id);
    expect(drafts.single.shopName, 'Dinner');
    expect(await repository.deleteDraft(id), 1);
    expect(await repository.getDrafts(), isEmpty);
  });
}
