import 'package:flutter/material.dart';

/// Pitch To Picture tokens, from the website (P2P-website/src/app/globals.css).
/// Dark-only: near-black with metallic gold (#D4AF37) as the single accent.
abstract class C {
  static const surface = Color(0xFF0A0A0A);
  static const onSurface = Color(0xFFFAFAFA);
  static const surface2 = Color(0xFF1A1A1A);
  static const onSurface2 = Color(0xFFEDEDED);
  static const surface3 = Color(0xFF262626);
  static const onSurface3 = Color(0xFFCCCCCC);
  static const muted = Color(0xFFB3B3B3);

  static const brand = Color(0xFFD4AF37);
  static const onBrand = Color(0xFF0A0A0A);
  static const brand2 = Color(0xFFF1D382);
  static const brand3 = Color(0xFF3A3218);
  static const onBrand3 = Color(0xFFF1D382);

  static const success = Color(0xFF3E7D59);
  static const warning = Color(0xFFB8860B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF4A6E8C);

  static const border = Color(0xFF333333);
  static const borderStrong = Color(0xFF404040);
  static const divider = Color(0xFF262626);
  static const overlay = Color(0x8C000000);
}

/// Spacing.
abstract class S {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const x2 = 32.0;
  static const x3 = 48.0;
}

/// Corner radius.
abstract class R {
  static const sm = 6.0;
  static const md = 12.0;
  static const lg = 20.0;
}

/// Type scale: Cinzel for headlines (the website's uppercase cinematic titles), Inter for UI.
abstract class T {
  static const hero = TextStyle(fontFamily: 'Cinzel', fontSize: 34, height: 1.15, letterSpacing: -0.5, fontWeight: FontWeight.w700, fontVariations: [FontVariation.weight(700)], color: C.onSurface);
  static const display = TextStyle(fontFamily: 'Cinzel', fontSize: 26, height: 1.2, letterSpacing: -0.3, fontWeight: FontWeight.w700, fontVariations: [FontVariation.weight(700)], color: C.onSurface);
  static const title = TextStyle(fontFamily: 'Inter', fontSize: 20, height: 1.3, fontWeight: FontWeight.w600, fontVariations: [FontVariation.weight(600)], color: C.onSurface);
  static const subtitle = TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.375, fontWeight: FontWeight.w600, fontVariations: [FontVariation.weight(600)], color: C.onSurface);
  static const body = TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5, fontVariations: [FontVariation.weight(400)], color: C.onSurface);
  static const caption = TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, fontVariations: [FontVariation.weight(400)], color: C.onSurface);
  static const label = TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.33, fontWeight: FontWeight.w500, fontVariations: [FontVariation.weight(500)], color: C.onSurface);
}

extension TextStyleX on TextStyle {
  TextStyle get muted => copyWith(color: C.muted);
  TextStyle get gold => copyWith(color: C.brand);
  TextStyle get semi => _w(600);
  TextStyle get medium => _w(500);
  TextStyle get bold => _w(700);
  // Variable fonts: set the weight axis as well as fontWeight.
  TextStyle _w(int w) => copyWith(fontWeight: FontWeight.values[w ~/ 100 - 1], fontVariations: [FontVariation.weight(w.toDouble())]);
  TextStyle col(Color c) => copyWith(color: c);
  TextStyle size(double s) => copyWith(fontSize: s);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: C.brand,
    onPrimary: C.onBrand,
    secondary: C.brand2,
    surface: C.surface,
    onSurface: C.onSurface,
    error: C.error,
    outline: C.border,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.surface,
    fontFamily: 'Inter',
    dividerColor: C.divider,
    dividerTheme: const DividerThemeData(color: C.divider, thickness: 0.5, space: 0.5),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.brand),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.brand, selectionColor: C.brand3, selectionHandleColor: C.brand),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface2,
      modalBackgroundColor: C.surface2,
      showDragHandle: true,
      dragHandleColor: Color(0xFF44444F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: C.surface2),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.brand : C.surface3),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: C.surface2),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: Colors.transparent,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => T.caption.size(11).medium.col(s.contains(WidgetState.selected) ? C.brand : C.muted),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? C.brand : C.muted),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.brand3,
      selectedIconTheme: IconThemeData(color: C.brand),
      unselectedIconTheme: IconThemeData(color: C.muted),
      selectedLabelTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.brand, fontWeight: FontWeight.w500),
      unselectedLabelTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
    ),
  );
}
