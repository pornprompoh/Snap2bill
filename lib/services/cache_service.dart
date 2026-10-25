import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  static const String _boxName = 'bills_cache';
  static const String authSessionKey = 'auth_session';
  static const String currentUserProfileKey = 'current_user_profile';
  static const String appSettingsKey = 'app_settings';
  static const String themePreferenceKey = 'theme_preference';

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

  Future<void> setValue(String key, Object? value) async {
    await _initializedBox.put(key, value);
  }

  T? getValue<T>(String key) {
    final value = _initializedBox.get(key);
    return value is T ? value : null;
  }

  Future<void> remove(String key) async {
    await _initializedBox.delete(key);
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
    await _initializedBox.clear();
  }
}
