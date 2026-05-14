import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/kaiva_theme.dart';
import 'providers/theme_provider.dart';

class KaivaApp extends ConsumerWidget {
  const KaivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Kaiva',
      debugShowCheckedModeBanner: false,
      theme: kaivaThemeLight(),
      darkTheme: kaivaThemeDark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
