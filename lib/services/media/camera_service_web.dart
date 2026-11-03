import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'camera_capture_dialog_web.dart';

Future<Uint8List?> captureReceiptPhoto(BuildContext context) =>
    captureReceiptPhotoWithControls(context);
