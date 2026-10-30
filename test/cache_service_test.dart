import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snap2bill/services/cache_service.dart';

void main() {
  final cache = CacheService.instance;

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('snap2bill_hive');
    Hive.init(directory.path);
    await cache.init();
    await cache.clearCache();
  });

  setUp(() async {
    await cache.clearCache();
  });

  test('stores and reads auth session, profile, settings, and theme', () async {
    await cache.saveAuthSession({'access_token': 'token'});
    await cache.saveCurrentUserProfile({'id': 'user-1'});
    await cache.saveAppSettings({'notifications': true});
    await cache.saveThemePreference('dark');

    expect(cache.getAuthSession(), {'access_token': 'token'});
    expect(cache.getCurrentUserProfile(), {'id': 'user-1'});
    expect(cache.getAppSettings(), {'notifications': true});
    expect(cache.getThemePreference(), 'dark');
  });

  test('supports generic values and removes individual keys', () async {
    await cache.setValue('counter', 2);
    expect(cache.getValue<int>('counter'), 2);
    expect(cache.getValue<String>('counter'), isNull);

    await cache.remove('counter');
    expect(cache.getValue<int>('counter'), isNull);
  });

  test('clearCache removes all values', () async {
    await cache.saveThemePreference('light');
    await cache.clearCache();
    expect(cache.getThemePreference(), isNull);
  });
}
