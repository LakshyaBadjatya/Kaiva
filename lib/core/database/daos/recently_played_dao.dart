import 'package:drift/drift.dart';
import '../kaiva_database.dart';
import '../tables/recently_played_table.dart';
import '../tables/songs_table.dart';
import '../tables/search_history_table.dart';

part 'recently_played_dao.g.dart';

@DriftAccessor(tables: [RecentlyPlayed, Songs, SearchHistory])
class RecentlyPlayedDao extends DatabaseAccessor<KaivaDatabase> with _$RecentlyPlayedDaoMixin {
  RecentlyPlayedDao(super.db);

  Stream<List<Song>> watchRecentlyPlayed({int limit = 20}) {
    final query = (select(recentlyPlayed)
      ..orderBy([(r) => OrderingTerm.desc(r.playedAt)])
      ..limit(limit))
        .join([innerJoin(songs, songs.id.equalsExp(recentlyPlayed.songId))]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(songs)).toList());
  }

  Future<void> recordPlay(String songId, {String? context}) async {
    await into(recentlyPlayed).insert(RecentlyPlayedCompanion(
      songId: Value(songId),
      context: Value(context),
      playedAt: Value(DateTime.now()),
    ));
    // Keep only last 200 entries
    final allRows = await (select(recentlyPlayed)
      ..orderBy([(r) => OrderingTerm.desc(r.playedAt)])).get();
    if (allRows.length > 200) {
      final toDelete = allRows.skip(200).map((r) => r.id).toList();
      await (delete(recentlyPlayed)..where((r) => r.id.isIn(toDelete))).go();
    }
  }

  Future<void> clearHistory() => delete(recentlyPlayed).go();

  // Search history
  Stream<List<SearchHistoryData>> watchSearchHistory({int limit = 15}) =>
      (select(searchHistory)
        ..orderBy([(s) => OrderingTerm.desc(s.searchedAt)])
        ..limit(limit))
          .watch();

  Future<void> addSearchQuery(String query) async {
    await (delete(searchHistory)..where((s) => s.query.equals(query))).go();
    await into(searchHistory).insert(SearchHistoryCompanion(
      query: Value(query),
      searchedAt: Value(DateTime.now()),
    ));
    final all = await (select(searchHistory)..orderBy([(s) => OrderingTerm.desc(s.searchedAt)])).get();
    if (all.length > 15) {
      final toDelete = all.skip(15).map((s) => s.id).toList();
      await (delete(searchHistory)..where((s) => s.id.isIn(toDelete))).go();
    }
  }

  Future<void> deleteSearchQuery(int id) =>
      (delete(searchHistory)..where((s) => s.id.equals(id))).go();

  Future<void> clearSearchHistory() => delete(searchHistory).go();
}
