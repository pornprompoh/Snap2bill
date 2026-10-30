import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  static const String _boxName = 'bills_cache';
  static const String _billsKey = 'cached_bills';
  static const String authSessionKey = 'auth_session';
  static const String currentUserProfileKey = 'current_user_profile';
  static const String appSettingsKey = 'app_settings';
  static const String themePreferenceKey = 'theme_preference';

  final List<Map<String, dynamic>> _cachedBills = [];
  Box<dynamic>? _box;

  Future<void> init() async {
    if (_box?.isOpen == true) return;
    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box<dynamic>(_boxName)
        : await Hive.openBox<dynamic>(_boxName);

    final storedBills = _box!.get(_billsKey);
    if (storedBills is List) {
      _cachedBills
        ..clear()
        ..addAll(
          storedBills.whereType<Map>().map(
            (bill) => Map<String, dynamic>.from(bill),
          ),
        );
    }
  }

  Future<void> setValue(String key, Object? value) async {
    await init();
    await _box!.put(key, value);
  }

  T? getValue<T>(String key) {
    final value = _box?.get(key);
    return value is T ? value : null;
  }

  Future<void> saveBills(List<Map<String, dynamic>> billsData) async {
    _cachedBills
      ..clear()
      ..addAll(billsData.map((bill) => Map<String, dynamic>.from(bill)));
    await setValue(_billsKey, _cachedBills);
  }

  List<Map<String, dynamic>> getCachedBills() {
    final storedBills = _box?.get(_billsKey);
    if (storedBills is List && _cachedBills.isEmpty) {
      _cachedBills.addAll(
        storedBills.whereType<Map>().map(
          (bill) => Map<String, dynamic>.from(bill),
        ),
      );
    }
    return List.unmodifiable(_cachedBills);
  }

  Future<void> remove(String key) async {
    await init();
    await _box!.delete(key);
  }

  Future<void> saveAuthSession(Map<String, dynamic> session) =>
      setValue(authSessionKey, session);

  Map<String, dynamic>? getAuthSession() =>
      getValue<Map>(authSessionKey)?.cast<String, dynamic>();

  Future<void> saveCurrentUserProfile(Map<String, dynamic> profile) =>
      setValue(currentUserProfileKey, profile);

  Map<String, dynamic>? getCurrentUserProfile() =>
      getValue<Map>(currentUserProfileKey)?.cast<String, dynamic>();

  Future<void> saveAppSettings(Map<String, dynamic> settings) =>
      setValue(appSettingsKey, settings);

  Map<String, dynamic>? getAppSettings() =>
      getValue<Map>(appSettingsKey)?.cast<String, dynamic>();

  Future<void> saveThemePreference(String preference) =>
      setValue(themePreferenceKey, preference);

  String? getThemePreference() => getValue<String>(themePreferenceKey);

  Future<void> clearCache() async {
    _cachedBills.clear();
    await init();
    await _box!.clear();
  }
}
