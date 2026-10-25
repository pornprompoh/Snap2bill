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

class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get totalAmount => real()();
  RealColumn get vat => real().withDefault(const Constant(0.0))();
  RealColumn get serviceCharge => real().withDefault(const Constant(0.0))();
  TextColumn get hostId => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncedWithServer =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class BillItems extends Table {
  TextColumn get id => text()();
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ItemClaims extends Table {
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(BillItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  IntColumn get claimedQuantity => integer()();
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
