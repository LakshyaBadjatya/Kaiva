import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/liked_songs_table.dart';
import 'tables/recently_played_table.dart';
import 'tables/search_history_table.dart';
import 'tables/listening_stats_table.dart';
import 'tables/play_events_table.dart';
import 'daos/songs_dao.dart';
import 'daos/playlists_dao.dart';
import 'daos/liked_songs_dao.dart';
import 'daos/recently_played_dao.dart';
import 'daos/stats_dao.dart';
import 'daos/play_events_dao.dart';

part 'kaiva_database.g.dart';

@DriftDatabase(
  tables: [
    Songs,
    LocalPlaylists,
    PlaylistSongs,
    LikedSongs,
    RecentlyPlayed,
    SearchHistory,
    ListeningStats,
    PlayEvents,
  ],
  daos: [
    SongsDao,
    PlaylistsDao,
    LikedSongsDao,
    RecentlyPlayedDao,
    StatsDao,
    PlayEventsDao,
  ],
)
class KaivaDatabase extends _$KaivaDatabase {
  KaivaDatabase() : super(_openConnection());

  // ignore: annotate_overrides
  int get schemaVersion => 2;

  // Add the new table on upgrade so existing installs don't crash.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(playEvents);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'kaiva_db');
  }
}
