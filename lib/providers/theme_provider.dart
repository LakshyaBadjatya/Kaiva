import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/utils/settings_keys.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadThemeMode());

  static ThemeMode _loadThemeMode() {
    final box = Hive.box('kaiva_settings');
    final stored = box.get(SettingsKeys.themeMode, defaultValue: 'system') as String;
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
  }

  void setMode(ThemeMode mode) => setThemeMode(mode);

  void setThemeMode(ThemeMode mode) {
    final box = Hive.box('kaiva_settings');
    final value = switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
    };
    box.put(SettingsKeys.themeMode, value);
    state = mode;
  }
}
