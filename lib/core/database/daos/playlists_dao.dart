import 'package:drift/drift.dart';
import '../kaiva_database.dart';
import '../tables/playlists_table.dart';
import '../tables/playlist_songs_table.dart';
import '../tables/songs_table.dart';

part 'playlists_dao.g.dart';

@DriftAccessor(tables: [LocalPlaylists, PlaylistSongs, Songs])
class PlaylistsDao extends DatabaseAccessor<KaivaDatabase> with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  Stream<List<LocalPlaylist>> watchAllPlaylists() =>
      (select(localPlaylists)..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();

  Future<LocalPlaylist?> getPlaylistById(String id) =>
      (select(localPlaylists)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<String> createPlaylist(LocalPlaylistsCompanion playlist) async {
    await into(localPlaylists).insert(playlist);
    return playlist.id.value;
  }

  Future<void> updatePlaylist(LocalPlaylistsCompanion playlist) =>
      (update(localPlaylists)..where((p) => p.id.equals(playlist.id.value))).write(playlist);

  Future<void> deletePlaylist(String id) async {
    await (delete(playlistSongs)..where((ps) => ps.playlistId.equals(id))).go();
    await (delete(localPlaylists)..where((p) => p.id.equals(id))).go();
  }

  Stream<List<Song>> watchPlaylistSongs(String playlistId) {
    final query = select(playlistSongs).join([
      innerJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
    ])
      ..where(playlistSongs.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistSongs.position)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(songs)).toList());
  }

  Future<void> addSongToPlaylist(String playlistId, String songId, int position) async {
    await into(playlistSongs).insertOnConflictUpdate(PlaylistSongsCompanion(
      playlistId: Value(playlistId),
      songId: Value(songId),
      position: Value(position),
      addedAt: Value(DateTime.now()),
    ));
    await _updateSongCount(playlistId);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await (delete(playlistSongs)
      ..where((ps) => ps.playlistId.equals(playlistId) & ps.songId.equals(songId)))
        .go();
    await _updateSongCount(playlistId);
  }

  Future<void> reorderSong(String playlistId, String songId, int newPosition) =>
      (update(playlistSongs)
        ..where((ps) => ps.playlistId.equals(playlistId) & ps.songId.equals(songId)))
          .write(PlaylistSongsCompanion(position: Value(newPosition)));

  Future<void> _updateSongCount(String playlistId) async {
    final count = await (selectOnly(playlistSongs)
      ..addColumns([playlistSongs.songId.count()])
      ..where(playlistSongs.playlistId.equals(playlistId)))
        .getSingle();
    final c = count.read(playlistSongs.songId.count()) ?? 0;
    await (update(localPlaylists)..where((p) => p.id.equals(playlistId)))
        .write(LocalPlaylistsCompanion(
          songCount: Value(c),
          updatedAt: Value(DateTime.now()),
        ));
  }
}
