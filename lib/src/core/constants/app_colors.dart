import 'package:flutter/material.dart';

/// Cinematic colour palette for Pitch To Picture.
///
/// Mirrors the web app's design tokens: deep cinema black, dark charcoal
/// surfaces and cinematic gold accents.
abstract class AppColors {
  // ─── Backgrounds ──────────────────────────────────────────────────────────
  /// Deep cinema black — primary background.
  static const Color background = Color(0xFF0B0B0B);

  /// Dark charcoal — cards, panels, forms, sheets.
  static const Color surface = Color(0xFF1A1A1A);

  /// Slightly lighter charcoal — elevated surfaces / inputs.
  static const Color surfaceVariant = Color(0xFF242424);

  // ─── Accent ───────────────────────────────────────────────────────────────
  /// Cinematic gold — buttons, highlights, selected states.
  static const Color gold = Color(0xFFD4AF37);

  /// Black text/icon on gold buttons for high contrast.
  static const Color onGold = Color(0xFF000000);

  // ─── Text ─────────────────────────────────────────────────────────────────
  /// Primary text — white.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary supporting text — light grey.
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Muted detail text — darker grey.
  static const Color textMuted = Color(0xFF7A7A7A);

  // ─── Borders / dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFF2A2A2A);

  // ─── Status colours ───────────────────────────────────────────────────────
  static const Color statusReview = Color(0xFFFFA500); // Orange
  static const Color statusApproved = Color(0xFF4CAF50); // Green
  static const Color statusRejected = Color(0xFFF44336); // Red
  static const Color statusSelected = gold; // Cinematic gold
  static const Color statusInfo = Color(0xFF2196F3); // Blue
  static const Color statusPurple = Color(0xFF9C27B0);
  static const Color statusCyan = Color(0xFF00BCD4);
  static const Color statusEmerald = Color(0xFF10B981);
}
