import 'package:drift/drift.dart';

class CachedBills extends Table {
  TextColumn get id => text()();
  TextColumn get shopName => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get receiptDate => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get receiptJson => text().nullable()();
  TextColumn get sharersJson => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class OfflineDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shopName => text()();
  RealColumn get totalAmount => real()();
  TextColumn get itemsJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
