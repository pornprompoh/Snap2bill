import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CachedBills, OfflineDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // Cache Bills (Offline first)
  Future<void> cacheBills(List<CachedBillsCompanion> bills) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedBills, bills);
    });
  }

  Future<List<CachedBill>> getAllCachedBills() {
    return (select(cachedBills)
          ..orderBy([
            (t) => OrderingTerm(expression: t.cachedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Stream<List<CachedBill>> watchAllCachedBills() {
    return (select(cachedBills)
          ..orderBy([
            (t) => OrderingTerm(expression: t.cachedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<CachedBill?> getCachedBill(String id) {
    return (select(cachedBills)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Offline Drafts
  Future<int> insertDraft(OfflineDraftsCompanion draft) {
    return into(offlineDrafts).insert(draft);
  }

  Future<List<OfflineDraft>> getAllDrafts() {
    return (select(offlineDrafts)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
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
