// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptShareService {
  static Future<Uint8List?> captureWidget(GlobalKey boundaryKey) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt widget: $e');
      return null;
    }
  }

  static Future<void> shareReceipt({
    required GlobalKey boundaryKey,
    required String shopName,
    required double totalAmount,
    String? message,
  }) async {
    final imageBytes = await captureWidget(boundaryKey);
    final shareText =
        message ??
        'สรุปยอดบิล: $shopName\nยอดรวม: ${totalAmount.toStringAsFixed(2)} บาท\nแชร์จาก Snap2Bill';

    if (imageBytes != null) {
      await Share.shareXFiles([
        XFile.fromData(
          imageBytes,
          mimeType: 'image/png',
          name: 'receipt_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      ], text: shareText);
    } else {
      await Share.share(shareText);
    }
  }
}
