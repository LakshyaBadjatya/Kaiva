import 'package:drift/drift.dart';
import '../kaiva_database.dart';
import '../tables/play_events_table.dart';

part 'play_events_dao.g.dart';

/// Record types returned by DAO queries — used as inputs to the taste profile.
typedef ArtistAffinity = ({String artistId, int totalCompletes, int totalSkips, double affinity});
typedef LanguageAffinity = ({String language, int completes, int total});
typedef HourAffinity = ({int hour, int plays});

@DriftAccessor(tables: [PlayEvents])
class PlayEventsDao extends DatabaseAccessor<KaivaDatabase>
    with _$PlayEventsDaoMixin {
  PlayEventsDao(super.db);

  /// One row per real event. Caller passes ['complete' | 'skip' | 'short_skip' | 'start'].
  Future<void> recordEvent({
    required String songId,
    required String artistId,
    required String language,
    required String album,
    required String eventType,
    required int playedSeconds,
    required int durationSeconds,
  }) async {
    final now = DateTime.now();
    await into(playEvents).insert(PlayEventsCompanion(
      songId: Value(songId),
      artistId: Value(artistId),
      language: Value(language),
      album: Value(album),
      eventType: Value(eventType),
      playedSeconds: Value(playedSeconds),
      durationSeconds: Value(durationSeconds),
      hourOfDay: Value(now.hour),
      timestamp: Value(now),
    ));
  }

  /// Total number of non-start events recorded — used to decide cold-start.
  Future<int> totalPlays() async {
    final rows = await customSelect(
      "SELECT COUNT(*) AS c FROM play_events WHERE event_type IN ('complete','skip','short_skip')",
      readsFrom: {playEvents},
    ).getSingle();
    return rows.read<int>('c');
  }

  /// Artist affinity = completes / (completes + skips + 1).
  /// We give "complete" 1.0 weight, "skip" -0.5, "short_skip" -1.0.
  /// Returns up to [limit] artists, highest affinity first.
  Future<List<ArtistAffinity>> topArtists({int limit = 20}) async {
    final rows = await customSelect(
      """
      SELECT artist_id,
             SUM(CASE WHEN event_type = 'complete' THEN 1 ELSE 0 END) AS completes,
             SUM(CASE WHEN event_type = 'skip' THEN 1 ELSE 0 END) AS skips,
             SUM(CASE WHEN event_type = 'short_skip' THEN 1 ELSE 0 END) AS short_skips
      FROM play_events
      WHERE artist_id != ''
      GROUP BY artist_id
      HAVING completes + skips + short_skips >= 2
      ORDER BY (completes * 1.0 - skips * 0.5 - short_skips * 1.0) DESC
      LIMIT ?
      """,
      variables: [Variable.withInt(limit)],
      readsFrom: {playEvents},
    ).get();

    return rows.map((r) {
      final completes = r.read<int>('completes');
      final skips = r.read<int>('skips');
      final shortSkips = r.read<int>('short_skips');
      final total = completes + skips + shortSkips;
      // Bayesian-smoothed affinity in [0, 1]
      final affinity = (completes + 0.5) / (total + 1.0);
      return (
        artistId: r.read<String>('artist_id'),
        totalCompletes: completes,
        totalSkips: skips + shortSkips,
        affinity: affinity,
      );
    }).toList();
  }

  /// Languages the user actually finishes listening to.
  Future<List<LanguageAffinity>> topLanguages({int limit = 10}) async {
    final rows = await customSelect(
      """
      SELECT language,
             SUM(CASE WHEN event_type = 'complete' THEN 1 ELSE 0 END) AS completes,
             COUNT(*) AS total
      FROM play_events
      WHERE language != '' AND event_type != 'start'
      GROUP BY language
      ORDER BY completes DESC
      LIMIT ?
      """,
      variables: [Variable.withInt(limit)],
      readsFrom: {playEvents},
    ).get();
    return rows
        .map((r) => (
              language: r.read<String>('language'),
              completes: r.read<int>('completes'),
              total: r.read<int>('total'),
            ))
        .toList();
  }

  /// Distribution of completes across the 24 hours.
  Future<List<HourAffinity>> hourDistribution() async {
    final rows = await customSelect(
      """
      SELECT hour_of_day, COUNT(*) AS plays
      FROM play_events
      WHERE event_type = 'complete'
      GROUP BY hour_of_day
      """,
      readsFrom: {playEvents},
    ).get();
    return rows
        .map((r) => (
              hour: r.read<int>('hour_of_day'),
              plays: r.read<int>('plays'),
            ))
        .toList();
  }

  /// Song IDs the user has seen in the last [days] days — used to avoid
  /// recommending songs they already heard.
  Future<Set<String>> recentSongIds({int days = 14}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rows = await (selectOnly(playEvents, distinct: true)
          ..addColumns([playEvents.songId])
          ..where(playEvents.timestamp.isBiggerThanValue(cutoff)))
        .get();
    return rows.map((r) => r.read(playEvents.songId)!).toSet();
  }

  /// IDs of songs the user has skipped — used as a soft penalty.
  Future<Set<String>> skippedSongIds() async {
    final rows = await (selectOnly(playEvents, distinct: true)
          ..addColumns([playEvents.songId])
          ..where(playEvents.eventType.isIn(['skip', 'short_skip'])))
        .get();
    return rows.map((r) => r.read(playEvents.songId)!).toSet();
  }

  /// Songs the user has completed at least twice — strong positive signal,
  /// useful as recommendation seeds.
  Future<List<String>> topSeedSongs({int limit = 10}) async {
    final rows = await customSelect(
      """
      SELECT song_id, COUNT(*) AS c
      FROM play_events
      WHERE event_type = 'complete'
      GROUP BY song_id
      HAVING c >= 2
      ORDER BY c DESC, MAX(timestamp) DESC
      LIMIT ?
      """,
      variables: [Variable.withInt(limit)],
      readsFrom: {playEvents},
    ).get();
    return rows.map((r) => r.read<String>('song_id')).toList();
  }

  Future<void> clear() => delete(playEvents).go();
}
