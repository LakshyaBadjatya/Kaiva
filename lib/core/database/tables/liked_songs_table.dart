import 'package:drift/drift.dart';

class LikedSongs extends Table {
  TextColumn     get songId  => text()();
  DateTimeColumn get likedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {songId};
}
