import 'package:drift/drift.dart';

import '../models/bill_model.dart';
import '../services/supabase_db_service.dart';
import 'app_database.dart';

class BillRepository {
  final AppDatabase _database;
  final SupabaseDbService _supabase;

  BillRepository({AppDatabase? database, SupabaseDbService? supabase})
    : _database = database ?? AppDatabase(),
      _supabase = supabase ?? SupabaseDbService();

  AppDatabase get database => _database;

  Future<List<BillModel>> getBills() async {
    final rows = await _database.getAllBills();
    return [
      for (final row in rows)
        BillModel(
          id: row.id,
          ownerId: row.hostId,
          shopName: row.title,
          subTotal: row.totalAmount - row.vat - row.serviceCharge,
          vatAmount: row.vat,
          serviceCharge: row.serviceCharge,
          totalAmount: row.totalAmount,
          finalTotal: row.totalAmount,
          status: row.syncedWithServer ? 'synced' : 'offline',
        ),
    ];
  }

  Future<void> saveOrUpdateBill(
    BillModel bill, {
    Iterable<BillItemModel> items = const [],
    bool syncedWithServer = false,
  }) async {
    final itemRows = <BillItemsCompanion>[];
    final claimRows = <ItemClaimsCompanion>[];
    for (final item in items) {
      itemRows.add(
        BillItemsCompanion.insert(
          id: item.id,
          billId: item.billId,
          name: item.itemName,
          price: item.price,
          quantity: item.quantity,
        ),
      );
      for (final entry in item.userQuantities.entries) {
        claimRows.add(
          ItemClaimsCompanion.insert(
            id: '${item.id}:${entry.key}',
            itemId: item.id,
            userId: entry.key,
            claimedQuantity: entry.value,
            isShared: const Value(false),
          ),
        );
      }
      for (final userId in item.sharedUsers) {
        claimRows.add(
          ItemClaimsCompanion.insert(
            id: '${item.id}:shared:$userId',
            itemId: item.id,
            userId: userId,
            claimedQuantity: 0,
            isShared: const Value(true),
          ),
        );
      }
    }

    await _database.saveBillGraph(
      bill: BillsCompanion.insert(
        id: bill.id,
        title: bill.shopName ?? '',
        totalAmount: bill.finalTotal == 0 ? bill.totalAmount : bill.finalTotal,
        vat: Value(bill.vatAmount),
        serviceCharge: Value(bill.serviceCharge),
        hostId: bill.ownerId,
        createdAt: DateTime.tryParse(bill.receiptDate ?? '') ?? DateTime.now(),
        syncedWithServer: Value(syncedWithServer),
      ),
      items: itemRows,
      claims: claimRows,
    );
  }

  Future<void> syncWithSupabase() async {
    final remoteBills = await _supabase.getMyBills();
    for (final bill in remoteBills) {
      await saveOrUpdateBill(bill, syncedWithServer: true);
    }
  }

  Future<void> dispose() => _database.close();
}
