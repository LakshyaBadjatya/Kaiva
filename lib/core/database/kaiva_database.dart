import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/liked_songs_table.dart';
import 'tables/recently_played_table.dart';
import 'tables/search_history_table.dart';
import 'tables/listening_stats_table.dart';
import 'daos/songs_dao.dart';
import 'daos/playlists_dao.dart';
import 'daos/liked_songs_dao.dart';
import 'daos/recently_played_dao.dart';
import 'daos/stats_dao.dart';

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
  ],
  daos: [
    SongsDao,
    PlaylistsDao,
    LikedSongsDao,
    RecentlyPlayedDao,
    StatsDao,
  ],
)
class KaivaDatabase extends _$KaivaDatabase {
  KaivaDatabase() : super(_openConnection());

  // ignore: annotate_overrides
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'kaiva_db');
  }
}
