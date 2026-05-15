import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/kaiva_theme.dart';

class KaivaApp extends ConsumerWidget {
  const KaivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kaiva',
      debugShowCheckedModeBanner: false,
      theme: kaivaThemeDark(),
      darkTheme: kaivaThemeDark(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
