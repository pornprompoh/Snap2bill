import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/bill_model.dart';
import '../services/supabase_db_service.dart';

class BillRepository {
  final AppDatabase _database;
  final SupabaseDbService _supabase;

  BillRepository({AppDatabase? database, SupabaseDbService? supabase})
    : _database = database ?? AppDatabase(),
      _supabase = supabase ?? SupabaseDbService();

  AppDatabase get database => _database;
  AppDatabase get db => _database;

  Future<List<BillModel>> getBills() async {
    final rows = await _database.getAllBills();
    return [
      for (final row in rows)
        BillModel(
          id: row.id,
          ownerId: row.hostId,
          shopName: row.title,
          subTotal: row.totalAmount - row.vat - row.serviceCharge,
          vatAmount: row.vat,
          serviceCharge: row.serviceCharge,
          totalAmount: row.totalAmount,
          finalTotal: row.totalAmount,
          status: row.syncedWithServer ? 'synced' : 'offline',
        ),
    ];
  }

  Future<void> saveOrUpdateBill(
    BillModel bill, {
    Iterable<BillItemModel> items = const [],
    bool syncedWithServer = false,
  }) async {
    final itemRows = <BillItemsCompanion>[];
    final claimRows = <ItemClaimsCompanion>[];
    for (final item in items) {
      itemRows.add(
        BillItemsCompanion.insert(
          id: item.id,
          billId: item.billId,
          name: item.itemName,
          price: item.price,
          quantity: item.quantity,
        ),
      );
      for (final entry in item.userQuantities.entries) {
        claimRows.add(
          ItemClaimsCompanion.insert(
            id: '${item.id}:${entry.key}',
            itemId: item.id,
            userId: entry.key,
            claimedQuantity: entry.value,
            isShared: const Value(false),
          ),
        );
      }
      for (final userId in item.sharedUsers) {
        claimRows.add(
          ItemClaimsCompanion.insert(
            id: '${item.id}:shared:$userId',
            itemId: item.id,
            userId: userId,
            claimedQuantity: 0,
            isShared: const Value(true),
          ),
        );
      }
    }

    await _database.saveBillGraph(
      bill: BillsCompanion.insert(
        id: bill.id,
        title: bill.shopName ?? '',
        totalAmount: bill.finalTotal == 0 ? bill.totalAmount : bill.finalTotal,
        vat: Value(bill.vatAmount),
        serviceCharge: Value(bill.serviceCharge),
        hostId: bill.ownerId,
        createdAt: DateTime.tryParse(bill.receiptDate ?? '') ?? DateTime.now(),
        syncedWithServer: Value(syncedWithServer),
      ),
      items: itemRows,
      claims: claimRows,
    );
  }

  Future<void> syncWithSupabase() async {
    final remoteBills = await _supabase.getMyBills();
    for (final bill in remoteBills) {
      await saveOrUpdateBill(bill, syncedWithServer: true);
    }
  }

  Future<void> cacheSupabaseBills(List<Map<String, dynamic>> rawBills) async {
    final companions = <CachedBillsCompanion>[];
    for (final bill in rawBills) {
      final id = bill['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final receiptJson = bill['receipt_json'];
      final sharersJson = bill['sharers_json'];
      companions.add(
        CachedBillsCompanion(
          id: Value(id),
          shopName: Value(bill['shop_name']?.toString()),
          totalAmount: Value(BillModel.totalFromJson(bill)),
          receiptDate: Value(
            bill['receipt_date']?.toString() ?? bill['created_at']?.toString(),
          ),
          status: Value(bill['status']?.toString() ?? 'completed'),
          receiptJson: Value(
            receiptJson == null
                ? null
                : receiptJson is String
                ? receiptJson
                : jsonEncode(receiptJson),
          ),
          sharersJson: Value(
            sharersJson == null
                ? null
                : sharersJson is String
                ? sharersJson
                : jsonEncode(sharersJson),
          ),
          cachedAt: Value(DateTime.now()),
        ),
      );
    }
    if (companions.isNotEmpty) {
      await _database.cacheBills(companions);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedBills() async {
    final rows = await _database.getAllCachedBills();
    return rows.map((row) {
      dynamic receipt;
      if (row.receiptJson?.isNotEmpty == true) {
        try {
          receipt = jsonDecode(row.receiptJson!);
        } catch (_) {}
      }
      dynamic sharers;
      if (row.sharersJson?.isNotEmpty == true) {
        try {
          sharers = jsonDecode(row.sharersJson!);
        } catch (_) {}
      }
      return <String, dynamic>{
        'id': row.id,
        'shop_name': row.shopName ?? 'ไม่ระบุชื่อร้าน',
        'total_amount': row.totalAmount,
        'final_total': row.totalAmount,
        'created_at': row.receiptDate ?? row.cachedAt.toIso8601String(),
        'status': row.status,
        'receipt_json': receipt,
        'sharers_json': sharers,
        'is_cached': true,
      };
    }).toList();
  }

  Future<int> saveDraft({
    required String shopName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) {
    return _database.insertDraft(
      OfflineDraftsCompanion(
        shopName: Value(shopName),
        totalAmount: Value(totalAmount),
        itemsJson: Value(jsonEncode(items)),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<OfflineDraft>> getDrafts() => _database.getAllDrafts();
  Future<int> deleteDraft(int id) => _database.deleteDraft(id);
  Future<void> dispose() => _database.close();
}
