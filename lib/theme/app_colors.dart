import 'package:flutter/material.dart';

/// 🎨 Snap2Bill Design System Color Palette & Tokens
///
/// Strictly conforms to the requested Design System specification:
/// - Black: #000000 (100%)
/// - White: #FFFFFF (100%)
/// - Gray: #757575 (100%)
/// - Primary Orange: #E37A51 (100%)
/// - Teal Green: #047E69 (100%)
/// - Pink: #F76DB7 (100%)
/// - Light Pink: #FFD5EC (100%)
/// - Black Overlay: #000000 (68% Opacity)
/// - Pale Yellow: #FFF9D4 (100%)
/// - Linear Gradient: Teal Gradient (#047E69 -> #0B9E84)
/// - Dark Overlay: #111010 (28% Opacity)
/// - Light Green: #B6F7C1 (100%)
/// - Yellow: #FFC800 (100%)
/// - White Overlay 24%: #FFFFFF (24% Opacity)
/// - White Overlay 7%: #FFFFFF (7% Opacity)
class AppColors {
  // --- 1. Core Palette Tokens ---
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFF757575);
  static const Color primaryOrange = Color(0xFFE37A51);
  static const Color tealGreen = Color(0xFF047E69);
  static const Color pink = Color(0xFFF76DB7);
  static const Color lightPink = Color(0xFFFFD5EC);
  static const Color paleYellow = Color(0xFFFFF9D4);
  static const Color lightGreen = Color(0xFFB6F7C1);
  static const Color yellow = Color(0xFFFFC800);

  // --- 2. Overlays ---
  /// Black with 68% opacity
  static const Color blackOverlay = Color(0xAD000000);
  /// Dark with 28% opacity (#111010)
  static const Color darkOverlay = Color(0x47111010);
  /// White with 24% opacity
  static const Color whiteOverlay24 = Color(0x3DFFFFFF);
  /// White with 7% opacity
  static const Color whiteOverlay7 = Color(0x12FFFFFF);

  // --- 3. Gradients ---
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF047E69), Color(0xFF0B9E84)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFF76DB7), Color(0xFFE65C9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- 4. Role-based & Semantic Aliases ---
  static const Color primary = pink;                // #F76DB7
  static const Color primaryDark = Color(0xFFD44C93);
  static const Color primaryLight = lightPink;       // #FFD5EC
  static const Color secondary = tealGreen;         // #047E69
  static const Color accent = primaryOrange;        // #E37A51

  // Neutral Background & Surface
  static const Color background = white;             // Clean crisp white
  static const Color surface = white;
  static const Color cardBackground = white;
  static const Color border = Color(0xFFE8E8E8);     // Subtle gray border
  static const Color divider = Color(0xFFEEEEEE);

  // Typography
  static const Color textPrimary = black;            // #000000
  static const Color textSecondary = gray;          // #757575
  static const Color textMuted = gray;              // #757575

  // Status & Semantics
  static const Color success = tealGreen;            // #047E69 (Teal Green)
  static const Color successLight = lightGreen;      // #B6F7C1 (Light Green)
  static const Color warning = primaryOrange;        // #E37A51 (Primary Orange)
  static const Color warningLight = paleYellow;      // #FFF9D4 (Pale Yellow)
  static const Color error = primaryOrange;          // #E37A51
  static const Color errorLight = lightPink;         // #FFD5EC
  static const Color info = tealGreen;
  static const Color infoLight = lightPink;
  static const Color lineGreen = Color(0xFF06C755);  // LINE brand green

  // Backward compatibility aliases
  static const Color blossomPink = lightPink;
  static const Color blushPink = lightPink;
  static const Color warmCream = paleYellow;
  static const Color butterPeach = paleYellow;

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF383838);
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
}
