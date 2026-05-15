import 'package:flutter/material.dart';
import 'kaiva_colors.dart';

// ─────────────────────────────────────────────────────────────
//  KAIVA — Editorial Noir Typography
//  Playfair Display (serif) for display/headlines/track titles
//  DM Sans (sans-serif) for body, labels, UI
// ─────────────────────────────────────────────────────────────

class KaivaTextStyles {
  KaivaTextStyles._();

  static const String _serif = 'Playfair Display';
  static const String _sans  = 'DM Sans';

  // ── Display (Playfair Display) ────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 40, // display-lg-mobile per Editorial Noir tokens
    fontWeight: FontWeight.w700,
    color: KaivaColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _serif,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: KaivaColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  // ── Headlines (Playfair Display) ──────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: KaivaColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _serif,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: KaivaColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: KaivaColors.textPrimary,
    height: 1.3,
  );

  // ── Titles transition to Sans for UI density ──────────────────
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: KaivaColors.textPrimary,
  );

  // ── Body (DM Sans) ────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: KaivaColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: KaivaColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: KaivaColors.textMuted,
    height: 1.5,
  );

  // ── Labels (DM Sans, structured "catalog" feel) ───────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: KaivaColors.textPrimary,
    letterSpacing: 0.14,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: KaivaColors.textMuted,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: KaivaColors.textMuted,
    letterSpacing: 0.6,
    height: 1.0,
  );

  // ── Player-specific (editorial moments use Playfair) ──────────
  static const TextStyle songTitle = TextStyle(
    fontFamily: _serif,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: KaivaColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle artistName = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: KaivaColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle durationLabel = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: KaivaColors.textMuted,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle chipLabel = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: KaivaColors.textMuted,
    letterSpacing: 1.2,
  );

  // ── Track row (Playfair title + DM meta) ──────────────────────
  static const TextStyle trackTitle = TextStyle(
    fontFamily: _serif,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: KaivaColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle trackMeta = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: KaivaColors.textMuted,
    height: 1.3,
  );
}
