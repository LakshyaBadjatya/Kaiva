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

  Future<void> clearStats() => delete(listeningStats).go();

  DateTime _truncateToDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
