import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// 📐 Snap2Bill Breakpoints for Responsive Design
/// Supports Smartphone (iOS & Android), Tablet, Laptop, and Desktop / PC
class AppBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 960.0;
  static const double desktop = 1280.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile &&
      MediaQuery.sizeOf(context).width < tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;
}

/// 📏 Snap2Bill Global Spacing System (Material Design 3)
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Standard EdgeInsets presets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets pagePaddingWide = EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(14.0);
  static const EdgeInsets compactCardPadding = EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0);
}

/// 🔘 Snap2Bill Corner Radius Tokens (Material Design 3)
class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static final BorderRadius radiusXs = BorderRadius.circular(xs);
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius radiusFull = BorderRadius.circular(full);
}

/// ☁️ Snap2Bill Elevation & Shadow System (Material Design 3 Ambient & Key Lighting)
class AppElevation {
  static List<BoxShadow> level1({Color? color, bool isDark = false}) => [
        BoxShadow(
          color: (color ?? (isDark ? Colors.black : Colors.black)).withValues(alpha: isDark ? 0.3 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> level2({Color? color, bool isDark = false}) => [
        BoxShadow(
          color: (color ?? (isDark ? Colors.black : Colors.black)).withValues(alpha: isDark ? 0.35 : 0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> level3({Color? color, bool isDark = false}) => [
        BoxShadow(
          color: (color ?? (isDark ? Colors.black : Colors.black)).withValues(alpha: isDark ? 0.4 : 0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

/// 📱💻 Responsive Container for Web & Mobile
/// Centers content and caps max width for comfortable reading on wide Desktop / Laptop screens,
/// while taking full fluid width on Tablets and Smartphones.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 720.0,
    this.padding,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );

    if (scrollable) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return content;
  }
}

/// 🎨 Global Material Design 3 Helper Extensions
extension ResponsiveContext on BuildContext {
  bool get isMobile => AppBreakpoints.isMobile(this);
  bool get isTablet => AppBreakpoints.isTablet(this);
  bool get isDesktop => AppBreakpoints.isDesktop(this);
  bool get isCompact => AppBreakpoints.isCompact(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Adaptive value helper: returns different values based on breakpoint
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// 🧩 Material Design 3 Preset Component Styles
class AppComponentStyles {
  // Primary filled button
  static ButtonStyle primaryButton({Color? backgroundColor, double height = 48}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: Size(64, height),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      textStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Tonal / Secondary button
  static ButtonStyle tonalButton({double height = 44}) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lightPink,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        minimumSize: Size(64, height),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        textStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: null,
      child: const SizedBox(),
    ).style!;
  }

  // Outlined button
  static ButtonStyle outlinedButton({Color? borderColor, double height = 44}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: BorderSide(color: borderColor ?? AppColors.border, width: 1.2),
      minimumSize: Size(64, height),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      textStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

