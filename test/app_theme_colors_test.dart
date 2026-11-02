import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_theme_colors.dart';

void main() {
  test('light and dark semantic palettes expose their configured colors', () {
    final light = AppThemeColors.light();
    final dark = AppThemeColors.dark();

    expect(light.textPrimary, isNot(dark.textPrimary));
    expect(light.surface, isNot(dark.surface));
    expect(light.surfaceVariant, isNot(dark.surfaceVariant));
    expect(light.border, isNot(dark.border));
    expect(light.divider, isNot(dark.divider));
    expect(light.successContainer, isNot(dark.successContainer));
    expect(light.warningContainer, isNot(dark.warningContainer));
    expect(light.errorContainer, isNot(dark.errorContainer));
    expect(light.onBrand, dark.onBrand);
  });

  test('copyWith preserves omitted colors and replaces supplied colors', () {
    final original = AppThemeColors.light();
    const replacement = Colors.purple;
    final copied = original.copyWith(
      textPrimary: replacement,
      successContainer: replacement,
      warningContainer: replacement,
      errorContainer: replacement,
    );

    expect(copied.textPrimary, replacement);
    expect(copied.successContainer, replacement);
    expect(copied.warningContainer, replacement);
    expect(copied.errorContainer, replacement);
    expect(copied.textSecondary, original.textSecondary);
    expect(copied.tealText, original.tealText);
    expect(copied.surface, original.surface);
    expect(copied.surfaceVariant, original.surfaceVariant);
    expect(copied.border, original.border);
    expect(copied.divider, original.divider);
    expect(copied.onBrand, original.onBrand);
    expect(copied.onSuccess, original.onSuccess);
    expect(copied.onWarning, original.onWarning);
    expect(copied.onError, original.onError);
  });

  test('lerp interpolates the palette and returns itself for null', () {
    final light = AppThemeColors.light();
    final dark = AppThemeColors.dark();

    expect(light.lerp(null, 0.5), same(light));
    final middle = light.lerp(dark, 0.5);
    expect(
      middle.textPrimary,
      Color.lerp(light.textPrimary, dark.textPrimary, 0.5),
    );
    expect(middle.surface, Color.lerp(light.surface, dark.surface, 0.5));
    expect(
      middle.warningContainer,
      Color.lerp(light.warningContainer, dark.warningContainer, 0.5),
    );
    expect(
      middle.errorContainer,
      Color.lerp(light.errorContainer, dark.errorContainer, 0.5),
    );
  });

  testWidgets(
    'context extension uses registered palette or brightness fallback',
    (tester) async {
      late AppThemeColors registered;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[AppThemeColors.dark()],
          ),
          home: Builder(
            builder: (context) {
              registered = context.appColors;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(registered.textPrimary, AppThemeColors.dark().textPrimary);

      late AppThemeColors fallback;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              fallback = AppThemeColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fallback.textPrimary, AppThemeColors.light().textPrimary);
    },
  );
}
