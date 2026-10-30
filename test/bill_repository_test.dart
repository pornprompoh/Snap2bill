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
}
