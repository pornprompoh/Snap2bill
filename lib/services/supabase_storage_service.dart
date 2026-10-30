import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

const int _maxImageDimension = 1280;
const int _maxUploadBytes = 500 * 1024;
const String _receiptBucket = 'firebase_receipts';

Uint8List _compressReceipt(Uint8List sourceBytes) {
  final decodedImage = img.decodeImage(sourceBytes);
  if (decodedImage == null) {
    throw const FormatException('ไม่สามารถอ่านรูปภาพได้');
  }

  final orientedImage = img.bakeOrientation(decodedImage);
  final longestSide = math.max(orientedImage.width, orientedImage.height);
  final initialScale = math.min(1.0, _maxImageDimension / longestSide);
  var image = initialScale < 1
      ? img.copyResize(
          orientedImage,
          width: (orientedImage.width * initialScale).round(),
          height: (orientedImage.height * initialScale).round(),
          interpolation: img.Interpolation.linear,
        )
      : orientedImage;

  var encoded = Uint8List.fromList(img.encodeJpg(image, quality: 78));
  if (encoded.length <= _maxUploadBytes) return encoded;
  for (final quality in [70, 62]) {
    encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    if (encoded.length <= _maxUploadBytes) return encoded;
  }

  for (final maxDimension in [1024, 896, 768, 640]) {
    final scale = math.min(
      1.0,
      maxDimension / math.max(orientedImage.width, orientedImage.height),
    );
    image = img.copyResize(
      orientedImage,
      width: (orientedImage.width * scale).round(),
      height: (orientedImage.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
    for (final quality in [70, 62]) {
      encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      if (encoded.length <= _maxUploadBytes) return encoded;
    }
  }
  return encoded;
}

class SupabaseStorageService {
  SupabaseClient? _client;

  SupabaseClient get _supabase {
    final client = _client;
    if (client != null) return client;

    final url = dotenv.env['SUPABASE_URL']?.trim();
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'กำหนด SUPABASE_URL และ SUPABASE_ANON_KEY ในไฟล์ .env ก่อนอัปโหลดรูป',
      );
    }
    return _client = SupabaseClient(url, anonKey);
  }

  Future<String> uploadReceiptBytes(
    Uint8List imageBytes,
    String billId,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(billId)) {
      throw ArgumentError.value(billId, 'billId', 'Invalid bill ID.');
    }

    final compressedBytes = await compute(_compressReceipt, imageBytes);
    final filePath = '$billId/receipt.jpg';
    final bucket = _supabase.storage.from(_receiptBucket);
    await bucket.uploadBinary(
      filePath,
      compressedBytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return bucket.getPublicUrl(filePath);
  }
}
