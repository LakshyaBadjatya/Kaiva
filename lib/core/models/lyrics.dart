class LyricLine {
  final Duration? timestamp;
  final String text;

  const LyricLine({this.timestamp, required this.text});
}

class Lyrics {
  final String songId;
  final bool isTimed;
  final List<LyricLine> lines;
  final String? rawText;

  const Lyrics({
    required this.songId,
    required this.isTimed,
    required this.lines,
    this.rawText,
  });

  factory Lyrics.fromJson(String songId, Map<String, dynamic> json) {
    final rawLyrics = json['lyrics'] as String? ?? '';
    final lines = _parseLyrics(rawLyrics);
    final isTimed = lines.any((l) => l.timestamp != null);
    return Lyrics(
      songId: songId,
      isTimed: isTimed,
      lines: lines,
      rawText: isTimed ? null : rawLyrics,
    );
  }

  static List<LyricLine> _parseLyrics(String raw) {
    // Try to parse [MM:SS.ms] format
    final timedRegex = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$');
    final results = <LyricLine>[];

    for (final line in raw.split('\n')) {
      final match = timedRegex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
        final text = match.group(4)!.trim();
        results.add(LyricLine(
          timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
          text: text,
        ));
      } else if (line.trim().isNotEmpty) {
        results.add(LyricLine(text: line.trim()));
      }
    }
    return results;
  }
}
