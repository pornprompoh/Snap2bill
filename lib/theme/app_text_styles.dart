import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Itim';

  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static final TextTheme textTheme = TextTheme(
    headlineLarge: headline,
    headlineMedium: headline,
    headlineSmall: title,
    titleLarge: title,
    titleMedium: body.copyWith(fontWeight: FontWeight.w600),
    titleSmall: body.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600),
    bodyLarge: body,
    bodyMedium: body.copyWith(fontSize: 15.5),
    bodySmall: caption,
    labelLarge: body.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600),
    labelMedium: caption.copyWith(fontWeight: FontWeight.w500),
    labelSmall: caption.copyWith(fontSize: 13.5),
  );
}
