import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'camera_capture_dialog.dart';

Future<Uint8List?> captureReceiptPhoto(BuildContext context) async {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return captureReceiptPhotoWithControls(context);
  }

  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.rear,
  );
  return picked?.readAsBytes();
}
