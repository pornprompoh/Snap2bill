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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await _addBillColumnIfMissing(migrator, cachedBills.payloadJson);
        await _addBillColumnIfMissing(migrator, cachedBills.localImagePath);
        await _addBillColumnIfMissing(migrator, cachedBills.syncStatus);
        if (!await _tableExists(cachedProfiles.actualTableName)) {
          await migrator.createTable(cachedProfiles);
        }
      }
      if (from < 3) {
        if (!await _tableExists(cachedRooms.actualTableName)) {
          await migrator.createTable(cachedRooms);
        }
      }
      if (from < 4) {
        if (!await _billColumnExists(cachedBills.createdAt.name)) {
          await customStatement(
            'ALTER TABLE cached_bills '
            'ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0',
          );
        }
        await customStatement('''
          UPDATE cached_bills
          SET created_at = COALESCE(
            CASE
              WHEN json_valid(payload_json)
              THEN CAST(strftime('%s', json_extract(payload_json, '\$.created_at')) AS INTEGER)
            END,
            CAST(strftime('%s', receipt_date) AS INTEGER),
            cached_at
          )
        ''');
      }
    },
  );

  Future<void> _addBillColumnIfMissing(
    Migrator migrator,
    GeneratedColumn<Object> column,
  ) async {
    if (await _billColumnExists(column.name)) return;
    await migrator.addColumn(cachedBills, column);
  }

  Future<bool> _billColumnExists(String columnName) async {
    final columns = await customSelect('PRAGMA table_info(cached_bills)').get();
    return columns.any((row) => row.read<String>('name') == columnName);
  }

  Future<bool> _tableExists(String tableName) async {
    final result = await customSelect(
      'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      variables: [const Variable<String>('table'), Variable<String>(tableName)],
    ).getSingleOrNull();
    return result != null;
  }

  // Cache Bills (Offline first)
  Future<void> cacheBills(List<CachedBillsCompanion> bills) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedBills, bills);
    });
  }

  Future<List<CachedBill>> getAllCachedBills() {
    return (select(cachedBills)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Stream<List<CachedBill>> watchAllCachedBills() {
    return (select(cachedBills)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
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
