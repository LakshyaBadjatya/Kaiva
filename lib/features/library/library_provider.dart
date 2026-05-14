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
enum LibraryFilter { all, liked, playlists, artists, albums }

final libraryFilterProvider =
    StateProvider<LibraryFilter>((ref) => LibraryFilter.all);

// ── Sort mode ─────────────────────────────────────────────────
enum LibrarySortMode { recentlyAdded, alphabetical }

final librarySortProvider =
    StateProvider<LibrarySortMode>((ref) => LibrarySortMode.recentlyAdded);

// ── Top artist info model ─────────────────────────────────────
class TopArtistInfo {
  final String artistId;
  final String artistName;
  final String artworkUrl;
  final int totalSeconds;

  const TopArtistInfo({
    required this.artistId,
    required this.artistName,
    required this.artworkUrl,
    required this.totalSeconds,
  });
}

// ── Daily album info model ────────────────────────────────────
class DailyAlbumInfo {
  final String albumId;
  final String albumName;
  final String artworkUrl;
  final int playCount;

  const DailyAlbumInfo({
    required this.albumId,
    required this.albumName,
    required this.artworkUrl,
    required this.playCount,
  });
}

// ── Top artists provider (all-time by seconds played) ─────────
final topArtistsProvider = FutureProvider<List<TopArtistInfo>>((ref) async {
  final db = ref.watch(databaseProvider);
  final topRows = await db.statsDao.getTopArtists(limit: 10);
  if (topRows.isEmpty) return [];

  final result = <TopArtistInfo>[];
  for (final row in topRows) {
    // Find a song by this artist to get name + artwork
    final songs = await db.songsDao.getAllSongs();
    final match = songs.where((s) => s.artistId == row.artistId).toList();
    if (match.isNotEmpty) {
      result.add(TopArtistInfo(
        artistId: row.artistId,
        artistName: match.first.artist,
        artworkUrl: match.first.artworkUrl.replaceAll('150x150', '500x500'),
        totalSeconds: row.totalSeconds,
      ));
    }
  }
  return result;
});

// ── Daily albums provider (played today) ─────────────────────
final dailyAlbumsProvider = FutureProvider<List<DailyAlbumInfo>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.statsDao.getDailyAlbums(limit: 10);
  return rows.map((r) => DailyAlbumInfo(
    albumId: r.albumId,
    albumName: r.album,
    artworkUrl: r.artworkUrl.replaceAll('150x150', '500x500'),
    playCount: r.playCount,
  )).toList();
});
