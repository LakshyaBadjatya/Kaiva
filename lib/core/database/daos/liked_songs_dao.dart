import 'package:drift/drift.dart';
import '../kaiva_database.dart';
import '../tables/liked_songs_table.dart';
import '../tables/songs_table.dart';

part 'liked_songs_dao.g.dart';

@DriftAccessor(tables: [LikedSongs, Songs])
class LikedSongsDao extends DatabaseAccessor<KaivaDatabase> with _$LikedSongsDaoMixin {
  LikedSongsDao(super.db);

  Stream<List<Song>> watchLikedSongs() {
    final query = select(likedSongs).join([
      innerJoin(songs, songs.id.equalsExp(likedSongs.songId)),
    ])..orderBy([OrderingTerm.desc(likedSongs.likedAt)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(songs)).toList());
  }

  Future<bool> isLiked(String songId) async {
    final result = await (select(likedSongs)..where((l) => l.songId.equals(songId))).getSingleOrNull();
    return result != null;
  }

  Stream<bool> watchIsLiked(String songId) =>
      (select(likedSongs)..where((l) => l.songId.equals(songId)))
          .watchSingleOrNull()
          .map((row) => row != null);

  Future<void> likeSong(String songId) =>
      into(likedSongs).insertOnConflictUpdate(LikedSongsCompanion(
        songId: Value(songId),
        likedAt: Value(DateTime.now()),
      ));

  Future<void> unlikeSong(String songId) =>
      (delete(likedSongs)..where((l) => l.songId.equals(songId))).go();

  Future<void> toggleLike(String songId) async {
    if (await isLiked(songId)) {
      await unlikeSong(songId);
    } else {
      await likeSong(songId);
    }
  }

  Future<void> clearAll() => delete(likedSongs).go();
}
