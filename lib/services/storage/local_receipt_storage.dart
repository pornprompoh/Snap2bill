import 'dart:convert';

import 'package:flutter/services.dart';

import 'local_receipt_storage_stub.dart'
    if (dart.library.io) 'local_receipt_storage_native.dart'
    as implementation;

Future<String> saveLocalReceipt(Uint8List bytes, String billId) {
  return implementation.saveLocalReceipt(bytes, billId);
}

Future<Uint8List?> readLocalReceipt(String path) {
  return implementation.readLocalReceipt(path);
}

Future<String> cacheRemoteImage(String source, String fileName) async {
  final uri = Uri.tryParse(source);
  if (uri == null) throw FormatException('Invalid image source', source);
  Uint8List bytes;
  if (source.startsWith('data:image/')) {
    final separator = source.indexOf(',');
    if (separator < 0) throw FormatException('Invalid image data', source);
    bytes = base64Decode(source.substring(separator + 1));
  } else {
    final data = await NetworkAssetBundle(
      uri,
    ).load(source).timeout(const Duration(seconds: 10));
    bytes = data.buffer.asUint8List();
  }
  return saveLocalReceipt(bytes, fileName);
}
