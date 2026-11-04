import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> saveLocalReceipt(Uint8List bytes, String billId) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final receiptDirectory = Directory(
    path.join(documentsDirectory.path, 'receipts'),
  );
  await receiptDirectory.create(recursive: true);
  final file = File(path.join(receiptDirectory.path, '$billId.jpg'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Uint8List?> readLocalReceipt(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
