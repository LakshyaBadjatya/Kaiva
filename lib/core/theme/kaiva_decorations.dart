import 'package:flutter/material.dart';
import 'kaiva_colors.dart';

class KaivaDecorations {
  KaivaDecorations._();

  static BoxDecoration card({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.backgroundTertiary : Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDark ? KaivaColors.borderSubtle : KaivaColors.borderSubtleLight,
      width: 0.5,
    ),
  );

  static BoxDecoration accentPill({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.downloadedBadgeBg : const Color(0xFFFAEEDA),
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: KaivaColors.accentDeep, width: 0.5),
  );

  static BoxDecoration miniPlayer({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.miniPlayerBg : KaivaColors.surfaceMidLight,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isDark ? KaivaColors.borderDefault : KaivaColors.borderDefaultLight,
      width: 0.5,
    ),
  );

  static BoxDecoration nowPlaying({bool isDark = true}) => BoxDecoration(
    color: isDark ? KaivaColors.nowPlayingBg : KaivaColors.surfaceLight,
    borderRadius: BorderRadius.zero,
  );

  static const BoxDecoration albumArtGradientOverlay = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xCC0E0A05)],
      stops: [0.5, 1.0],
    ),
  );

  static BoxDecoration playButtonGlow({bool isDark = true}) => BoxDecoration(
    color: KaivaColors.accentPrimary,
    shape: BoxShape.circle,
    boxShadow: isDark
        ? [const BoxShadow(color: KaivaColors.accentGlow, blurRadius: 20, spreadRadius: 2)]
        : [],
  );
}

extension KaivaThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme   get text   => Theme.of(this).textTheme;
  bool        get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get accentColor   => KaivaColors.accentPrimary;
  Color get surfaceBg     => isDark ? KaivaColors.backgroundSecondary : KaivaColors.surfaceLight;
  Color get cardBg        => isDark ? KaivaColors.backgroundTertiary  : Colors.white;
  Color get primaryText   => isDark ? KaivaColors.textPrimary         : KaivaColors.textPrimaryLight;
  Color get secondaryText => isDark ? KaivaColors.textSecondary       : KaivaColors.textSecondaryLight;
}
