import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_colors.dart';
import 'package:snap2bill/theme/app_design_system.dart';

void main() {
  group('Material Design 3 system', () {
    test('apply() keeps Material 3 and configures component themes', () {
      final t = AppDesignSystem.apply(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
      );
      expect(t.useMaterial3, isTrue);
      expect(t.cardTheme.shape, isNotNull);
      expect(t.dialogTheme.shape, isNotNull);
      expect(t.bottomSheetTheme.showDragHandle, isTrue);
      expect(t.filledButtonTheme.style, isNotNull);
      expect(t.elevatedButtonTheme.style, isNotNull);
    });

    test('Spacing and radius tokens have valid positive values', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.md, 12);
      expect(AppRadius.lg, 16);
      expect(AppTouchTarget.min, 48);
    });
  });
}
