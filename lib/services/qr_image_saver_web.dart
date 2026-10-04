import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> saveQrImage(Uint8List bytes, String filename) async {
  final body = web.document.body;
  if (body == null) {
    throw StateError('ไม่สามารถดาวน์โหลดรูปภาพจากเบราว์เซอร์ได้');
  }

  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  try {
    body.append(anchor);
    anchor.click();
  } finally {
    anchor.remove();
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 1),
        () => web.URL.revokeObjectURL(url),
      ),
    );
  }
}
