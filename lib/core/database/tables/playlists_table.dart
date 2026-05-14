import 'package:drift/drift.dart';

class LocalPlaylists extends Table {
  TextColumn     get id          => text()();
  TextColumn     get name        => text()();
  TextColumn     get description => text().nullable()();
  TextColumn     get coverPath   => text().nullable()();
  TextColumn     get coverUrl    => text().nullable()();
  IntColumn      get songCount   => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt   => dateTime()();
  DateTimeColumn get updatedAt   => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
