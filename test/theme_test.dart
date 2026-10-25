import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/providers/theme_provider.dart';

void main() {
  test('ThemeProvider toggles between light and dark modes', () {
    final provider = ThemeProvider();
    expect(provider.themeMode, ThemeMode.light);
    expect(provider.isDarkMode, isFalse);

    provider.toggleTheme();
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.isDarkMode, isTrue);

    provider.toggleTheme();
    expect(provider.themeMode, ThemeMode.light);
    expect(provider.isDarkMode, isFalse);

    provider.setThemeMode(ThemeMode.dark);
    expect(provider.isDarkMode, isTrue);
  });
}
