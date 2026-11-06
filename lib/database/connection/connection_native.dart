import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      return NativeDatabase.memory();
    }

    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'snap2bill.db'));
      return NativeDatabase.createInBackground(file);
    } on MissingPluginException {
      return NativeDatabase.memory();
    }
  });
}
