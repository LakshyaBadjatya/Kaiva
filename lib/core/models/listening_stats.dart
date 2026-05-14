class ListeningStats {
  final String songId;
  final String artistId;
  final String? genre;
  final int secondsPlayed;
  final DateTime date;

  const ListeningStats({
    required this.songId,
    required this.artistId,
    this.genre,
    required this.secondsPlayed,
    required this.date,
  });

  String get formattedTime {
    final h = secondsPlayed ~/ 3600;
    final m = (secondsPlayed % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class WeeklyStats {
  final int totalSecondsPlayed;
  final Map<String, int> songPlaytime;    // songId → seconds
  final Map<String, int> artistPlaytime;  // artistId → seconds
  final Map<String, int> genrePlaytime;   // genre → seconds
  final Map<DateTime, int> dailyPlaytime; // day → seconds

  const WeeklyStats({
    required this.totalSecondsPlayed,
    required this.songPlaytime,
    required this.artistPlaytime,
    required this.genrePlaytime,
    required this.dailyPlaytime,
  });

  String get formattedTotal {
    final h = totalSecondsPlayed ~/ 3600;
    final m = (totalSecondsPlayed % 3600) ~/ 60;
    return '$h hours $m minutes';
  }
}
