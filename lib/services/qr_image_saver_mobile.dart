import 'dart:typed_data';

import 'package:gal/gal.dart';

Future<void> saveQrImage(Uint8List bytes, String filename) async {
  if (!await Gal.hasAccess()) {
    await Gal.requestAccess();
  }
  if (!await Gal.hasAccess()) {
    throw StateError('ไม่ได้รับอนุญาตให้บันทึกรูปลงคลังภาพ');
  }

  await Gal.putImageBytes(bytes);
}
