import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kaiva_colors.dart';
import 'kaiva_text_styles.dart';

// ─────────────────────────────────────────────────────────────
//  KAIVA — Editorial Noir ThemeData
//  Source: Stitch design system "Editorial Noir"
// ─────────────────────────────────────────────────────────────

ThemeData kaivaThemeDark() {
  const colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,

    primary:            KaivaColors.accentBright, // #ffbf6f
    onPrimary:          KaivaColors.textOnAccent,
    primaryContainer:   KaivaColors.accentPrimary, // #ef9f27
    onPrimaryContainer: Color(0xFF603B00),

    secondary:          Color(0xFFC8C6C5),
    onSecondary:        Color(0xFF313030),
    secondaryContainer: Color(0xFF474746),
    onSecondaryContainer: Color(0xFFB7B5B4),

    tertiary:           KaivaColors.secondaryAccent, // sky
    onTertiary:         Color(0xFF00344A),
    tertiaryContainer:  Color(0xFF37BBF8),
    onTertiaryContainer: Color(0xFF004864),

    surface:            KaivaColors.backgroundSecondary,
    onSurface:          KaivaColors.textPrimary,
    onSurfaceVariant:   KaivaColors.textSecondary,
    surfaceContainerHighest: KaivaColors.surfaceContainerHighest,
    surfaceContainerHigh:    KaivaColors.surfaceContainerHigh,
    surfaceContainer:        KaivaColors.surfaceContainer,
    surfaceContainerLow:     KaivaColors.surfaceContainerLow,
    surfaceContainerLowest:  KaivaColors.surfaceContainerLowest,

    error:              KaivaColors.error,
    onError:            Color(0xFF690005),
    errorContainer:     KaivaColors.errorContainer,
    onErrorContainer:   Color(0xFFFFDAD6),

    outline:            KaivaColors.borderDefault,
    outlineVariant:     KaivaColors.borderSubtle,

    inverseSurface:     KaivaColors.textPrimary,
    onInverseSurface:   Color(0xFF313030),
    inversePrimary:     KaivaColors.accentDim,

    scrim:              Color(0xCC000000),
    shadow:             Colors.black,
    surfaceTint:        Color(0xFFFFB95D),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KaivaColors.backgroundPrimary,

    textTheme: const TextTheme(
      displayLarge:   KaivaTextStyles.displayLarge,
      displayMedium:  KaivaTextStyles.displayMedium,
      displaySmall:   KaivaTextStyles.headlineLarge,
      headlineLarge:  KaivaTextStyles.headlineLarge,
      headlineMedium: KaivaTextStyles.headlineMedium,
      headlineSmall:  KaivaTextStyles.titleLarge,
      titleLarge:     KaivaTextStyles.titleLarge,
      titleMedium:    KaivaTextStyles.titleMedium,
      titleSmall:     KaivaTextStyles.labelLarge,
      bodyLarge:      KaivaTextStyles.bodyLarge,
      bodyMedium:     KaivaTextStyles.bodyMedium,
      bodySmall:      KaivaTextStyles.bodySmall,
      labelLarge:     KaivaTextStyles.labelLarge,
      labelMedium:    KaivaTextStyles.labelMedium,
      labelSmall:     KaivaTextStyles.labelSmall,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: KaivaColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: KaivaColors.textPrimary,
        letterSpacing: -0.2,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: KaivaColors.backgroundPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: KaivaColors.textPrimary, size: 24),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: KaivaColors.glassFill,
      selectedItemColor: KaivaColors.accentPrimary,
      unselectedItemColor: KaivaColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      unselectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w400),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KaivaColors.glassFill,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: KaivaColors.accentPrimary, size: 24);
        }
        return const IconThemeData(color: KaivaColors.textMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: KaivaColors.accentPrimary, letterSpacing: 0.1);
        }
        return const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w400, color: KaivaColors.textMuted);
      }),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: KaivaColors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.lg),
        side: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KaivaColors.accentPrimary,
        foregroundColor: KaivaColors.textOnAccent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KaivaRadius.base)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KaivaColors.textPrimary,
        side: const BorderSide(color: KaivaColors.borderDefault, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KaivaRadius.base)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KaivaColors.accentPrimary,
        textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: KaivaColors.textPrimary,
        highlightColor: KaivaColors.accentGlow,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: KaivaColors.backgroundTertiary,
      selectedColor: KaivaColors.accentPrimary,
      disabledColor: KaivaColors.backgroundTertiary,
      labelStyle: KaivaTextStyles.chipLabel.copyWith(color: KaivaColors.textPrimary),
      secondaryLabelStyle: KaivaTextStyles.chipLabel.copyWith(color: KaivaColors.textOnAccent, fontWeight: FontWeight.w700),
      side: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
      selectedShadowColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KaivaRadius.base)),
      showCheckmark: false,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KaivaColors.backgroundTertiary,
      hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 16, color: KaivaColors.textMuted),
      labelStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: KaivaColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.base),
        borderSide: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.base),
        borderSide: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.base),
        borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.base),
        borderSide: const BorderSide(color: KaivaColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: KaivaColors.accentPrimary,
      inactiveTrackColor: KaivaColors.seekBarTrack,
      thumbColor: KaivaColors.seekBarThumb,
      overlayColor: KaivaColors.accentGlow,
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
    ),

    dividerTheme: const DividerThemeData(
      color: KaivaColors.borderSubtle,
      thickness: 1,
      space: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KaivaColors.backgroundElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(KaivaRadius.xl))),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: KaivaColors.backgroundElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: KaivaTextStyles.headlineMedium,
      contentTextStyle: KaivaTextStyles.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.lg),
        side: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: KaivaColors.backgroundElevated,
      contentTextStyle: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textPrimary),
      actionTextColor: KaivaColors.accentPrimary,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.base),
        side: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      titleTextStyle: KaivaTextStyles.trackTitle,
      subtitleTextStyle: KaivaTextStyles.trackMeta,
      iconColor: KaivaColors.textMuted,
      minVerticalPadding: 12,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return KaivaColors.textOnAccent;
        return KaivaColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return KaivaColors.accentPrimary;
        return KaivaColors.backgroundElevated;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KaivaColors.accentPrimary,
      linearTrackColor: KaivaColors.seekBarTrack,
      linearMinHeight: 4,
      circularTrackColor: KaivaColors.backgroundTertiary,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: KaivaColors.accentPrimary,
      unselectedLabelColor: KaivaColors.textMuted,
      indicatorColor: KaivaColors.accentPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: KaivaColors.borderSubtle,
      labelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.14),
      unselectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w400),
    ),

    iconTheme: const IconThemeData(color: KaivaColors.textPrimary, size: 24),
    primaryIconTheme: const IconThemeData(color: KaivaColors.accentPrimary, size: 24),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    splashColor: KaivaColors.accentGlow,
    highlightColor: Colors.transparent,
    hoverColor: KaivaColors.accentGlow,
    focusColor: KaivaColors.accentGlow,
    disabledColor: KaivaColors.textDisabled,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

