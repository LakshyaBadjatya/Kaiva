import 'package:drift/drift.dart';
import '../kaiva_database.dart';
import '../tables/listening_stats_table.dart';

part 'stats_dao.g.dart';

@DriftAccessor(tables: [ListeningStats])
class StatsDao extends DatabaseAccessor<KaivaDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  Future<void> recordListening({
    required String songId,
    required String artistId,
    String? genre,
    required int secondsPlayed,
  }) async {
    final today = _truncateToDay(DateTime.now());
    final existing = await (select(listeningStats)
      ..where((s) => s.songId.equals(songId) & s.date.equals(today)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(listeningStats)
        ..where((s) => s.songId.equals(songId) & s.date.equals(today)))
          .write(ListeningStatsCompanion(
            secondsPlayed: Value(existing.secondsPlayed + secondsPlayed),
          ));
    } else {
      await into(listeningStats).insert(ListeningStatsCompanion(
        songId: Value(songId),
        artistId: Value(artistId),
        genre: Value(genre),
        secondsPlayed: Value(secondsPlayed),
        date: Value(today),
      ));
    }
  }

  Future<List<ListeningStat>> getWeeklyStats() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return (select(listeningStats)..where((s) => s.date.isBiggerOrEqualValue(weekAgo))).get();
  }

  Future<List<ListeningStat>> getAllTimeStats() => select(listeningStats).get();

  /// Top artists by total seconds played, all time. Returns up to [limit] rows.
  Future<List<({String artistId, int totalSeconds})>> getTopArtists({int limit = 10}) async {
    final rows = await customSelect(
      'SELECT artist_id, SUM(seconds_played) AS total '
      'FROM listening_stats '
      'GROUP BY artist_id '
      'ORDER BY total DESC '
      'LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {listeningStats},
    ).get();
    return rows.map((r) => (
      artistId: r.read<String>('artist_id'),
      totalSeconds: r.read<int>('total'),
    )).toList();
  }

  /// Albums played today, ordered by play count descending.
  Future<List<({String albumId, String album, String artworkUrl, int playCount})>>
      getDailyAlbums({int limit = 10}) async {
    final today = _truncateToDay(DateTime.now());
    final rows = await customSelect(
      'SELECT s.album_id, s.album, s.artwork_url, COUNT(*) AS cnt '
      'FROM listening_stats ls '
      'JOIN songs s ON ls.song_id = s.id '
      'WHERE ls.date = ? AND s.album_id IS NOT NULL AND s.album_id != "" '
      'GROUP BY s.album_id '
      'ORDER BY cnt DESC '
      'LIMIT ?',
      variables: [Variable.withDateTime(today), Variable.withInt(limit)],
      readsFrom: {listeningStats},
    ).get();
    return rows.map((r) => (
      albumId: r.read<String>('album_id'),
      album: r.read<String>('album'),
      artworkUrl: r.read<String>('artwork_url'),
      playCount: r.read<int>('cnt'),
    )).toList();
  }

  Future<void> clearStats() => delete(listeningStats).go();

  DateTime _truncateToDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
