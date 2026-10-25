import 'dart:convert';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

class LocalBillRepository {
  final AppDatabase _db;

  LocalBillRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  AppDatabase get db => _db;

  // Cache multiple bills from Supabase
  Future<void> cacheSupabaseBills(List<Map<String, dynamic>> rawBills) async {
    final companions = <CachedBillsCompanion>[];
    for (final b in rawBills) {
      final id = b['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final total = double.tryParse(b['total_amount']?.toString() ?? '0') ?? 0.0;
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
          receiptDate: Value(b['receipt_date']?.toString() ?? b['created_at']?.toString()),
          status: Value(b['status']?.toString() ?? 'completed'),
          receiptJson: Value(receiptJsonStr),
          sharersJson: Value(sharersJsonStr),
          cachedAt: Value(DateTime.now()),
        ),
      );
    }
    try {
      if (companions.isNotEmpty) {
        await _db.cacheBills(companions);
      }
    } catch (e) {
      // Safe fallback if local DB is unavailable
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
