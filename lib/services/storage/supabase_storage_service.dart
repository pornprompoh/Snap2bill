import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int _maxImageDimension = 1280;
const int _maxUploadBytes = 500 * 1024;

Uint8List _compressImage(Uint8List sourceBytes) {
  final decodedImage = img.decodeImage(sourceBytes);
  if (decodedImage == null) {
    throw const FormatException('ไม่สามารถอ่านรูปภาพได้');
  }

  final orientedImage = img.bakeOrientation(decodedImage);
  final longestSide = math.max(orientedImage.width, orientedImage.height);
  final initialScale = math.min(1.0, _maxImageDimension / longestSide);
  final initialImage = initialScale < 1
      ? img.copyResize(
          orientedImage,
          width: (orientedImage.width * initialScale).round(),
          height: (orientedImage.height * initialScale).round(),
          interpolation: img.Interpolation.linear,
        )
      : orientedImage;

  var image = initialImage;
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
    encoded = Uint8List.fromList(img.encodeJpg(image, quality: 70));
    if (encoded.length <= _maxUploadBytes) return encoded;
    encoded = Uint8List.fromList(img.encodeJpg(image, quality: 62));
    if (encoded.length <= _maxUploadBytes) return encoded;
  }

  return encoded;
}

class SupabaseStorageService {
  SupabaseStorageService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<String> uploadReceiptXFile(XFile imageFile, String lobbyId) async {
    return uploadReceiptBytes(await imageFile.readAsBytes(), lobbyId);
  }

  Future<Uint8List> compressImageBytes(Uint8List imageBytes) {
    return compute(_compressImage, imageBytes);
  }

  Future<String> uploadReceiptBytes(
    Uint8List imageBytes,
    String lobbyId, {
    String? fileName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');
      final resolvedFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      bool isInvalidPathSegment(String value) =>
          value.isEmpty ||
          value == '.' ||
          value == '..' ||
          value.contains('/') ||
          value.contains('\\');
      if (isInvalidPathSegment(lobbyId) ||
          isInvalidPathSegment(resolvedFileName)) {
        throw ArgumentError('เส้นทางไฟล์ใบเสร็จไม่ถูกต้อง');
      }

      final compressedBytes = await compressImageBytes(imageBytes);
      final filePath = '$userId/$lobbyId/$resolvedFileName';

      await _supabase.storage
          .from('receipts')
          .uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return _supabase.storage.from('receipts').getPublicUrl(filePath);
    } catch (error) {
      debugPrint('เกิดข้อผิดพลาดในการบีบอัด/อัปโหลดรูปภาพ: $error');
      rethrow;
    }
  }

  Future<String> resolveReceiptImageUrl(String imageUrl) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('URL รูปใบเสร็จไม่ถูกต้อง', imageUrl);
    }

    final segments = uri.pathSegments;
    final objectIndex = segments.indexOf('object');
    if (objectIndex < 0 ||
        segments.length <= objectIndex + 3 ||
        !{
          'public',
          'sign',
          'authenticated',
        }.contains(segments[objectIndex + 1]) ||
        segments[objectIndex + 2] != 'receipts') {
      return imageUrl;
    }

    final objectPath = segments.skip(objectIndex + 3).join('/');
    if (objectPath.isEmpty) {
      throw FormatException('ไม่พบตำแหน่งไฟล์ใบเสร็จ', imageUrl);
    }

    return _supabase.storage
        .from('receipts')
        .createSignedUrl(objectPath, 60 * 60);
  }
}
