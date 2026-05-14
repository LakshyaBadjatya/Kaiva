import 'package:drift/drift.dart';

class Songs extends Table {
  TextColumn    get id           => text()();
  TextColumn    get title        => text()();
  TextColumn    get artist       => text()();
  TextColumn    get album        => text()();
  TextColumn    get albumId      => text().nullable()();
  TextColumn    get artistId     => text()();
  TextColumn    get artworkUrl   => text()();
  IntColumn     get duration     => integer()();
  TextColumn    get language     => text()();
  TextColumn    get streamUrl    => text().nullable()();
  BoolColumn    get isDownloaded => boolean().withDefault(const Constant(false))();
  TextColumn    get localPath    => text().nullable()();
  IntColumn     get qualityKbps  => integer().withDefault(const Constant(128))();
  IntColumn     get playCount    => integer().withDefault(const Constant(0))();
  BoolColumn    get hasLyrics    => boolean().withDefault(const Constant(false))();
  BoolColumn    get isExplicit   => boolean().withDefault(const Constant(false))();
  IntColumn     get year         => integer().nullable()();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt     => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
