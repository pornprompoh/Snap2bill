// coverage:ignore-file
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  static const String _boxName = 'bills_cache';
  static const String _recentBillsKey = 'recent_bills';

  Box<dynamic>? _box;
  Future<void>? _initialization;

  Future<void> init() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  Box<dynamic> get _initializedBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError(
        'CacheService.init() must be called before using the cache.',
      );
    }
    return box;
  }

  Future<void> saveBills(List<Map<String, dynamic>> billsData) async {
    await _initializedBox.put(
      _recentBillsKey,
      billsData.map((bill) => Map<String, dynamic>.from(bill)).toList(),
    );
  }

  List<Map<String, dynamic>> getCachedBills() {
    final cachedBills = _initializedBox.get(_recentBillsKey);
    if (cachedBills is! Iterable) return [];

    return cachedBills.whereType<Map>().map((bill) {
      final normalizedBill = <String, dynamic>{};
      for (final entry in bill.entries) {
        if (entry.key is String) {
          normalizedBill[entry.key as String] = entry.value;
        }
      }
      return normalizedBill;
    }).toList();
  }

  Future<void> clearCache() async {
    await _initializedBox.clear();
  }
}
