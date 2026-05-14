import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kaiva_colors.dart';
import 'kaiva_text_styles.dart';

ThemeData kaivaThemeDark() {
  const colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary:            KaivaColors.accentPrimary,
    onPrimary:          KaivaColors.textOnAccent,
    primaryContainer:   KaivaColors.accentDim,
    onPrimaryContainer: KaivaColors.accentBright,
    secondary:          KaivaColors.secondaryAccent,
    onSecondary:        KaivaColors.textOnAccent,
    secondaryContainer: Color(0xFF2A1828),
    onSecondaryContainer: KaivaColors.secondaryAccent,
    tertiary:           KaivaColors.textSecondary,
    onTertiary:         KaivaColors.textOnAccent,
    surface:            KaivaColors.backgroundSecondary,
    onSurface:          KaivaColors.textPrimary,
    surfaceContainerHighest: KaivaColors.backgroundTertiary,
    surfaceContainerHigh:    KaivaColors.backgroundElevated,
    surfaceContainer:        KaivaColors.backgroundTertiary,
    surfaceContainerLow:     KaivaColors.backgroundSecondary,
    surfaceContainerLowest:  KaivaColors.backgroundPrimary,
    error:              KaivaColors.error,
    onError:            KaivaColors.textPrimary,
    outline:            KaivaColors.borderDefault,
    outlineVariant:     KaivaColors.borderSubtle,
    inverseSurface:     KaivaColors.surfaceLight,
    onInverseSurface:   KaivaColors.textPrimaryLight,
    inversePrimary:     KaivaColors.accentDeep,
    scrim:              Color(0xCC0B0D12),
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
      backgroundColor: KaivaColors.backgroundPrimary,
      foregroundColor: KaivaColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: KaivaColors.textPrimary,
        letterSpacing: 0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: KaivaColors.backgroundPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: KaivaColors.textSecondary, size: 22),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: KaivaColors.backgroundSecondary,
      selectedItemColor: KaivaColors.accentPrimary,
      unselectedItemColor: KaivaColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w400),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KaivaColors.backgroundSecondary,
      indicatorColor: KaivaColors.accentGlow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: KaivaColors.accentPrimary, size: 22);
        }
        return const IconThemeData(color: KaivaColors.textMuted, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: KaivaColors.accentPrimary);
        }
        return const TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w400, color: KaivaColors.textMuted);
      }),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: KaivaColors.backgroundTertiary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: KaivaColors.borderSubtle, width: 0.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KaivaColors.accentPrimary,
        foregroundColor: KaivaColors.textOnAccent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KaivaColors.accentPrimary,
        side: const BorderSide(color: KaivaColors.accentDeep, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KaivaColors.accentPrimary,
        textStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: KaivaColors.textSecondary,
        highlightColor: KaivaColors.accentGlow,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: KaivaColors.backgroundTertiary,
      selectedColor: KaivaColors.accentDim,
      disabledColor: KaivaColors.backgroundTertiary,
      labelStyle: KaivaTextStyles.chipLabel.copyWith(color: KaivaColors.textSecondary),
      secondaryLabelStyle: KaivaTextStyles.chipLabel.copyWith(color: KaivaColors.accentPrimary),
      side: const BorderSide(color: KaivaColors.borderDefault, width: 0.5),
      selectedShadowColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      showCheckmark: false,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KaivaColors.backgroundTertiary,
      hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: KaivaColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KaivaColors.borderSubtle, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KaivaColors.borderSubtle, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: KaivaColors.accentPrimary,
      inactiveTrackColor: KaivaColors.seekBarTrack,
      thumbColor: KaivaColors.seekBarThumb,
      overlayColor: KaivaColors.accentGlow,
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
    ),

    dividerTheme: const DividerThemeData(
      color: KaivaColors.borderSubtle,
      thickness: 0.5,
      space: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KaivaColors.backgroundElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: KaivaColors.backgroundElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: KaivaTextStyles.headlineMedium,
      contentTextStyle: KaivaTextStyles.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: KaivaColors.backgroundElevated,
      contentTextStyle: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textPrimary),
      actionTextColor: KaivaColors.accentPrimary,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: KaivaColors.borderDefault, width: 0.5),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: KaivaTextStyles.titleMedium,
      subtitleTextStyle: KaivaTextStyles.bodyMedium,
      iconColor: KaivaColors.textMuted,
      minVerticalPadding: 8,
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
      linearMinHeight: 3,
      circularTrackColor: KaivaColors.backgroundTertiary,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: KaivaColors.accentPrimary,
      unselectedLabelColor: KaivaColors.textMuted,
      indicatorColor: KaivaColors.accentPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: KaivaColors.borderSubtle,
      labelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w400),
    ),

    iconTheme: const IconThemeData(color: KaivaColors.textSecondary, size: 22),
    primaryIconTheme: const IconThemeData(color: KaivaColors.accentPrimary, size: 22),

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
    primaryContainer:   Color(0xFFE8E4FF),
    onPrimaryContainer: KaivaColors.accentDim,
    secondary:          KaivaColors.secondaryAccent,
    onSecondary:        KaivaColors.textOnAccent,
    secondaryContainer: Color(0xFFFFE4EA),
    onSecondaryContainer: Color(0xFF8A0020),
    surface:            KaivaColors.surfaceLight,
    onSurface:          KaivaColors.textPrimaryLight,
    surfaceContainerHighest: KaivaColors.surfaceMidLight,
    surfaceContainerHigh:    KaivaColors.surfaceDeepLight,
    surfaceContainer:        KaivaColors.surfaceMidLight,
    surfaceContainerLow:     KaivaColors.surfaceLight,
    surfaceContainerLowest:  Colors.white,
    error:              KaivaColors.error,
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
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: KaivaColors.borderSubtleLight, width: 0.5),
      ),
    ),
  );
}
