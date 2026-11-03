import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_theme_colors.dart';
import 'package:snap2bill/widgets/common/mascot_state_view.dart';

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

  test('status and accent containers have readable foreground colors', () {
    final palettes = [AppThemeColors.light(), AppThemeColors.dark()];

    for (final palette in palettes) {
      expect(
        _contrastRatio(palette.onSuccessContainer, palette.successContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(palette.onAccentContainer, palette.accentContainer),
        greaterThanOrEqualTo(4.5),
      );
    }
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

  testWidgets('mascot state text follows the active theme', (tester) async {
    final darkColors = AppThemeColors.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: <ThemeExtension<dynamic>>[darkColors],
        ),
        home: const Scaffold(
          body: MascotStateView(
            state: MascotState.scan,
            message: 'Ready to scan',
            detail: 'Choose a receipt image',
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Ready to scan')).style?.color,
      darkColors.textPrimary,
    );
    expect(
      tester.widget<Text>(find.text('Choose a receipt image')).style?.color,
      darkColors.textMuted,
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final luminances = [
    foreground.computeLuminance(),
    background.computeLuminance(),
  ]..sort();
  return (luminances[1] + 0.05) / (luminances[0] + 0.05);
}
