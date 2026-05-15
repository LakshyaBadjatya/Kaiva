import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_storage_info/flutter_storage_info.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/db_song_ext.dart';
import '../../core/database/kaiva_database.dart' show SongsCompanion;
import '../../core/models/song.dart';
import '../../core/utils/settings_keys.dart';
import 'package:drift/drift.dart' show Value;

// ── Storage info ─────────────────────────────────────────────
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  try {
    final free = await FlutterStorageInfo.storageFreeSpace;
    final total = await FlutterStorageInfo.storageTotalSpace;
    final db = ref.watch(databaseProvider);
    final downloaded = await db.songsDao.getDownloadedSongs();
    int usedByKaiva = 0;
    for (final s in downloaded) {
      if (s.localPath != null) {
        final file = File(s.localPath!);
        if (await file.exists()) {
          usedByKaiva += await file.length();
        }
      }
    }
    return StorageInfo(
      freeBytes: free,
      totalBytes: total,
      kaivaUsedBytes: usedByKaiva,
    );
  } catch (_) {
    return const StorageInfo(freeBytes: 0, totalBytes: 0, kaivaUsedBytes: 0);
  }
});

class StorageInfo {
  final int freeBytes;
  final int totalBytes;
  final int kaivaUsedBytes;

  const StorageInfo({
    required this.freeBytes,
    required this.totalBytes,
    required this.kaivaUsedBytes,
  });

  String get freeFormatted => _fmt(freeBytes);
  String get kaivaFormatted => _fmt(kaivaUsedBytes);

  static String _fmt(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
}

// ── Downloaded songs ─────────────────────────────────────────
final downloadedSongsProvider = StreamProvider<List<Song>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.songsDao.watchDownloadedSongs().map((rows) => rows.toModels());
});

// ── In-progress task ID → song ID map (shared singleton) ─────
// Keeps track of which flutter_downloader task ID maps to which song ID
// so the completion callback can call markDownloaded on the right song.
final _taskToSongId = <String, String>{};
final _taskToDir = <String, String>{}; // taskId → download directory path

// Global port — created once at app startup so it exists before any
// download callback can fire. Stored here so DownloadManager can listen to it.
final _globalPort = ReceivePort();

/// Must be called in main() before FlutterDownloader.initialize(), so the
/// IsolateNameServer port exists before any callback arrives.
void initDownloadPort() {
  IsolateNameServer.removePortNameMapping('downloader_send_port');
  IsolateNameServer.registerPortWithName(
    _globalPort.sendPort,
    'downloader_send_port',
  );
}

// ── Download manager ─────────────────────────────────────────
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager(ref);
  manager._startListening();
  ref.onDispose(manager._stopListening);
  return manager;
});

class DownloadManager {
  final Ref _ref;

  StreamSubscription? _sub;

  DownloadManager(this._ref);

  // ── IsolateNameServer wiring ─────────────────────────────

  void _startListening() {
    _sub = _globalPort.listen(_onCallback);
  }

  void _stopListening() {
    _sub?.cancel();
  }

  void _onCallback(dynamic data) async {
    if (data is! List || data.length < 3) return;
    final taskId = data[0] as String;
    final rawStatus = data[1] as int;
    // data[2] is progress (int)

    final status = DownloadTaskStatus.fromInt(rawStatus);

    if (status == DownloadTaskStatus.complete) {
      final songId = _taskToSongId[taskId];
      final dir = _taskToDir[taskId];
      if (songId == null || dir == null) return;

      final localPath = '$dir/$songId.mp3';

      final db = _ref.read(databaseProvider);

      // Determine quality from the song record already in DB
      final existing = await db.songsDao.getSongById(songId);
      final quality = existing?.qualityKbps ?? 128;

      await db.songsDao.markDownloaded(songId, localPath, quality);

      _taskToSongId.remove(taskId);
      _taskToDir.remove(taskId);
    } else if (status == DownloadTaskStatus.failed ||
        status == DownloadTaskStatus.canceled) {
      _taskToSongId.remove(taskId);
      _taskToDir.remove(taskId);
    }
  }

  // ── Public API ───────────────────────────────────────────

