import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CachedBills, CachedProfiles, CachedRooms, OfflineDrafts],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(cachedBills, cachedBills.payloadJson);
        await migrator.addColumn(cachedBills, cachedBills.localImagePath);
        await migrator.addColumn(cachedBills, cachedBills.syncStatus);
        await migrator.createTable(cachedProfiles);
      }
      if (from < 3) {
        await migrator.createTable(cachedRooms);
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

  Future<void> cacheProfile(CachedProfilesCompanion profile) {
    return into(cachedProfiles).insertOnConflictUpdate(profile);
  }

  Future<CachedProfile?> getCachedProfile(String id) {
    return (select(
      cachedProfiles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CachedProfile>> getCachedProfiles(Iterable<String> ids) {
    return (select(cachedProfiles)..where((t) => t.id.isIn(ids))).get();
  }

  Future<void> cacheRoom(CachedRoomsCompanion room) {
    return into(cachedRooms).insertOnConflictUpdate(room);
  }

  Future<CachedRoom?> getCachedRoom(String roomCode) {
    return (select(
      cachedRooms,
    )..where((t) => t.roomCode.equals(roomCode))).getSingleOrNull();
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

  Future<int> deleteCachedBill(String id) {
    return (delete(cachedBills)..where((t) => t.id.equals(id))).go();
  }
}
