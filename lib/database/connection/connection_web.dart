// ignore_for_file: deprecated_member_use
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final storage = await DriftWebStorage.indexedDbIfSupported('snap2bill_local');
    return WebDatabase.withStorage(storage);
  });
}
