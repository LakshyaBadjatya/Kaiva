import 'package:flutter/material.dart';

class KaivaColors {
  KaivaColors._();

  // ── Core backgrounds (dark navy / near-black) ──────────────
  static const Color backgroundPrimary   = Color(0xFF0F1117);
  static const Color backgroundSecondary = Color(0xFF1A1D27);
  static const Color backgroundTertiary  = Color(0xFF232736);
  static const Color backgroundElevated  = Color(0xFF2D3348);

  // ── Surface (light mode) ─────────────────────────────────
  static const Color surfaceLight        = Color(0xFFF6F8FD);
  static const Color surfaceMidLight     = Color(0xFFECEFF7);
  static const Color surfaceDeepLight    = Color(0xFFDFE3EF);

  // ── Accent — vivid red ───────────────────────────────────
  static const Color accentPrimary       = Color(0xFFE53935);
  static const Color accentBright        = Color(0xFFFF6F60);
  static const Color accentDeep          = Color(0xFFFF5252);
  static const Color accentDim           = Color(0xFF3A0A09);
  static const Color accentGlow          = Color(0x33E53935);

  // ── Secondary accent — teal ─────────────────────────────
  static const Color secondaryAccent     = Color(0xFF00897B);
  static const Color secondaryGlow       = Color(0x3300897B);

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary         = Color(0xFFF0F2FF);
  static const Color textSecondary       = Color(0xFF9AA5C4);
  static const Color textMuted           = Color(0xFF5A6480);
  static const Color textDisabled        = Color(0xFF2D3348);
  static const Color textOnAccent        = Color(0xFFFFFFFF);

  // Text (light mode)
  static const Color textPrimaryLight    = Color(0xFF0D1020);
  static const Color textSecondaryLight  = Color(0xFF4A5280);
  static const Color textMutedLight      = Color(0xFF7A83A8);

  // ── Borders ───────────────────────────────────────────────
  static const Color borderSubtle        = Color(0xFF1E2230);
  static const Color borderDefault       = Color(0xFF2D3348);
  static const Color borderStrong        = Color(0xFF3D4560);

  // Borders (light mode)
  static const Color borderSubtleLight   = Color(0xFFDDE1EF);
  static const Color borderDefaultLight  = Color(0xFFC4CBE2);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success             = Color(0xFF00897B);
  static const Color error               = Color(0xFFE53935);
  static const Color warning             = Color(0xFFFF8F00);
  static const Color info                = Color(0xFF1E88E5);

  // ── Player-specific ───────────────────────────────────────
  static const Color seekBarTrack        = Color(0xFF2D3348);
  static const Color seekBarFilled       = Color(0xFFE53935);
  static const Color seekBarThumb        = Color(0xFFFF6F60);
  static const Color miniPlayerBg        = Color(0xFF1A1D27);
  static const Color nowPlayingBg        = Color(0xFF0F1117);
  static const Color waveformActive      = Color(0xFFE53935);
  static const Color waveformInactive    = Color(0xFF2D3348);

  // ── Download badge ────────────────────────────────────────
  static const Color downloadedBadgeBg   = Color(0xFF1A1D27);
  static const Color downloadedBadgeFg   = Color(0xFFE53935);
}
