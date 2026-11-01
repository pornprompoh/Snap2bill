import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central Material Design 3 design system for Snap2Bill.
///
/// Additive layer: it only adds tokens, responsive helpers and component
/// themes on top of the existing [AppColors] / [AppTextStyles]. Change values
/// here to restyle the whole app.

/// Spacing scale (4dp grid).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radius scale (Material 3 shape tokens).
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
}

/// Window size classes (Material 3 breakpoints).
class AppBreakpoints {
  static const double compact = 600; // phones
  static const double medium = 840; // tablets
  static const double expanded = 1200; // laptops / desktop

  /// Max width of the main content column on large screens.
  static const double maxContentWidth = 960;

  /// Minimum touch target (Material guideline).
  static const double minTouchTarget = 48;
}

enum AppWindowSize { compact, medium, expanded }

class Responsive {
  static AppWindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static AppWindowSize fromWidth(double width) {
    if (width < AppBreakpoints.compact) return AppWindowSize.compact;
    if (width < AppBreakpoints.medium) return AppWindowSize.medium;
    return AppWindowSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      of(context) == AppWindowSize.compact;

  /// True when a navigation rail should replace the bottom bar.
  static bool useRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
}

/// Centers app content and limits its width on large screens so layouts
/// never stretch edge-to-edge on desktop/tablet. No-op on phones.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Builds Material 3 component themes on top of an existing [ThemeData].
class AppDesignSystem {
  static ThemeData apply(ThemeData base) {
    final scheme = base.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.cardBackground;

    final roundedLg = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
    const minSize = Size(AppBreakpoints.minTouchTarget, AppBreakpoints.minTouchTarget);

    return base.copyWith(
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: roundedLg,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: minSize,
          shape: roundedLg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: roundedLg,
          side: BorderSide(color: border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minSize),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minSize),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: null,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide(color: border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isDark ? AppColors.darkBorder : AppColors.divider,
        linearMinHeight: 6,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        indicatorColor: scheme.primary,
        dividerColor: border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primaryLight,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
        labelType: NavigationRailLabelType.all,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
    );
  }
}
