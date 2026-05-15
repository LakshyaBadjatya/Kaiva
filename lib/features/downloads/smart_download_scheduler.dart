import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/utils/settings_keys.dart';

const _taskName = 'kaiva.smartDownload.nightly';
const _uniqueName = 'kaiva-smart-download-periodic';

/// Background entrypoint. WorkManager runs this in a separate isolate, so
/// it cannot touch Riverpod or the live UI. It records that a sync is due;
/// the heavy lifting (actual downloads) happens on next app open via
/// [SmartDownloadScheduler.runCatchUpIfDue]. This is deliberate: reliable
/// scheduled background *downloads* are not guaranteed on iOS, and on
/// Android the WorkManager isolate lacks the app's DI graph. Flagging +
/// catch-up is the dependable pattern across both platforms.
@pragma('vm:entry-point')
void smartDownloadCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      if (!Hive.isBoxOpen('kaiva_settings')) {
        await Hive.openBox('kaiva_settings');
      }
      final box = Hive.box('kaiva_settings');
      final enabled = box.get(SettingsKeys.smartDownloadEnabled,
          defaultValue: false) as bool;
      if (enabled) {
        box.put('smart_download_sync_due', true);
      }
      return true;
    } catch (e) {
      debugPrint('SmartDownload bg task failed: $e');
      return false;
    }
  });
}

class SmartDownloadScheduler {
  SmartDownloadScheduler._();
  static final instance = SmartDownloadScheduler._();

  bool _initialised = false;

  /// Call once at app start (Android + iOS). Safe to call repeatedly.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      await Workmanager().initialize(
        smartDownloadCallbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    } catch (e) {
      debugPrint('Workmanager init failed: $e');
    }
  }

  /// Registers (or refreshes) the ~daily background wake. Constraints:
  /// only when the device is idle/charging-friendly; Wi-Fi enforcement
  /// happens in the engine itself so the constraint here stays loose
  /// enough that iOS actually schedules it.
  Future<void> enablePeriodic({required bool wifiOnly}) async {
    try {
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: const Duration(hours: 12),
        constraints: Constraints(
          networkType:
              wifiOnly ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: const Duration(hours: 1),
      );
    } catch (e) {
      debugPrint('Workmanager register failed: $e');
    }
  }

  Future<void> disablePeriodic() async {
    try {
      await Workmanager().cancelByUniqueName(_uniqueName);
    } catch (e) {
      debugPrint('Workmanager cancel failed: $e');
    }
  }

  /// True if a background wake flagged that a sync is owed.
  bool get isSyncDue {
    final box = Hive.box('kaiva_settings');
    return box.get('smart_download_sync_due', defaultValue: false) as bool;
  }

  void clearSyncDue() {
    Hive.box('kaiva_settings').put('smart_download_sync_due', false);
  }
}
