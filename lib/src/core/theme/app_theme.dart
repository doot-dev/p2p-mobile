import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Cinematic dark theme for Pitch To Picture.
///
/// Headlines use Playfair Display (elegant, film-poster feel); body text uses
/// Inter for clean readability. Cinematic gold is the single accent colour.
abstract class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    const colorScheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      secondary: AppColors.gold,
      onSecondary: AppColors.onGold,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      error: AppColors.statusRejected,
      onError: AppColors.textPrimary,
      outline: AppColors.border,
    );

    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryColor: AppColors.gold,
      dividerColor: AppColors.border,
      splashColor: AppColors.gold.withValues(alpha: 0.08),
      highlightColor: AppColors.gold.withValues(alpha: 0.06),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.statusRejected),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceVariant,
        side: const BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    final body = GoogleFonts.interTextTheme(base);
    final display = GoogleFonts.playfairDisplayTextTheme(base);
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: AppColors.textPrimary),
      displayMedium:
          display.displayMedium?.copyWith(color: AppColors.textPrimary),
      displaySmall: display.displaySmall?.copyWith(color: AppColors.textPrimary),
      headlineLarge: display.headlineLarge
          ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium
          ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      headlineSmall: display.headlineSmall
          ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleLarge: display.titleLarge
          ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.textSecondary),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.textMuted),
      labelLarge: body.labelLarge?.copyWith(color: AppColors.textPrimary),
    );
  }
}
