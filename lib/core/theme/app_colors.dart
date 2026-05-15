import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ───────────────────────────────────────────────
  static const Color background     = Color(0xFF07070F);
  static const Color surface        = Color(0xFF0D0D1A);
  static const Color surfaceUp      = Color(0xFF131328);
  static const Color surfaceHigh    = Color(0xFF1A1A35);

  // ── Borders ───────────────────────────────────────────────────
  static const Color border         = Color(0xFF1E1E3A);
  static const Color borderBright   = Color(0xFF2D2D5E);

  // ── Primary (Indigo) ──────────────────────────────────────────
  static const Color primary        = Color(0xFF6366F1);
  static const Color primaryLight   = Color(0xFF818CF8);
  static const Color primaryDark    = Color(0xFF4F46E5);

  // ── Accent palette ────────────────────────────────────────────
  static const Color cyan           = Color(0xFF06B6D4);
  static const Color cyanLight      = Color(0xFF67E8F9);
  static const Color purple         = Color(0xFF8B5CF6);
  static const Color purpleLight    = Color(0xFFA78BFA);
  static const Color pink           = Color(0xFFEC4899);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color successLight   = Color(0xFF34D399);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFBBF24);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorLight     = Color(0xFFF87171);

  // ── XP / Gamification ─────────────────────────────────────────
  static const Color xpGold         = Color(0xFFF59E0B);
  static const Color xpGoldGlow     = Color(0xFFFF8C00);
  static const Color streakOrange   = Color(0xFFF97316);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF8FAFC);
  static const Color textSecondary  = Color(0xFF94A3B8);
  static const Color textMuted      = Color(0xFF475569);

  // ── Glow helpers (with opacity) ───────────────────────────────
  static Color primaryGlow(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color cyanGlow(double opacity) =>
      cyan.withValues(alpha: opacity);
  static Color purpleGlow(double opacity) =>
      purple.withValues(alpha: opacity);
  static Color successGlow(double opacity) =>
      success.withValues(alpha: opacity);
  static Color warningGlow(double opacity) =>
      warning.withValues(alpha: opacity);
  static Color errorGlow(double opacity) =>
      error.withValues(alpha: opacity);

  // ── Standard glass card decoration ───────────────────────────
  static BoxDecoration glassCard({
    double radius = 20,
    Color? glowColor,
    double glowOpacity = 0.15,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF1E1E3A)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: glowOpacity),
            blurRadius: 32,
            spreadRadius: -4,
          ),
      ],
    );
  }
}