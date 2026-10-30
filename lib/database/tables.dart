import 'package:drift/drift.dart';

class CachedBills extends Table {
  TextColumn get id => text()();
  TextColumn get shopName => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get receiptDate => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get receiptJson => text().nullable()();
  TextColumn get sharersJson => text().nullable()();
  TextColumn get localImagePath =>
      text().nullable().named('receipt_image_local_path')();
  BlobColumn get localImageBytes => blob().nullable()();
  TextColumn get receiptImageUrl => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get cachedForUserId => text().nullable()();
  BoolColumn get syncedWithServer =>
      boolean().withDefault(const Constant(false))();
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
