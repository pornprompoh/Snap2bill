import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle headline = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  static final TextTheme textTheme = TextTheme(
    headlineLarge: headline,
    headlineMedium: headline,
    headlineSmall: title,
    titleLarge: title,
    titleMedium: body.copyWith(fontWeight: FontWeight.w600),
    titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: body,
    bodyMedium: body.copyWith(fontSize: 14),
    bodySmall: caption,
    labelLarge: body.copyWith(fontWeight: FontWeight.w600),
    labelMedium: caption.copyWith(fontWeight: FontWeight.w500),
    labelSmall: caption.copyWith(fontSize: 11),
  );
}
