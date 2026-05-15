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
import 'core/firebase/firebase_status.dart';
import 'core/firebase/sync_service.dart';
import 'firebase_options.dart';
import 'core/recommender/recommender_provider.dart';
import 'core/theme/kaiva_colors.dart';
import 'features/downloads/download_manager.dart';
import 'features/downloads/smart_download.dart';
import 'features/downloads/smart_download_scheduler.dart';
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
    _initSmartDownload();
  }

  Future<void> _initSmartDownload() async {
    final box = Hive.box('kaiva_settings');
    final enabled = box.get(SettingsKeys.smartDownloadEnabled,
        defaultValue: false) as bool;
    if (!enabled) return;
    await SmartDownloadScheduler.instance.init();
    final wifi = box.get(SettingsKeys.smartDownloadWifiOnly,
        defaultValue: true) as bool;
    await SmartDownloadScheduler.instance
        .enablePeriodic(wifiOnly: wifi);
    // Catch up if a background wake flagged a pending sync, or just run
    // an opportunistic pass on open.
    if (SmartDownloadScheduler.instance.isSyncDue) {
      SmartDownloadScheduler.instance.clearSyncDue();
    }
    // Fire-and-forget; engine self-guards on Wi-Fi + enabled.
    ref.read(smartDownloadProvider).sync();
  }

  void _restoreAudioSettings() {
    final box = Hive.box('kaiva_settings');
    final handler = ref.read(audioHandlerProvider);
    final crossfade = box.get(SettingsKeys.crossfadeDuration, defaultValue: 0) as int;
    if (crossfade > 0) handler.setCrossfade(crossfade);
    final autoTune =
        box.get(SettingsKeys.crossfadeAutoTune, defaultValue: false) as bool;
    handler.setAutoTuneCrossfade(autoTune);
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
  // Firebase init — MUST NOT crash the app. Uses compiled-in options
  // (firebase_options.dart) so it works without a bundled native plist;
  // the regenerated clean iOS project does not bundle GoogleService-Info.plist.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('Firebase init timed out — running without it');
      return Firebase.app(); // returns default app or throws, caught below
    });
    firebaseReady = true;
  } catch (e, st) {
    firebaseReady = false;
    debugPrint('Firebase init failed (running without it): $e\n$st');
  }

  // Hive init
  try {
    await Hive.initFlutter();
    await Hive.openBox('kaiva_settings');
    // Always reset API URL to current default — wipes any stale saved URL
    await Hive.box('kaiva_settings')
        .put('api_base_url', ApiEndpoints.defaultBaseUrl);
  } catch (e) {
    debugPrint('Hive init failed: $e');
  }
  ApiClient.reinitialize(ApiEndpoints.defaultBaseUrl);

  // Audio service init — full OS-integrated background controls on BOTH
  // platforms. iOS gets the `audio` UIBackgroundMode + AVAudioSession; this
  // is signed correctly by TrollStore (which grants the entitlement), so the
  // earlier sideload SIGABRT no longer applies. try/catch kept as a safety net.
  late final KaivaAudioHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => KaivaAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.lakshya.kaiva.channel.audio',
        androidNotificationChannelName: 'Kaiva',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFFEF9F27),
      ),
    );
  } catch (e) {
    debugPrint('AudioService.init failed, using bare handler: $e');
    audioHandler = KaivaAudioHandler();
  }

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

  // flutter_downloader init — ANDROID ONLY. On iOS its background isolate
  // executes a code page that fails the OS code-signing monitor on a
  // sideloaded/ad-hoc-signed build, which SIGKILLs the whole app at launch
  // (EXC_BAD_ACCESS, CODESIGNING "Invalid Page"). iOS downloads go through
  // a plain Dio request instead (see DownloadManager).
  if (Platform.isAndroid) {
    try {
      initDownloadPort();
      await FlutterDownloader.initialize(debug: kDebugMode);
      await FlutterDownloader.registerCallback(downloadCallback);
    } catch (e) {
      debugPrint('flutter_downloader init failed: $e');
    }
  }

  return _AppDeps(audioHandler, db);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

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
  late final Future<_AppDeps> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

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

        // Branded splash while initializing
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: KaivaColors.backgroundPrimary,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Actual Kaiva logo
                  Image.asset(
                    'assets/images/kaiva_logo.png',
                    width: 110,
                    height: 110,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: KaivaColors.accentPrimary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: KaivaColors.textOnAccent,
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'KAIVA',
                    style: TextStyle(
                      color: KaivaColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your music, your world',
                    style: TextStyle(
                      color: KaivaColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  const SizedBox(height: 56),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Failed to start: ${snapshot.error}',
                        style: const TextStyle(
                          color: KaivaColors.error,
                          fontSize: 12,
                          fontFamily: 'DM Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
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
