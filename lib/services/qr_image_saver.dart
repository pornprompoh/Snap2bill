import 'dart:typed_data';

import 'qr_image_saver_mobile.dart'
    if (dart.library.html) 'qr_image_saver_web.dart' as platform;

Future<void> saveQrImage(Uint8List bytes, String filename) {
  return platform.saveQrImage(bytes, filename);
}