ThemeData kaivaThemeLight() {
  const colorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary:            KaivaColors.accentDeep,
    onPrimary:          KaivaColors.surfaceLight,
    primaryContainer:   Color(0xFFFAEEDA),
    onPrimaryContainer: KaivaColors.accentDim,
    secondary:          KaivaColors.accentPrimary,
    onSecondary:        KaivaColors.textOnAccent,
    secondaryContainer: Color(0xFFFAEEDA),
    onSecondaryContainer: KaivaColors.accentDeep,
    surface:            KaivaColors.surfaceLight,
    onSurface:          KaivaColors.textPrimaryLight,
    surfaceContainerHighest: KaivaColors.surfaceMidLight,
    surfaceContainerHigh:    KaivaColors.surfaceDeepLight,
    surfaceContainer:        KaivaColors.surfaceMidLight,
    surfaceContainerLow:     KaivaColors.surfaceLight,
    surfaceContainerLowest:  Colors.white,
    error:              Color(0xFFBA1A1A),
    onError:            Colors.white,
    outline:            KaivaColors.borderDefaultLight,
    outlineVariant:     KaivaColors.borderSubtleLight,
  );

  final darkTheme = kaivaThemeDark();

  return darkTheme.copyWith(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KaivaColors.surfaceLight,
    appBarTheme: darkTheme.appBarTheme.copyWith(
      backgroundColor: KaivaColors.surfaceLight,
      foregroundColor: KaivaColors.textPrimaryLight,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KaivaColors.surfaceLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KaivaRadius.lg),
        side: const BorderSide(color: KaivaColors.borderSubtleLight, width: 1),
      ),
    ),
  );
}
