import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// App is dark-only. Provider kept so existing ref.watch(themeModeProvider)
// calls in settings don't break, but it always returns dark.
final themeModeProvider = Provider<ThemeMode>((_) => ThemeMode.dark);
