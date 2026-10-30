import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CachedBills, OfflineDrafts, Bills, BillItems, ItemClaims],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(bills);
        await m.createTable(billItems);
        await m.createTable(itemClaims);
      }
    },
  );

  Future<List<Bill>> getAllBills() {
    return (select(bills)..orderBy([
          (table) => OrderingTerm(
            expression: table.createdAt,
            mode: OrderingMode.desc,
          ),
        ]))
        .get();
  }

  Stream<List<Bill>> watchAllBills() => select(bills).watch();

  Future<Bill?> getBill(String id) =>
      (select(bills)..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<List<BillItem>> getBillItems(String billId) =>
      (select(billItems)..where((table) => table.billId.equals(billId))).get();

  Future<List<ItemClaim>> getItemClaims(String itemId) =>
      (select(itemClaims)..where((table) => table.itemId.equals(itemId))).get();

  Future<void> saveBillGraph({
    required BillsCompanion bill,
    required List<BillItemsCompanion> items,
    required List<ItemClaimsCompanion> claims,
  }) async {
    await transaction(() async {
      await into(bills).insertOnConflictUpdate(bill);
      await (delete(itemClaims)..where(
            (table) => table.itemId.isIn(items.map((item) => item.id.value)),
          ))
          .go();
      await (delete(
        billItems,
      )..where((table) => table.billId.equals(bill.id.value))).go();
      await batch((batch) {
        batch.insertAllOnConflictUpdate(billItems, items);
        batch.insertAllOnConflictUpdate(itemClaims, claims);
      });
    });
  }

  Future<void> markBillSynced(String id) async {
    await (update(bills)..where((table) => table.id.equals(id))).write(
      const BillsCompanion(syncedWithServer: Value(true)),
    );
  }

  // Cache Bills (Offline first)
  Future<void> cacheBills(List<CachedBillsCompanion> bills) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedBills, bills);
    });
  }

  Future<List<CachedBill>> getAllCachedBills() {
    return (select(cachedBills)..orderBy([
          (t) => OrderingTerm(expression: t.cachedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Stream<List<CachedBill>> watchAllCachedBills() {
    return (select(cachedBills)..orderBy([
          (t) => OrderingTerm(expression: t.cachedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<CachedBill?> getCachedBill(String id) {
    return (select(
      cachedBills,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Offline Drafts
  Future<int> insertDraft(OfflineDraftsCompanion draft) {
    return into(offlineDrafts).insert(draft);
  }

  Future<List<OfflineDraft>> getAllDrafts() {
    return (select(offlineDrafts)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<int> deleteDraft(int id) {
    return (delete(offlineDrafts)..where((t) => t.id.equals(id))).go();
  }

  Future<int> clearCache() {
    return delete(cachedBills).go();
  }
}