  Future<void> downloadSong(Song song) async {
    final db = _ref.read(databaseProvider);

    // Persist song record first so markDownloaded can find it later
    await db.songsDao.upsertSong(SongsCompanion(
      id: Value(song.id),
      title: Value(song.title),
      artist: Value(song.artist),
      album: Value(song.album),
      albumId: Value(song.albumId.isEmpty ? null : song.albumId),
      artistId: Value(song.artistId),
      artworkUrl: Value(song.artworkUrl),
      duration: Value(song.durationSeconds),
      language: Value(song.language),
      streamUrl: Value(song.bestStreamUrl),
      hasLyrics: Value(song.hasLyrics),
      isExplicit: Value(song.isExplicit),
      year: Value(song.year),
      qualityKbps: Value(song.qualityKbps),
      cachedAt: Value(DateTime.now()),
    ));

    // Evict oldest download if over storage limit
    final limitMb = Hive.box('kaiva_settings')
        .get(SettingsKeys.storageLimit, defaultValue: 2048) as int;
    final storageInfo = await _ref.read(storageInfoProvider.future);
    if (storageInfo.kaivaUsedBytes > limitMb * 1024 * 1024) {
      await _evictOldestDownload();
    }

    // Resolve download directory
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = '${dir.path}/kaiva_downloads';
    await Directory(downloadDir).create(recursive: true);

    // Pick the best quality URL at or below the user's quality setting
    if (song.streamUrls.isEmpty) {
      debugPrint('DownloadManager: no stream URLs for ${song.id}, aborting');
      return;
    }
    final quality = Hive.box('kaiva_settings')
        .get(SettingsKeys.downloadQuality, defaultValue: '320') as String;
    final sorted = [...song.streamUrls]
      ..sort((a, b) => b.quality.compareTo(a.quality));
    final targetQuality = int.tryParse(quality) ?? 320;
    final best = sorted.firstWhere(
      (s) => s.quality <= targetQuality,
      orElse: () => sorted.last,
    );

    // Update DB with chosen quality before enqueue
    await db.songsDao.updateSong(SongsCompanion(
      id: Value(song.id),
      qualityKbps: Value(best.quality),
    ));

    if (Platform.isAndroid) {
      final taskId = await FlutterDownloader.enqueue(
        url: best.url,
        savedDir: downloadDir,
        fileName: '${song.id}.mp3',
        showNotification: false,
        openFileFromNotification: false,
      );

      if (taskId != null) {
        _taskToSongId[taskId] = song.id;
        _taskToDir[taskId] = downloadDir;
      }
    } else {
      // iOS: flutter_downloader's background isolate is killed by the OS
      // code-signing monitor on sideloaded builds, so download directly
      // with Dio and mark the song downloaded on completion.
      await _downloadWithDio(
        url: best.url,
        songId: song.id,
        downloadDir: downloadDir,
        quality: best.quality,
      );
    }
  }

  Future<void> _downloadWithDio({
    required String url,
    required String songId,
    required String downloadDir,
    required int quality,
  }) async {
    final localPath = '$downloadDir/$songId.mp3';
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 5),
      ));
      await dio.download(url, localPath);
      final db = _ref.read(databaseProvider);
      await db.songsDao.markDownloaded(songId, localPath, quality);
    } catch (e) {
      debugPrint('Dio download failed for $songId: $e');
      final f = File(localPath);
      if (await f.exists()) await f.delete();
    }
  }

  Future<void> deleteDownload(Song song) async {
    final db = _ref.read(databaseProvider);
    if (song.localPath != null) {
      final file = File(song.localPath!);
      if (await file.exists()) await file.delete();
    }
    await db.songsDao.removeDownload(song.id);
  }

  Future<void> _evictOldestDownload() async {
    final db = _ref.read(databaseProvider);
    final downloaded = await db.songsDao.getDownloadedSongs();
    if (downloaded.isEmpty) return;
    final sorted = [...downloaded]
      ..sort((a, b) {
        final aTime = a.downloadedAt ?? DateTime(0);
        final bTime = b.downloadedAt ?? DateTime(0);
        return aTime.compareTo(bTime);
      });
    final oldest = sorted.first;
    if (oldest.localPath != null) {
      final file = File(oldest.localPath!);
      if (await file.exists()) await file.delete();
    }
    await db.songsDao.removeDownload(oldest.id);
  }
}
