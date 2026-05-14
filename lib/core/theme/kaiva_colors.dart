import 'package:flutter/material.dart';

class KaivaColors {
  KaivaColors._();

  // ── Core backgrounds (deep charcoal / near-black) ──────────
  static const Color backgroundPrimary   = Color(0xFF0B0D12);
  static const Color backgroundSecondary = Color(0xFF12151C);
  static const Color backgroundTertiary  = Color(0xFF1A1E28);
  static const Color backgroundElevated  = Color(0xFF222736);

  // ── Surface (light mode) ─────────────────────────────────
  static const Color surfaceLight        = Color(0xFFF6F8FD);
  static const Color surfaceMidLight     = Color(0xFFECEFF7);
  static const Color surfaceDeepLight    = Color(0xFFDFE3EF);

  // ── Accent — electric violet-blue ────────────────────────
  static const Color accentPrimary       = Color(0xFF7C6EF0);
  static const Color accentBright        = Color(0xFFAA9FF5);
  static const Color accentDeep          = Color(0xFF5548C8);
  static const Color accentDim           = Color(0xFF2D2860);
  static const Color accentGlow          = Color(0x337C6EF0);

  // ── Secondary accent — rose/coral ───────────────────────
  static const Color secondaryAccent     = Color(0xFFFF6B8A);
  static const Color secondaryGlow       = Color(0x33FF6B8A);

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary         = Color(0xFFEEF0F8);
  static const Color textSecondary       = Color(0xFF8A92B2);
  static const Color textMuted           = Color(0xFF555E7A);
  static const Color textDisabled        = Color(0xFF2E3348);
  static const Color textOnAccent        = Color(0xFFFFFFFF);

  // Text (light mode)
  static const Color textPrimaryLight    = Color(0xFF0D1020);
  static const Color textSecondaryLight  = Color(0xFF4A5280);
  static const Color textMutedLight      = Color(0xFF7A83A8);

  // ── Borders ───────────────────────────────────────────────
  static const Color borderSubtle        = Color(0xFF1E2232);
  static const Color borderDefault       = Color(0xFF2C3350);
  static const Color borderStrong        = Color(0xFF3D4670);

  // Borders (light mode)
  static const Color borderSubtleLight   = Color(0xFFDDE1EF);
  static const Color borderDefaultLight  = Color(0xFFC4CBE2);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success             = Color(0xFF3DD68C);
  static const Color error               = Color(0xFFFF5C6E);
  static const Color warning             = Color(0xFFFFB347);
  static const Color info                = Color(0xFF4FC3F7);

  // ── Player-specific ───────────────────────────────────────
  static const Color seekBarTrack        = Color(0xFF2C3350);
  static const Color seekBarFilled       = Color(0xFF7C6EF0);
  static const Color seekBarThumb        = Color(0xFFAA9FF5);
  static const Color miniPlayerBg        = Color(0xFF12151C);
  static const Color nowPlayingBg        = Color(0xFF0B0D12);
  static const Color waveformActive      = Color(0xFF7C6EF0);
  static const Color waveformInactive    = Color(0xFF2C3350);

  // ── Download badge ────────────────────────────────────────
  static const Color downloadedBadgeBg   = Color(0xFF1A1E34);
  static const Color downloadedBadgeFg   = Color(0xFF7C6EF0);
}
