import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/utils/settings_keys.dart';

// themeModeProvider lives in providers/theme_provider.dart
// re-exported here so settings_screen.dart has a single import point
export '../../providers/theme_provider.dart' show themeModeProvider, ThemeModeNotifier;

// ── Stream quality ────────────────────────────────────────────
final streamQualityProvider =
    StateNotifierProvider<_StringPrefNotifier, String>(
        (ref) => _StringPrefNotifier(SettingsKeys.streamQuality, '128'));

// ── Download quality ──────────────────────────────────────────
final downloadQualityProvider =
    StateNotifierProvider<_StringPrefNotifier, String>(
        (ref) => _StringPrefNotifier(SettingsKeys.downloadQuality, '320'));

// ── Storage limit (MB) ────────────────────────────────────────
final storageLimitProvider =
    StateNotifierProvider<_IntPrefNotifier, int>(
        (ref) => _IntPrefNotifier(SettingsKeys.storageLimit, 2048));

// ── Wifi-only download ────────────────────────────────────────
final wifiOnlyProvider = StateNotifierProvider<_BoolPrefNotifier, bool>(
    (ref) => _BoolPrefNotifier(SettingsKeys.wifiOnlyDownload, false));

// ── Gapless playback ─────────────────────────────────────────
final gaplessPlaybackProvider = StateNotifierProvider<_BoolPrefNotifier, bool>(
    (ref) => _BoolPrefNotifier(SettingsKeys.gaplessPlayback, false));

// ── Volume normalization ──────────────────────────────────────
final volumeNormalizeProvider = StateNotifierProvider<_BoolPrefNotifier, bool>(
    (ref) => _BoolPrefNotifier(SettingsKeys.volumeNormalize, false));

// ── Mono audio ────────────────────────────────────────────────
final monoAudioProvider = StateNotifierProvider<_BoolPrefNotifier, bool>(
    (ref) => _BoolPrefNotifier(SettingsKeys.monoAudio, false));

// ── Crossfade ─────────────────────────────────────────────────
final crossfadeProvider = StateNotifierProvider<_IntPrefNotifier, int>(
    (ref) => _IntPrefNotifier(SettingsKeys.crossfadeDuration, 0));

// ── Auto-tune crossfade ───────────────────────────────────────
final autoTuneCrossfadeProvider =
    StateNotifierProvider<_BoolPrefNotifier, bool>(
        (ref) => _BoolPrefNotifier(SettingsKeys.crossfadeAutoTune, false));

// ── API base URL ──────────────────────────────────────────────
final apiBaseUrlProvider = StateNotifierProvider<ApiUrlNotifier, String>(
    (ref) => ApiUrlNotifier());

class ApiUrlNotifier extends StateNotifier<String> {
  ApiUrlNotifier()
      : super(
          Hive.box('kaiva_settings')
              .get(SettingsKeys.apiBaseUrl, defaultValue: ApiEndpoints.defaultBaseUrl)
              as String,
        );

  void setUrl(String url) {
    Hive.box('kaiva_settings').put(SettingsKeys.apiBaseUrl, url);
    ApiClient.reinitialize(url);
    state = url;
  }
}

// ── Display name ──────────────────────────────────────────────
final displayNameProvider = StateNotifierProvider<_StringPrefNotifier, String>(
    (ref) => _StringPrefNotifier(SettingsKeys.displayName, 'Lakshya'));

// ── Generic notifiers ─────────────────────────────────────────
class _StringPrefNotifier extends StateNotifier<String> {
  final String _key;
  _StringPrefNotifier(this._key, String defaultValue)
      : super(Hive.box('kaiva_settings').get(_key, defaultValue: defaultValue) as String);

  void set(String v) {
    Hive.box('kaiva_settings').put(_key, v);
    state = v;
  }
}

class _IntPrefNotifier extends StateNotifier<int> {
  final String _key;
  _IntPrefNotifier(this._key, int defaultValue)
      : super(Hive.box('kaiva_settings').get(_key, defaultValue: defaultValue) as int);

  void set(int v) {
    Hive.box('kaiva_settings').put(_key, v);
    state = v;
  }
}

class _BoolPrefNotifier extends StateNotifier<bool> {
  final String _key;
  _BoolPrefNotifier(this._key, bool defaultValue)
      : super(Hive.box('kaiva_settings').get(_key, defaultValue: defaultValue) as bool);

  void set(bool v) {
    Hive.box('kaiva_settings').put(_key, v);
    state = v;
  }
}
