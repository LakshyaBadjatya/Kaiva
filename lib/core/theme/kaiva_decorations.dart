import 'package:flutter/material.dart';
import 'kaiva_colors.dart';

// ─────────────────────────────────────────────────────────────
//  KAIVA — Editorial Noir Decorations
//  Avoids drop shadows; uses tonal layering, glassmorphism,
//  and low-contrast 1px white@10% outlines.
// ─────────────────────────────────────────────────────────────

class KaivaDecorations {
  KaivaDecorations._();

  // Card: 1px white@10% border, tonal bg, 16px radius
  static BoxDecoration card({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.backgroundSecondary : Colors.white,
    borderRadius: BorderRadius.circular(KaivaRadius.lg),
    border: Border.all(
      color: isDark ? KaivaColors.borderSubtle : KaivaColors.borderSubtleLight,
      width: 1,
    ),
  );

  // Feature card
  static BoxDecoration featureCard({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.backgroundSecondary : Colors.white,
    borderRadius: BorderRadius.circular(KaivaRadius.lg),
    border: Border.all(
      color: isDark ? KaivaColors.borderSubtle : KaivaColors.borderSubtleLight,
      width: 1,
    ),
  );

  // Accent pill (selected chips, primary badges)
  static BoxDecoration accentPill({bool isDark = true}) => BoxDecoration(
    color: KaivaColors.accentPrimary,
    borderRadius: BorderRadius.circular(KaivaRadius.base),
  );

  // Mini player bar (glassmorphism — apply with BackdropFilter blur 20)
  static BoxDecoration miniPlayer({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.glassFill : KaivaColors.surfaceMidLight.withOpacity(0.85),
    borderRadius: BorderRadius.circular(KaivaRadius.lg),
    border: Border.all(
      color: isDark ? KaivaColors.borderSubtle : KaivaColors.borderDefaultLight,
      width: 1,
    ),
  );

  // Glass nav bar (bottom nav / header — apply with BackdropFilter blur 20–32)
  static BoxDecoration glassNav({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.glassFill : KaivaColors.surfaceLight.withOpacity(0.85),
    border: Border(
      top: BorderSide(
        color: isDark ? KaivaColors.borderSubtle : KaivaColors.borderSubtleLight,
        width: 1,
      ),
    ),
  );

  // Now Playing full-screen backdrop
  static BoxDecoration nowPlaying({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.nowPlayingBg : KaivaColors.surfaceLight,
  );

  // Album-art gradient overlay (over hero artwork)
  static const BoxDecoration albumArtGradientOverlay = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xCC0A0A0A)],
      stops: [0.5, 1.0],
    ),
  );

  // Play-button (no shadow per design spec)
  static BoxDecoration playButtonGlow({bool isDark = true}) => const BoxDecoration(
    color: KaivaColors.accentPrimary,
    shape: BoxShape.circle,
  );
}

// Convenience extensions on BuildContext
extension KaivaThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme   get text   => Theme.of(this).textTheme;
  bool        get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get accentColor   => KaivaColors.accentPrimary;
  Color get surfaceBg     => isDark ? KaivaColors.backgroundSecondary : KaivaColors.surfaceLight;
  Color get cardBg        => isDark ? KaivaColors.backgroundSecondary : Colors.white;
  Color get primaryText   => isDark ? KaivaColors.textPrimary         : KaivaColors.textPrimaryLight;
  Color get secondaryText => isDark ? KaivaColors.textSecondary       : KaivaColors.textSecondaryLight;
}
