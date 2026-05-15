import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/search/search_results_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/album/album_detail_screen.dart';
import '../../features/artist/artist_detail_screen.dart';
import '../../features/playlist/playlist_detail_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/widgets/equalizer_screen.dart';
import '../../features/settings/widgets/crossfade_screen.dart';
import '../../features/settings/widgets/spotify_import_screen.dart';
import '../../features/downloads/smart_download_screen.dart';
import '../../features/wrapped/wrapped_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/mood/mood_mix_screen.dart';
import '../../features/car_mode/car_mode_screen.dart';
import '../../features/identify/identify_screen.dart';
import '../../shared/widgets/kaiva_scaffold.dart';
import '../../core/utils/settings_keys.dart';

String _initialLocation() {
  final box = Hive.box('kaiva_settings');
  final done = box.get(SettingsKeys.onboardingComplete, defaultValue: false) as bool;
  return done ? '/home' : '/onboarding';
}

String? _redirect(BuildContext context, GoRouterState state) {
  final box = Hive.box('kaiva_settings');
  final done = box.get(SettingsKeys.onboardingComplete, defaultValue: false) as bool;
  if (done && state.matchedLocation == '/onboarding') return '/home';
  return null;
}

final appRouter = GoRouter(
  initialLocation: _initialLocation(),
  redirect: _redirect,
  routes: [
    // ── Onboarding (pre-auth gate) ──────────────────────────
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // ── Main shell (4-tab nav) ──────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => KaivaScaffold(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(
            path: '/search/results',
            builder: (_, state) => SearchResultsScreen(
              query: state.uri.queryParameters['q'] ?? '',
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/downloads', builder: (_, __) => const DownloadsScreen()),
        ]),
      ],
    ),

    // ── Full-screen routes ──────────────────────────────────
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) => CustomTransitionPage(
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
        child: const PlayerScreen(),
      ),
    ),

    GoRoute(
      path: '/album/:id',
      builder: (context, state) =>
          AlbumDetailScreen(albumId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/artist/:id',
      builder: (context, state) =>
          ArtistDetailScreen(artistId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/playlist/:id',
      builder: (context, state) =>
          PlaylistDetailScreen(playlistId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/local-playlist/:id',
      builder: (context, state) => PlaylistDetailScreen(
        playlistId: state.pathParameters['id']!,
        isLocal: true,
      ),
    ),

    GoRoute(
      path: '/stats',
      builder: (_, __) => const StatsScreen(),
    ),

    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),

    GoRoute(
      path: '/settings/equalizer',
      builder: (_, __) => const EqualizerScreen(),
    ),

    GoRoute(
      path: '/settings/crossfade',
      builder: (_, __) => const CrossfadeScreen(),
    ),

    GoRoute(
      path: '/settings/smart-download',
      builder: (_, __) => const SmartDownloadScreen(),
    ),

    GoRoute(
      path: '/wrapped',
      pageBuilder: (context, state) => CustomTransitionPage(
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
        child: const WrappedScreen(),
      ),
    ),

    GoRoute(
      path: '/settings/spotify-import',
      builder: (_, __) => const SpotifyImportScreen(),
    ),

    GoRoute(
      path: '/mood-mix',
      builder: (_, __) => const MoodMixScreen(),
    ),

    GoRoute(
      path: '/identify',
      builder: (_, __) => const IdentifyScreen(),
    ),

    GoRoute(
      path: '/car-mode',
      pageBuilder: (context, state) => CustomTransitionPage(
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        child: const CarModeScreen(),
      ),
    ),
  ],
);
