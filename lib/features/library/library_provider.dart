import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/db_song_ext.dart';
import '../../core/models/song.dart';
import '../../core/models/local_playlist.dart' as model;
import '../../core/database/kaiva_database.dart' show LocalPlaylist;

// ── Liked songs ───────────────────────────────────────────────
final likedSongsProvider = StreamProvider<List<Song>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.likedSongsDao.watchLikedSongs().map((rows) => rows.toModels());
});

// ── Local playlists ───────────────────────────────────────────
final localPlaylistsProvider = StreamProvider<List<model.LocalPlaylist>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.playlistsDao.watchAllPlaylists().map(
    (rows) => rows.map(_toModelPlaylist).toList(),
  );
});

model.LocalPlaylist _toModelPlaylist(LocalPlaylist row) => model.LocalPlaylist(
  id: row.id,
  name: row.name,
  description: row.description,
  coverPath: row.coverPath,
  coverUrl: row.coverUrl,
  songCount: row.songCount,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

// ── Playlist songs (for detail screen) ───────────────────────
final localPlaylistSongsProvider =
    StreamProvider.family<List<Song>, String>((ref, playlistId) {
  final db = ref.watch(databaseProvider);
  return db.playlistsDao
      .watchPlaylistSongs(playlistId)
      .map((rows) => rows.toModels());
});

// ── Liked state for a specific song ──────────────────────────
final isSongLikedProvider = StreamProvider.family<bool, String>((ref, songId) {
  final db = ref.watch(databaseProvider);
  return db.likedSongsDao.watchIsLiked(songId);
});

// ── Library filter ────────────────────────────────────────────
enum LibraryFilter { all, liked, playlists }

final libraryFilterProvider =
    StateProvider<LibraryFilter>((ref) => LibraryFilter.all);

// ── Sort mode ─────────────────────────────────────────────────
enum LibrarySortMode { recentlyAdded, alphabetical }

final librarySortProvider =
    StateProvider<LibrarySortMode>((ref) => LibrarySortMode.recentlyAdded);
