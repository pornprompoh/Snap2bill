class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  final List<Map<String, dynamic>> _cachedBills = [];

  Future<void> init() async {}

  Future<void> saveBills(List<Map<String, dynamic>> billsData) async {
    _cachedBills.clear();
    _cachedBills.addAll(billsData.map((bill) => Map<String, dynamic>.from(bill)));
  }

  List<Map<String, dynamic>> getCachedBills() {
    return List.unmodifiable(_cachedBills);
  }

  Future<void> clearCache() async {
    _cachedBills.clear();
  }
}
