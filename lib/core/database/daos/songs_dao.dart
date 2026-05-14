import 'package:drift/drift.dart';
import '../kaiva_database.dart';
import '../tables/songs_table.dart';

part 'songs_dao.g.dart';

@DriftAccessor(tables: [Songs])
class SongsDao extends DatabaseAccessor<KaivaDatabase> with _$SongsDaoMixin {
  SongsDao(super.db);

  Future<List<Song>> getAllSongs() => select(songs).get();

  Stream<List<Song>> watchAllSongs() => select(songs).watch();

  Future<Song?> getSongById(String id) =>
      (select(songs)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<List<Song>> getDownloadedSongs() =>
      (select(songs)..where((s) => s.isDownloaded.equals(true))).get();

  Stream<List<Song>> watchDownloadedSongs() =>
      (select(songs)..where((s) => s.isDownloaded.equals(true))).watch();

  Future<void> upsertSong(SongsCompanion song) =>
      into(songs).insertOnConflictUpdate(song);

  Future<void> updateSong(SongsCompanion song) =>
      (update(songs)..where((s) => s.id.equals(song.id.value))).write(song);

  Future<void> markDownloaded(String id, String localPath, int qualityKbps) =>
      (update(songs)..where((s) => s.id.equals(id))).write(SongsCompanion(
        isDownloaded: const Value(true),
        localPath: Value(localPath),
        qualityKbps: Value(qualityKbps),
        downloadedAt: Value(DateTime.now()),
      ));

  Future<void> removeDownload(String id) =>
      (update(songs)..where((s) => s.id.equals(id))).write(const SongsCompanion(
        isDownloaded: Value(false),
        localPath: Value(null),
      ));

  Future<void> incrementPlayCount(String id) async {
    final song = await getSongById(id);
    if (song == null) return;
    await (update(songs)..where((s) => s.id.equals(id)))
        .write(SongsCompanion(playCount: Value(song.playCount + 1)));
  }

  Future<void> deleteSong(String id) =>
      (delete(songs)..where((s) => s.id.equals(id))).go();
}
