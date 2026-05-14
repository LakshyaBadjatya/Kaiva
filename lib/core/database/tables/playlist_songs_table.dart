import 'package:drift/drift.dart';

class PlaylistSongs extends Table {
  TextColumn     get playlistId => text()();
  TextColumn     get songId     => text()();
  IntColumn      get position   => integer()();
  DateTimeColumn get addedAt    => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}
