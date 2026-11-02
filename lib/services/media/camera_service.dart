import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'camera_service_mobile.dart'
    if (dart.library.js_interop) 'camera_service_web.dart' as platform;

class CameraService {
  static Future<Uint8List?> captureReceiptPhoto(BuildContext context) {
    return platform.captureReceiptPhoto(context);
  }
}
