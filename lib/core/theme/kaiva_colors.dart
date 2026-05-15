import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  KAIVA — Editorial Noir Palette
//  Source: Stitch design system "Editorial Noir"
//  Aesthetic: minimalism + glassmorphism · deep dark · warm sand accent
// ─────────────────────────────────────────────────────────────

class KaivaColors {
  KaivaColors._();

  // ── Core backgrounds (tonal layering: lighter = higher elevation) ──
  static const Color backgroundPrimary   = Color(0xFF0A0A0A); // true black base
  static const Color backgroundSecondary = Color(0xFF131313); // surface
  static const Color backgroundTertiary  = Color(0xFF1A1A1A); // inputs / cards
  static const Color backgroundElevated  = Color(0xFF1F1F1F); // overlay (modals, dropdowns)

  // Granular tonal scale (from Editorial Noir design tokens)
  static const Color surfaceContainerLowest  = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow     = Color(0xFF1C1B1B);
  static const Color surfaceContainer        = Color(0xFF201F1F);
  static const Color surfaceContainerHigh    = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright           = Color(0xFF3A3939);

  // ── Light mode (kept minimal — Editorial Noir is dark-first) ──
  static const Color surfaceLight        = Color(0xFFFAF7F2);
  static const Color surfaceMidLight     = Color(0xFFF0EAE0);
  static const Color surfaceDeepLight    = Color(0xFFE8DDD0);

  // ── Accent — Warm Sand ────────────────────────────────────────
  static const Color accentPrimary       = Color(0xFFEF9F27); // primary-container
  static const Color accentBright        = Color(0xFFFFBF6F); // primary
  static const Color accentDeep          = Color(0xFFBA7517); // hover / pressed
  static const Color accentDim           = Color(0xFF855400); // inverse-primary
  static const Color accentGlow          = Color(0x33EF9F27); // 20% sand glow

  // ── Secondary accent — Sky (Editorial Noir tertiary) ─────────
  static const Color secondaryAccent     = Color(0xFF8CD4FF);
  static const Color secondaryGlow       = Color(0x338CD4FF);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary         = Color(0xFFE5E2E1); // on-surface
  static const Color textSecondary       = Color(0xFFD7C3AE); // on-surface-variant
  static const Color textMuted           = Color(0xFFA08E7B); // outline (used for muted text)
  static const Color textDisabled        = Color(0xFF524435); // outline-variant
  static const Color textOnAccent        = Color(0xFF462A00); // on-primary (dark on sand)

  // Text (light mode)
  static const Color textPrimaryLight    = Color(0xFF1A120A);
  static const Color textSecondaryLight  = Color(0xFF6A5A45);
  static const Color textMutedLight      = Color(0xFF8A7A6A);

  // ── Borders (low-contrast outlines — white @ 10% per design spec) ──
  static const Color borderSubtle        = Color(0x1AFFFFFF); // white 10% opacity
  static const Color borderDefault       = Color(0x33FFFFFF); // white 20%
  static const Color borderStrong        = Color(0x4DFFFFFF); // white 30%

  // Borders (light mode)
  static const Color borderSubtleLight   = Color(0xFFEDE4D8);
  static const Color borderDefaultLight  = Color(0xFFD4C4A8);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success             = Color(0xFF4CAF7D);
  static const Color error               = Color(0xFFFFB4AB);
  static const Color errorContainer      = Color(0xFF93000A);
  static const Color warning             = Color(0xFFEF9F27);
  static const Color info                = Color(0xFF8CD4FF);

  // ── Player-specific ───────────────────────────────────────────
  static const Color seekBarTrack        = Color(0xFF2A2A2A);
  static const Color seekBarFilled       = Color(0xFFEF9F27);
  static const Color seekBarThumb        = Color(0xFFFFBF6F);
  static const Color miniPlayerBg        = Color(0xCC0A0A0A); // 80% black — glass
  static const Color nowPlayingBg        = Color(0xFF0A0A0A);
  static const Color waveformActive      = Color(0xFFEF9F27);
  static const Color waveformInactive    = Color(0xFF353534);

  // ── Download badge ────────────────────────────────────────────
  static const Color downloadedBadgeBg   = Color(0xFF201F1F);
  static const Color downloadedBadgeFg   = Color(0xFFEF9F27);

  // ── Glass effects (use with BackdropFilter) ───────────────────
  static const Color glassFill           = Color(0xB30A0A0A); // black @ 70%
  static const Color glassStroke         = Color(0x1AFFFFFF); // white @ 10%
}

// ─────────────────────────────────────────────────────────────
//  Editorial Noir spacing & radius scales (8px base)
// ─────────────────────────────────────────────────────────────

class KaivaSpacing {
  KaivaSpacing._();
  static const double xs            = 4;
  static const double base          = 8;
  static const double sm            = 12;
  static const double md            = 24;
  static const double gutter        = 24;
  static const double lg            = 40;
  static const double xl            = 64;
  static const double marginMobile  = 16;
  static const double marginDesktop = 48;
}

class KaivaRadius {
  KaivaRadius._();
  static const double sm      = 4;
  static const double base    = 8;   // standard UI
  static const double md      = 12;
  static const double lg      = 16;  // large containers / artwork
  static const double xl      = 24;
  static const double full    = 9999;
}
