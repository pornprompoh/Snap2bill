import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CachedBills, OfflineDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(cachedBills, cachedBills.localImagePath);
        await migrator.addColumn(cachedBills, cachedBills.receiptImageUrl);
      }
      if (from < 3) {
        await migrator.addColumn(cachedBills, cachedBills.localImageBytes);
        await migrator.addColumn(cachedBills, cachedBills.ownerId);
        await migrator.addColumn(cachedBills, cachedBills.cachedForUserId);
        await migrator.addColumn(cachedBills, cachedBills.syncedWithServer);
      }
    },
  );

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

  Future<List<CachedBill>> getCachedBillsForUser(String userId) {
    return (select(cachedBills)
          ..where((bill) => bill.cachedForUserId.equals(userId))
          ..orderBy([
            (bill) => OrderingTerm(
              expression: bill.cachedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Stream<List<CachedBill>> watchAllCachedBills() {
    return (select(cachedBills)..orderBy([
          (t) => OrderingTerm(expression: t.cachedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Stream<List<CachedBill>> watchCachedBillsForUser(String userId) {
    return (select(cachedBills)
          ..where((bill) => bill.cachedForUserId.equals(userId))
          ..orderBy([
            (bill) => OrderingTerm(
              expression: bill.cachedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<List<CachedBill>> getUnsyncedBills(String userId) {
    return (select(cachedBills)..where(
          (bill) =>
              bill.cachedForUserId.equals(userId) &
              bill.syncedWithServer.equals(false),
        ))
        .get();
  }

  Future<void> assignLegacyBillsToUser(String userId) async {
    await (update(
      cachedBills,
    )..where((bill) => bill.cachedForUserId.isNull())).write(
      CachedBillsCompanion(
        cachedForUserId: Value(userId),
        syncedWithServer: const Value(true),
      ),
    );
  }

  Future<void> saveCachedBill(CachedBillsCompanion bill) async {
    await into(cachedBills).insertOnConflictUpdate(bill);
  }

  Future<void> updateCachedBill(String id, CachedBillsCompanion bill) async {
    await (update(cachedBills)..where((row) => row.id.equals(id))).write(bill);
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
