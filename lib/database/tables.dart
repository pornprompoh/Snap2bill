import 'package:drift/drift.dart';

class CachedBills extends Table {
  TextColumn get id => text()();
  TextColumn get shopName => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get receiptDate => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get receiptJson => text().nullable()();
  TextColumn get sharersJson => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  TextColumn get localImagePath => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedRooms extends Table {
  TextColumn get roomCode => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {roomCode};
}

class OfflineDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shopName => text()();
  RealColumn get totalAmount => real()();
  TextColumn get itemsJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
