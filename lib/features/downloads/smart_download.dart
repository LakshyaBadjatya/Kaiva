import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/db_song_ext.dart';
import '../../core/models/song.dart';
import '../../core/utils/settings_keys.dart';
import 'download_manager.dart';

/// Result of a smart-download sync pass.
class SmartDownloadResult {
  final int queued;
  final int skipped;
  final String? message;

  const SmartDownloadResult({
    required this.queued,
    required this.skipped,
    this.message,
  });
}

final smartDownloadProvider = Provider<SmartDownloadEngine>((ref) {
  return SmartDownloadEngine(ref);
});

/// Picks the user's liked + most-played songs that aren't downloaded yet
/// and queues them, respecting Wi-Fi-only and a max-songs cap. Driven
/// either by the user ("Sync now"), on app open (catch-up), or by the
/// background scheduler (overnight).
class SmartDownloadEngine {
  SmartDownloadEngine(this._ref);
  final Ref _ref;

  Box get _box => Hive.box('kaiva_settings');

  bool get enabled =>
      _box.get(SettingsKeys.smartDownloadEnabled, defaultValue: false) as bool;
  bool get includeLiked =>
      _box.get(SettingsKeys.smartDownloadLiked, defaultValue: true) as bool;
  bool get includeMostPlayed =>
      _box.get(SettingsKeys.smartDownloadMostPlayed, defaultValue: true)
          as bool;
  bool get wifiOnly =>
      _box.get(SettingsKeys.smartDownloadWifiOnly, defaultValue: true) as bool;
  int get maxSongs =>
      _box.get(SettingsKeys.smartDownloadMaxSongs, defaultValue: 50) as int;

  DateTime? get lastRun {
    final ms = _box.get(SettingsKeys.smartDownloadLastRun);
    if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);
    return null;
  }

  Future<bool> _onWifi() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Runs a sync pass. [force] skips the enabled check (used by "Sync now").
  Future<SmartDownloadResult> sync({bool force = false}) async {
    if (!force && !enabled) {
      return const SmartDownloadResult(
          queued: 0, skipped: 0, message: 'Smart Download is off');
    }

    if (wifiOnly && !await _onWifi()) {
      return const SmartDownloadResult(
          queued: 0, skipped: 0, message: 'Waiting for Wi-Fi');
    }

    final db = _ref.read(databaseProvider);

    // Build the candidate set (already-downloaded excluded).
    final downloaded = await db.songsDao.getDownloadedSongs();
    final downloadedIds = downloaded.map((s) => s.id).toSet();

    final candidates = <String, Song>{};

    if (includeLiked) {
      final liked = await db.likedSongsDao.watchLikedSongs().first;
      for (final row in liked.toModels()) {
        if (!downloadedIds.contains(row.id)) candidates[row.id] = row;
      }
    }

    if (includeMostPlayed) {
      final ids = await db.playEventsDao.topSeedSongs(limit: 60);
      for (final id in ids) {
        if (downloadedIds.contains(id) || candidates.containsKey(id)) {
          continue;
        }
        final dbSong = await db.songsDao.getSongById(id);
        if (dbSong != null) candidates[id] = dbSong.toModel();
      }
    }

    if (candidates.isEmpty) {
      _stampRun();
      return const SmartDownloadResult(
          queued: 0, skipped: 0, message: 'Nothing new to download');
    }

    final manager = _ref.read(downloadManagerProvider);
    final toQueue = candidates.values.take(maxSongs).toList();

    int queued = 0;
    for (final song in toQueue) {
      try {
        await manager.downloadSong(song);
        queued++;
      } catch (e) {
        debugPrint('SmartDownload: failed to queue ${song.id}: $e');
      }
    }

    _stampRun();
    return SmartDownloadResult(
      queued: queued,
      skipped: candidates.length - queued,
      message: queued == 0
          ? 'Nothing queued'
          : 'Queued $queued song${queued == 1 ? '' : 's'}',
    );
  }

  void _stampRun() {
    _box.put(SettingsKeys.smartDownloadLastRun,
        DateTime.now().millisecondsSinceEpoch);
  }
}
