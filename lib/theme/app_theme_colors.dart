import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colors that change with the active app theme.
///
/// Screens should prefer this extension for UI surfaces, text, borders, and
/// status feedback. Brand colors remain in [AppColors].
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color tealText;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color divider;
  final Color onBrand;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color onWarning;
  final Color warningContainer;
  final Color onError;
  final Color errorContainer;

  AppThemeColors({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.tealText,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.divider,
    required this.onBrand,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.onWarning,
    required this.warningContainer,
    required this.onError,
    required this.errorContainer,
  });

  AppThemeColors.light()
    : this(
        textPrimary: AppColors.black,
        textSecondary: AppColors.gray,
        textMuted: Color(0xFF616161),
        tealText: AppColors.tealText,
        surface: AppColors.white,
        surfaceVariant: Color(0xFFF7F7F7),
        border: AppColors.border,
        divider: AppColors.divider,
        onBrand: AppColors.white,
        onSuccess: AppColors.white,
        successContainer: Color(0xFFD8F3ED),
        onSuccessContainer: AppColors.tealText,
        accentContainer: AppColors.lightPink,
        onAccentContainer: AppColors.black,
        onWarning: AppColors.white,
        warningContainer: AppColors.paleYellow,
        onError: AppColors.white,
        errorContainer: Color(0xFFFFE6EE),
      );

  AppThemeColors.dark()
    : this(
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textMuted: Color(0xFFBDBDBD),
        tealText: Color(0xFF8FE0D0),
        surface: AppColors.darkSurface,
        surfaceVariant: AppColors.darkCardBackground,
        border: AppColors.darkBorder,
        divider: Color(0xFF303030),
        onBrand: AppColors.white,
        onSuccess: AppColors.white,
        successContainer: Color(0xFF075C4E),
        onSuccessContainer: AppColors.white,
        accentContainer: Color(0xFF54213D),
        onAccentContainer: AppColors.white,
        onWarning: AppColors.white,
        warningContainer: Color(0xFF5A4210),
        onError: AppColors.white,
        errorContainer: Color(0xFF632B40),
      );

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppThemeColors.dark()
            : AppThemeColors.light());
  }

  @override
  AppThemeColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? tealText,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? divider,
    Color? onBrand,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? onWarning,
    Color? warningContainer,
    Color? onError,
    Color? errorContainer,
  }) {
    return AppThemeColors(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      tealText: tealText ?? this.tealText,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      onBrand: onBrand ?? this.onBrand,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
    );
  }

  @override
  AppThemeColors lerp(covariant AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      tealText: Color.lerp(tealText, other.tealText, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer: Color.lerp(
        onAccentContainer,
        other.onAccentContainer,
        t,
      )!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
    );
  }
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors => AppThemeColors.of(this);
}
