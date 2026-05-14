import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../database/database_provider.dart';
import '../database/kaiva_database.dart' show SongsCompanion;
import '../utils/settings_keys.dart';
import 'firebase_service.dart';
import 'auth_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final svc = SyncService(
    firebase: ref.watch(firebaseServiceProvider),
    ref: ref,
  );
  ref.listen(authStateProvider, (_, next) {
    if (next.valueOrNull != null) {
      svc.onSignIn();
    } else {
      svc.onSignOut();
    }
  });
  ref.onDispose(svc.dispose);
  return svc;
});

class SyncService {
  final FirebaseService firebase;
  final Ref ref;

  StreamSubscription? _likedWatcher;
  StreamSubscription? _settingsWatcher;

  SyncService({required this.firebase, required this.ref});

  // ── Called on sign-in ────────────────────────────────────────
  Future<void> onSignIn() async {
    await _pullSettingsFromCloud();
    await _pullLikedSongsFromCloud();
    _startCloudWatchers();
  }

  void onSignOut() {
    _likedWatcher?.cancel();
    _settingsWatcher?.cancel();
  }

  void dispose() {
    _likedWatcher?.cancel();
    _settingsWatcher?.cancel();
  }

  // ── Settings ─────────────────────────────────────────────────
  Future<void> pushSettingsToCloud() async {
    if (!firebase.isSignedIn) return;
    final box = Hive.box('kaiva_settings');
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      final val = box.get(key);
      if (val != null) data[key.toString()] = val;
    }
    await firebase.pushSettings(data);
  }

  Future<void> _pullSettingsFromCloud() async {
    final remote = await firebase.pullSettings();
    if (remote == null || remote.isEmpty) return;
    final box = Hive.box('kaiva_settings');
    for (final entry in remote.entries) {
      // Don't overwrite apiBaseUrl with cloud value — keep local proxy setting
      if (entry.key == SettingsKeys.apiBaseUrl) continue;
      // Never let cloud data reset onboarding — it should only be set locally once
      if (entry.key == SettingsKeys.onboardingComplete) continue;
      await box.put(entry.key, entry.value);
    }
  }

  void _startCloudWatchers() {
    _settingsWatcher?.cancel();
    _settingsWatcher = firebase.watchSettings().listen((remote) {
      if (remote == null) return;
      final box = Hive.box('kaiva_settings');
      for (final entry in remote.entries) {
        if (entry.key == SettingsKeys.apiBaseUrl) continue;
        if (entry.key == SettingsKeys.onboardingComplete) continue;
        box.put(entry.key, entry.value);
      }
    });

    _likedWatcher?.cancel();
    _likedWatcher = firebase.watchLikedSongs().listen((songs) async {
      // Sync cloud liked songs into local Drift DB
      final db = ref.read(databaseProvider);
      for (final song in songs) {
        final id = song['id'] as String?;
        if (id == null) continue;
        // Upsert song into songs cache
        try {
          await db.songsDao.upsertSong(SongsCompanion(
            id: Value(id),
            title: Value(song['title'] as String? ?? ''),
            artist: Value(song['artist'] as String? ?? ''),
            artistId: Value(song['artistId'] as String? ?? ''),
            album: Value(song['album'] as String? ?? ''),
            albumId: Value(song['albumId'] as String? ?? ''),
            artworkUrl: Value(song['artworkUrl'] as String? ?? ''),
            duration: Value(song['durationSeconds'] as int? ?? 0),
            language: Value(song['language'] as String? ?? ''),
            streamUrl: Value(song['streamUrl'] as String?),
            hasLyrics: Value(song['hasLyrics'] as bool? ?? false),
            isExplicit: Value(song['isExplicit'] as bool? ?? false),
            year: Value(song['year'] as int?),
          ));
          await db.likedSongsDao.likeSong(id);
        } catch (_) {}
      }
    });
  }

  // ── Liked songs ──────────────────────────────────────────────
  Future<void> pushLikedSong(String songId) async {
    if (!firebase.isSignedIn) return;
    final db = ref.read(databaseProvider);
    final song = await db.songsDao.getSongById(songId);
    if (song == null) return;
    await firebase.pushLikedSong({
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'artistId': song.artistId,
      'album': song.album,
      'albumId': song.albumId ?? '',
      'artworkUrl': song.artworkUrl,
      'durationSeconds': song.duration,
      'language': song.language,
      'streamUrl': song.streamUrl,
      'hasLyrics': song.hasLyrics,
      'isExplicit': song.isExplicit,
      'year': song.year,
    });
  }

  Future<void> removeLikedSong(String songId) async {
    if (!firebase.isSignedIn) return;
    await firebase.removeLikedSong(songId);
  }

  Future<void> _pullLikedSongsFromCloud() async {
    final songs = await firebase.fetchLikedSongs();
    final db = ref.read(databaseProvider);
    for (final song in songs) {
      final id = song['id'] as String?;
      if (id == null) continue;
      try {
        await db.songsDao.upsertSong(SongsCompanion(
          id: Value(id),
          title: Value(song['title'] as String? ?? ''),
          artist: Value(song['artist'] as String? ?? ''),
          artistId: Value(song['artistId'] as String? ?? ''),
          album: Value(song['album'] as String? ?? ''),
          albumId: Value(song['albumId'] as String? ?? ''),
          artworkUrl: Value(song['artworkUrl'] as String? ?? ''),
          duration: Value(song['durationSeconds'] as int? ?? 0),
          language: Value(song['language'] as String? ?? ''),
          streamUrl: Value(song['streamUrl'] as String?),
          hasLyrics: Value(song['hasLyrics'] as bool? ?? false),
          isExplicit: Value(song['isExplicit'] as bool? ?? false),
          year: Value(song['year'] as int?),
        ));
        await db.likedSongsDao.likeSong(id);
      } catch (_) {}
    }
  }
}
