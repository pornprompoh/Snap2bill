import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_design_system.dart';
import 'app_text_styles.dart';
import 'app_theme_colors.dart';

class AppTheme {
  static ThemeData get light => AppDesignSystem.apply(
    ThemeData(
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: _lightColorScheme,
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: AppColors.black,
        displayColor: AppColors.black,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: AppTextStyles.caption,
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      ),
      useMaterial3: true,
      extensions: [AppThemeColors.light()],
    ),
  );

  static ThemeData lightWithDynamicColors(ColorScheme? dynamicColors) =>
      _withDynamicColors(light, dynamicColors);

  static ThemeData darkWithDynamicColors(ColorScheme? dynamicColors) =>
      _withDynamicColors(dark, dynamicColors);

  static ThemeData get dark => AppDesignSystem.apply(
    ThemeData(
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: _darkColorScheme,
      brightness: Brightness.dark,
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
      useMaterial3: true,
      extensions: [AppThemeColors.dark()],
    ),
  );

  static ThemeData _withDynamicColors(
    ThemeData base,
    ColorScheme? dynamicColors,
  ) {
    if (dynamicColors == null) return base;

    final scheme = base.colorScheme.copyWith(
      surface: dynamicColors.surface,
      onSurface: dynamicColors.onSurface,
      onSurfaceVariant: dynamicColors.onSurfaceVariant,
      surfaceTint: dynamicColors.surfaceTint,
      inverseSurface: dynamicColors.inverseSurface,
      onInverseSurface: dynamicColors.onInverseSurface,
      outline: dynamicColors.outline,
      outlineVariant: dynamicColors.outlineVariant,
      surfaceContainerLowest: dynamicColors.surfaceContainerLowest,
      surfaceContainerLow: dynamicColors.surfaceContainerLow,
      surfaceContainer: dynamicColors.surfaceContainer,
      surfaceContainerHigh: dynamicColors.surfaceContainerHigh,
      surfaceContainerHighest: dynamicColors.surfaceContainerHighest,
    );
    final isDark = scheme.brightness == Brightness.dark;
    final colors = isDark ? AppThemeColors.dark() : AppThemeColors.light();
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: scheme.surfaceContainerLow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHigh,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surfaceContainer,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
      ),
      dividerTheme: base.dividerTheme.copyWith(color: scheme.outlineVariant),
      extensions: [
        colors.copyWith(
          textPrimary: scheme.onSurface,
          textSecondary: scheme.onSurfaceVariant,
          textMuted: scheme.onSurfaceVariant,
          surface: scheme.surface,
          surfaceVariant: scheme.surfaceContainerLow,
          border: scheme.outlineVariant,
          divider: scheme.outlineVariant,
        ),
      ],
    );
  }

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        primaryContainer: AppColors.secondary,
        onPrimaryContainer: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        tertiary: AppColors.accent,
        onTertiary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        error: AppColors.error,
        onError: AppColors.surface,
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.secondary,
        onPrimary: AppColors.primaryDark,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.secondary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.primaryDark,
        tertiary: AppColors.accent,
        onTertiary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
        error: AppColors.error,
        onError: Colors.white,
      );
}
