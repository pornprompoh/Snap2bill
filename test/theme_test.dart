import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/providers/theme_provider.dart';
import 'package:snap2bill/theme/app_design_system.dart';

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

  group('Global Design System & Responsive Tokens', () {
    test('AppSpacing tokens follow standard scale', () {
      expect(AppSpacing.xxs, 2.0);
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.xxxl, 32.0);
    });

    test('AppRadius tokens follow Material Design 3 rounded corners', () {
      expect(AppRadius.none, 0.0);
      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 20.0);
      expect(AppRadius.full, 999.0);
    });

    test('AppElevation levels provide soft ambient and key lighting shadows', () {
      final shadowsL1 = AppElevation.level1();
      expect(shadowsL1.length, 1);
      expect(shadowsL1.first.blurRadius, 4);

      final shadowsL2 = AppElevation.level2();
      expect(shadowsL2.length, 1);
      expect(shadowsL2.first.blurRadius, 10);

      final shadowsL3 = AppElevation.level3();
      expect(shadowsL3.length, 1);
      expect(shadowsL3.first.blurRadius, 20);
    });

    testWidgets('ResponsiveContainer caps max width on desktop and allows fluid full width on mobile', (WidgetTester tester) async {
      // 1. Mobile viewport test (390x844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              maxWidth: 720,
              child: const SizedBox(
                key: Key('test_child'),
                width: double.infinity,
                child: Text('Mobile Test Content'),
              ),
            ),
          ),
        ),
      );

      final mobileBox = tester.renderObject<RenderBox>(find.byKey(const Key('test_child')));
      expect(mobileBox.size.width, 390.0);

      // 2. Desktop viewport test (1440x900)
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              maxWidth: 720,
              child: const SizedBox(
                key: Key('test_child_desktop'),
                width: double.infinity,
                child: Text('Desktop Test Content'),
              ),
            ),
          ),
        ),
      );

      final desktopBox = tester.renderObject<RenderBox>(find.byKey(const Key('test_child_desktop')));
      expect(desktopBox.size.width, 720.0);
    });

    testWidgets('ResponsiveContext extension returns correct responsive value based on screen width', (WidgetTester tester) async {
      late bool isMob;
      late String responsiveText;

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                isMob = ctx.isMobile;
                responsiveText = ctx.responsive<String>(
                  mobile: 'Phone View',
                  tablet: 'Tablet View',
                  desktop: 'Desktop View',
                );
                return Text(responsiveText);
              },
            ),
          ),
        ),
      );

      expect(isMob, isTrue);
      expect(responsiveText, 'Phone View');
    });
  });
}
