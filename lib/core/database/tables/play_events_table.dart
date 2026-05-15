import 'package:drift/drift.dart';

/// Granular play event log used by the on-device recommender.
///
/// Every transition (track-start, skip, complete) writes one row. The
/// recommender derives skip-rate, completion-rate, and time-of-day affinity
/// from this. ListeningStats remains as the aggregate-seconds source.
class PlayEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get songId => text()();
  TextColumn get artistId => text().withDefault(const Constant(''))();
  TextColumn get language => text().withDefault(const Constant(''))();
  TextColumn get album => text().withDefault(const Constant(''))();

  /// 'complete' (>=80% played) | 'skip' (<80% played but moved on) |
  /// 'short_skip' (<10s played) | 'start' (track just began)
  TextColumn get eventType => text()();

  IntColumn get playedSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  /// 0-23, captured from local time at event.
  IntColumn get hourOfDay => integer().withDefault(const Constant(0))();

  DateTimeColumn get timestamp => dateTime()();
}
