import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/kaiva_database.dart';

/// One ranked song in the Wrapped recap.
class WrappedSong {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final int playCount;

  const WrappedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.playCount,
  });
}

class WrappedArtist {
  final String id;
  final String name;
  final String artworkUrl;
  final int minutes;

  const WrappedArtist({
    required this.id,
    required this.name,
    required this.artworkUrl,
    required this.minutes,
  });
}

class WrappedGenre {
  final String label;
  final double fraction; // 0..1
  const WrappedGenre({required this.label, required this.fraction});
}

/// Everything the Wrapped screen renders, computed from this year's
/// play_events joined with the songs table.
class WrappedData {
  final int year;
  final int totalMinutes;
  final int totalPlays;
  final WrappedSong? topSong;
  final List<WrappedSong> topSongs; // up to 5
  final WrappedArtist? topArtist;
  final List<WrappedArtist> topArtists; // up to 5
  final String personality; // "Night Owl" etc.
  final String personalityBlurb;
  final List<WrappedGenre> genres; // language as a genre proxy
  final List<int> minutesByMonth; // length 12
  final bool isEmpty;

  const WrappedData({
    required this.year,
    required this.totalMinutes,
    required this.totalPlays,
    required this.topSong,
    required this.topSongs,
    required this.topArtist,
    required this.topArtists,
    required this.personality,
    required this.personalityBlurb,
    required this.genres,
    required this.minutesByMonth,
    required this.isEmpty,
  });

  factory WrappedData.empty(int year) => WrappedData(
        year: year,
        totalMinutes: 0,
        totalPlays: 0,
        topSong: null,
        topSongs: const [],
        topArtist: null,
        topArtists: const [],
        personality: 'Explorer',
        personalityBlurb: 'Your year in music is just getting started.',
        genres: const [],
        minutesByMonth: List.filled(12, 0),
        isEmpty: true,
      );
}

final wrappedProvider = FutureProvider<WrappedData>((ref) async {
  final db = ref.watch(databaseProvider);
  final year = DateTime.now().year;
  final start = DateTime(year, 1, 1);
  final end = DateTime(year + 1, 1, 1);

  // Pull this year's meaningful listening events.
  final events = await (db.select(db.playEvents)
        ..where((e) =>
            e.timestamp.isBiggerOrEqualValue(start) &
            e.timestamp.isSmallerThanValue(end) &
            e.eventType.isIn(['complete', 'skip'])))
      .get();

  if (events.isEmpty) return WrappedData.empty(year);

  int totalSeconds = 0;
  final playCountBySong = <String, int>{};
  final secondsByArtist = <String, int>{};
  final secondsByLang = <String, int>{};
  final hourHistogram = List<int>.filled(24, 0);
  final minutesByMonth = List<int>.filled(12, 0);

  for (final e in events) {
    totalSeconds += e.playedSeconds;
    playCountBySong.update(e.songId, (v) => v + 1, ifAbsent: () => 1);
    if (e.artistId.isNotEmpty) {
      secondsByArtist.update(e.artistId, (v) => v + e.playedSeconds,
          ifAbsent: () => e.playedSeconds);
    }
    if (e.language.isNotEmpty) {
      secondsByLang.update(e.language, (v) => v + e.playedSeconds,
          ifAbsent: () => e.playedSeconds);
    }
    hourHistogram[e.hourOfDay.clamp(0, 23)]++;
    final m = e.timestamp.month - 1;
    minutesByMonth[m] += (e.playedSeconds / 60).round();
  }

  // Resolve song + artist display data from the songs table.
  Future<Song?> songRow(String id) => db.songsDao.getSongById(id);

  // Top songs.
  final songEntries = playCountBySong.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topSongs = <WrappedSong>[];
  for (final e in songEntries.take(5)) {
    final s = await songRow(e.key);
    if (s == null) continue;
    topSongs.add(WrappedSong(
      id: s.id,
      title: s.title,
      artist: s.artist,
      artworkUrl: s.artworkUrl,
      playCount: e.value,
    ));
  }

  // Top artists (need a display name + art — pull from any of their songs).
  final artistEntries = secondsByArtist.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topArtists = <WrappedArtist>[];
  for (final e in artistEntries.take(5)) {
    final s = await (db.select(db.songs)
          ..where((t) => t.artistId.equals(e.key))
          ..limit(1))
        .getSingleOrNull();
    if (s == null) continue;
    topArtists.add(WrappedArtist(
      id: e.key,
      name: s.artist,
      artworkUrl: s.artworkUrl,
      minutes: (e.value / 60).round(),
    ));
  }

  // Personality from the hour the user listens most.
  final peakHour = _argMax(hourHistogram);
  final (personality, blurb) = _personalityFor(peakHour);

  // "Genre" breakdown — language is the closest proxy in this catalogue.
  final langTotal =
      secondsByLang.values.fold<int>(0, (a, b) => a + b);
  final genreEntries = secondsByLang.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final genres = <WrappedGenre>[];
  for (final e in genreEntries.take(5)) {
    if (langTotal == 0) break;
    genres.add(WrappedGenre(
      label: _titleCase(e.key),
      fraction: e.value / langTotal,
    ));
  }

  return WrappedData(
    year: year,
    totalMinutes: (totalSeconds / 60).round(),
    totalPlays: events.where((e) => e.eventType == 'complete').length,
    topSong: topSongs.isNotEmpty ? topSongs.first : null,
    topSongs: topSongs,
    topArtist: topArtists.isNotEmpty ? topArtists.first : null,
    topArtists: topArtists,
    personality: personality,
    personalityBlurb: blurb,
    genres: genres,
    minutesByMonth: minutesByMonth,
    isEmpty: false,
  );
});

int _argMax(List<int> xs) {
  int best = 0;
  int bestI = 0;
  for (int i = 0; i < xs.length; i++) {
    if (xs[i] > best) {
      best = xs[i];
      bestI = i;
    }
  }
  return bestI;
}

(String, String) _personalityFor(int hour) {
  if (hour >= 5 && hour < 12) {
    return ('Early Bird', 'Mornings are your soundtrack.');
  }
  if (hour >= 12 && hour < 17) {
    return ('Daydreamer', 'Afternoons hit different with you.');
  }
  if (hour >= 17 && hour < 22) {
    return ('Golden Hour', 'You score your evenings perfectly.');
  }
  return ('Night Owl', 'The quiet hours are when you go deepest.');
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
