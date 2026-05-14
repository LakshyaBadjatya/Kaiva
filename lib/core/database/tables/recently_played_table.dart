import 'package:drift/drift.dart';

class RecentlyPlayed extends Table {
  IntColumn      get id       => integer().autoIncrement()();
  TextColumn     get songId   => text()();
  TextColumn     get context  => text().nullable()();
  DateTimeColumn get playedAt => dateTime()();
}
