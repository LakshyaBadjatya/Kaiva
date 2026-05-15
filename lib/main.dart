import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'app.dart';
import 'core/api/api_client.dart';
import 'core/api/api_endpoints.dart';
import 'core/utils/settings_keys.dart';
import 'core/database/database_provider.dart';
import 'core/database/kaiva_database.dart';
import 'core/firebase/sync_service.dart';
import 'core/recommender/recommender_provider.dart';
import 'core/theme/kaiva_colors.dart';
import 'features/downloads/download_manager.dart';
import 'features/player/audio_handler.dart';
import 'features/player/player_provider.dart';
// Bootstraps sync service on app start so it activates the moment the user signs in
class _AppWithSync extends ConsumerStatefulWidget {
  const _AppWithSync();
  @override
  ConsumerState<_AppWithSync> createState() => _AppWithSyncState();
}

class _AppWithSyncState extends ConsumerState<_AppWithSync> {
  @override
  void initState() {
    super.initState();
    _restoreAudioSettings();
    _wireQueueAutoplay();
  }

  void _restoreAudioSettings() {
    final box = Hive.box('kaiva_settings');
    final handler = ref.read(audioHandlerProvider);
    final crossfade = box.get(SettingsKeys.crossfadeDuration, defaultValue: 0) as int;
    if (crossfade > 0) handler.setCrossfade(crossfade);
    final gapless = box.get(SettingsKeys.gaplessPlayback, defaultValue: false) as bool;
    if (gapless) handler.setGapless(true);
  }

  // When the queue runs out, fetch recommendations and append to autoplay.
  void _wireQueueAutoplay() {
    final handler = ref.read(audioHandlerProvider);
    handler.onQueueExhausted = () async {
      try {
        final profile = await ref.read(tasteProfileProvider.future);
        final rec = ref.read(recommenderProvider);
        return rec.recommend(profile: profile, limit: 15);
      } catch (_) {
        return const [];
      }
    };
  }

  String? _lastSongId;

  @override
  Widget build(BuildContext context) {
    ref.watch(syncServiceProvider);
    ref.watch(downloadManagerProvider);

    // When the currently-playing song changes, invalidate the recommender
    // cache so "For You" re-ranks from the latest events.
    ref.listen(currentSongProvider, (prev, next) {
      final newId = next.valueOrNull?.id;
      if (newId == null || newId == _lastSongId) return;
      _lastSongId = newId;
      ref.invalidate(tasteProfileProvider);
      ref.invalidate(forYouProvider);
    });

    return const KaivaApp();
  }
}

// Top-level download callback — must be static + @pragma for flutter_downloader
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  IsolateNameServer.lookupPortByName('downloader_send_port')
      ?.send([id, status, progress]);
}

// Holds init results until ProviderScope can consume them
class _AppDeps {
  final KaivaAudioHandler audioHandler;
  final KaivaDatabase db;
  const _AppDeps(this.audioHandler, this.db);
}

Future<_AppDeps> _initApp() async {
  // Firebase init
  await Firebase.initializeApp();

  // Hive init
  await Hive.initFlutter();
  await Hive.openBox('kaiva_settings');

  // Always reset API URL to current default — wipes any stale saved URL
  await Hive.box('kaiva_settings').put('api_base_url', ApiEndpoints.defaultBaseUrl);
  ApiClient.reinitialize(ApiEndpoints.defaultBaseUrl);

  // Audio service init
  final audioHandler = await AudioService.init(
    builder: () => KaivaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lakshya.kaiva.channel.audio',
      androidNotificationChannelName: 'Kaiva',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFFEF9F27),
    ),
  );

  // Single DB instance shared across the whole app — avoids Drift multiple-instance warning
  final db = KaivaDatabase();
  audioHandler.setDatabase(db);

  // Proxy routes CDN audio through host machine — only needed on Android emulator,
  // where the emulator can reach the host at 10.0.2.2 but not external CDN directly.
  // Physical devices have direct internet access, so proxy is skipped.
  if (Platform.isAndroid && kDebugMode) {
    // Try a socket connect to 10.0.2.2:8888 — succeeds only on emulator (ADB reverse)
    bool onEmulator = false;
    try {
      final socket = await Socket.connect('10.0.2.2', 8888,
          timeout: const Duration(seconds: 1));
      socket.destroy();
      onEmulator = true;
    } catch (_) {}
    if (onEmulator) KaivaAudioHandler.enableProxy();
  }

  // flutter_downloader init — port must be registered before initialize()
  // so callbacks that fire immediately on cold start don't get dropped.
  initDownloadPort();
  await FlutterDownloader.initialize(debug: kDebugMode);
  await FlutterDownloader.registerCallback(downloadCallback);

  return _AppDeps(audioHandler, db);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all unhandled Flutter framework errors and log them without crashing.
  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  // UI chrome
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const _SplashGate());
}

// Shows Kaiva splash while async init runs, then swaps to the real app
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  late final Future<_AppDeps> _initFuture = _initApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDeps>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final deps = snapshot.data!;
          return ProviderScope(
            overrides: [
              audioHandlerProvider.overrideWithValue(deps.audioHandler),
              databaseProvider.overrideWithValue(deps.db),
            ],
            child: const _AppWithSync(),
          );
        }

        // Show branded splash while initializing
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: KaivaColors.backgroundPrimary,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C6EF0), Color(0xFF5548C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x507C6EF0),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: KaivaColors.textOnAccent,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kaiva',
                    style: TextStyle(
                      color: KaivaColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your music, your world',
                    style: TextStyle(
                      color: KaivaColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  const SizedBox(height: 52),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KaivaColors.accentPrimary,
                    ),
                  ),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Failed to start: ${snapshot.error}',
                      style: const TextStyle(
                        color: KaivaColors.error,
                        fontSize: 12,
                        fontFamily: 'DM Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
