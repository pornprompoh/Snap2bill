import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

class LocalBillRepository {
  final AppDatabase _db;

  LocalBillRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  AppDatabase get db => _db;

  Future<List<Map<String, dynamic>>> cacheFirebaseBills(
    List<Map<String, dynamic>> rawBills, {
    String? cachedForUserId,
  }) async {
    final companions = <CachedBillsCompanion>[];
    final billsWithImagePaths = <Map<String, dynamic>>[];
    for (final b in rawBills) {
      final id = b['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final existing = await _db.getCachedBill(id);
      final receiptImageUrl =
          b['receipt_image_url']?.toString() ??
          b['image_url']?.toString() ??
          existing?.receiptImageUrl;
      var localImagePath = existing?.localImagePath;
      final receiptImageChanged = existing?.receiptImageUrl != receiptImageUrl;
      if (receiptImageUrl != null &&
          receiptImageUrl.isNotEmpty &&
          !kIsWeb &&
          (receiptImageChanged ||
              localImagePath == null ||
              !await File(localImagePath).exists())) {
        final downloadedImagePath = await _downloadReceiptImage(
          receiptImageUrl,
          id,
        );
        if (downloadedImagePath != null) {
          localImagePath = downloadedImagePath;
        } else if (receiptImageChanged) {
          localImagePath = null;
        }
      }

      final total =
          double.tryParse(b['total_amount']?.toString() ?? '0') ?? 0.0;
      final receiptJsonStr = b['receipt_json'] != null
          ? (b['receipt_json'] is String
                ? b['receipt_json'] as String
                : jsonEncode(b['receipt_json']))
          : null;
      final sharersJsonStr = b['sharers_json'] != null
          ? (b['sharers_json'] is String
                ? b['sharers_json'] as String
                : jsonEncode(b['sharers_json']))
          : null;

      companions.add(
        CachedBillsCompanion(
          id: Value(id),
          shopName: Value(b['shop_name']?.toString()),
          totalAmount: Value(total),
          receiptDate: Value(
            b['receipt_date']?.toString() ?? b['created_at']?.toString(),
          ),
          status: Value(b['status']?.toString() ?? 'completed'),
          receiptJson: Value(receiptJsonStr),
          sharersJson: Value(sharersJsonStr),
          localImagePath: Value(localImagePath),
          localImageBytes: Value(
            receiptImageChanged ? null : existing?.localImageBytes,
          ),
          receiptImageUrl: Value(receiptImageUrl),
          ownerId: Value(
            b['owner_id']?.toString() ??
                b['userId']?.toString() ??
                existing?.ownerId,
          ),
          cachedForUserId: Value(cachedForUserId ?? existing?.cachedForUserId),
          syncedWithServer: const Value(true),
          cachedAt: Value(DateTime.now()),
        ),
      );
      billsWithImagePaths.add({
        ...b,
        'receipt_image_url': receiptImageUrl,
        'receipt_image_local_path': localImagePath,
      });
    }
    if (companions.isNotEmpty) await _db.cacheBills(companions);
    return billsWithImagePaths;
  }

  Future<String?> _downloadReceiptImage(String url, String billId) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
      debugPrint('Skipping invalid receipt image URL for bill $billId');
      return null;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Receipt image cache download failed for bill $billId '
          'with HTTP ${response.statusCode}',
        );
        return null;
      }

      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        bytes.addAll(chunk);
        if (bytes.length > 10 * 1024 * 1024) {
          debugPrint('Receipt image exceeds cache size limit for bill $billId');
          return null;
        }
      }

      final directory = await getApplicationSupportDirectory();
      final cacheDirectory = Directory(p.join(directory.path, 'receipt_cache'));
      await cacheDirectory.create(recursive: true);
      final fileName = '${base64Url.encode(utf8.encode(billId))}.image';
      final imageFile = File(p.join(cacheDirectory.path, fileName));
      await imageFile.writeAsBytes(bytes, flush: true);
      return imageFile.path;
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Receipt image cache failed for bill $billId: $error\n$stackTrace',
      );
      return null;
    } finally {
      client.close(force: true);
    }
  }

  // Get cached bills as Map format matching HomeScreen
  Future<List<Map<String, dynamic>>> getCachedBills() async {
    try {
      final rows = await _db.getAllCachedBills();
      return rows.map((row) {
        dynamic parsedReceipt;
        if (row.receiptJson != null && row.receiptJson!.isNotEmpty) {
          try {
            parsedReceipt = jsonDecode(row.receiptJson!);
          } catch (_) {}
        }
        dynamic parsedSharers;
        if (row.sharersJson != null && row.sharersJson!.isNotEmpty) {
          try {
            parsedSharers = jsonDecode(row.sharersJson!);
          } catch (_) {}
        }

        return <String, dynamic>{
          'id': row.id,
          'shop_name': row.shopName ?? 'ไม่ระบุชื่อร้าน',
          'total_amount': row.totalAmount,
          'created_at': row.receiptDate ?? row.cachedAt.toIso8601String(),
          'status': row.status,
          'receipt_json': parsedReceipt,
          'sharers_json': parsedSharers,
          'receipt_image_url': row.receiptImageUrl,
          'receipt_image_local_path': row.localImagePath,
          'is_cached': true,
        };
      }).toList();
    } catch (e) {
      // Safe fallback if local database throws on web
      return [];
    }
  }

  // Save an offline draft bill
  Future<int> saveDraft({
    required String shopName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) {
    return _db.insertDraft(
      OfflineDraftsCompanion(
        shopName: Value(shopName),
        totalAmount: Value(totalAmount),
        itemsJson: Value(jsonEncode(items)),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<OfflineDraft>> getDrafts() => _db.getAllDrafts();

  Future<int> deleteDraft(int id) => _db.deleteDraft(id);
}
