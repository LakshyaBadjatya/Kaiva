import 'package:drift/drift.dart';

class ListeningStats extends Table {
  TextColumn     get songId        => text()();
  TextColumn     get artistId      => text()();
  TextColumn     get genre         => text().nullable()();
  IntColumn      get secondsPlayed => integer().withDefault(const Constant(0))();
  DateTimeColumn get date          => dateTime()();

  @override
  Set<Column> get primaryKey => {songId, date};
}
