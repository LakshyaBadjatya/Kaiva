import 'package:audio_service/audio_service.dart';

class StreamUrl {
  final int quality;
  final String url;

  const StreamUrl({required this.quality, required this.url});

  factory StreamUrl.fromJson(Map<String, dynamic> json) => StreamUrl(
    quality: int.tryParse(json['quality']?.toString().replaceAll('kbps', '') ?? '128') ?? 128,
    url: json['url'] as String,
  );
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String artworkUrl;
  final int durationSeconds;
  final String language;
  final List<StreamUrl> streamUrls;
  final bool hasLyrics;
  final String? lyricsId;
  final bool isExplicit;
  final int? year;

  // Local state
  final bool isLiked;
  final bool isDownloaded;
  final String? localPath;
  final int qualityKbps;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    required this.artworkUrl,
    required this.durationSeconds,
    required this.language,
    required this.streamUrls,
    this.hasLyrics = false,
    this.lyricsId,
    this.isExplicit = false,
    this.year,
    this.isLiked = false,
    this.isDownloaded = false,
    this.localPath,
    this.qualityKbps = 128,
  });

  String get bestStreamUrl {
    if (isDownloaded && localPath != null) return localPath!;
    final sorted = [...streamUrls]..sort((a, b) => b.quality.compareTo(a.quality));
    return sorted.isNotEmpty ? sorted.first.url : '';
  }

  String get highResArtworkUrl =>
      artworkUrl.replaceAll('150x150', '500x500');

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  MediaItem toMediaItem() => MediaItem(
    id: bestStreamUrl,
    title: title,
    artist: artist,
    album: album,
    duration: Duration(seconds: durationSeconds),
    artUri: Uri.parse(highResArtworkUrl),
    extras: {
      'songId': id,
      'artworkUrl': artworkUrl,
      'artistId': artistId,
      'albumId': albumId,
      'language': language,
    },
  );

  static String _decode(String? s) {
    if (s == null) return '';
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    final downloadUrls = (json['downloadUrl'] as List<dynamic>? ?? [])
        .map((e) => StreamUrl.fromJson(e as Map<String, dynamic>))
        .toList();

    final artistsJson = json['artists'] as Map<String, dynamic>?;
    final primaryArtists = artistsJson?['primary'] as List<dynamic>? ?? [];
    final firstArtist = primaryArtists.isNotEmpty
        ? primaryArtists.first as Map<String, dynamic>
        : <String, dynamic>{};

    return Song(
      id: json['id'] as String,
      title: _decode(json['name'] as String? ?? json['title'] as String?),
      artist: _decode(firstArtist['name'] as String? ?? json['primaryArtists'] as String?),
      artistId: firstArtist['id'] as String? ?? '',
      album: _decode(json['album'] is Map
          ? (json['album'] as Map<String, dynamic>)['name'] as String?
          : json['album'] as String?),
      albumId: json['album'] is Map
          ? (json['album'] as Map<String, dynamic>)['id'] as String? ?? ''
          : '',
      artworkUrl: (json['image'] as List<dynamic>?)?.lastOrNull?['url'] as String? ?? '',
      durationSeconds: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      language: json['language'] as String? ?? '',
      streamUrls: downloadUrls,
      hasLyrics: json['hasLyrics'] == true || json['hasLyrics'] == 'true',
      lyricsId: json['lyricsId'] as String?,
      isExplicit: json['explicitContent'] == 1 || json['explicitContent'] == true,
      year: int.tryParse(json['year']?.toString() ?? ''),
    );
  }

  Song copyWith({
    bool? isLiked,
    bool? isDownloaded,
    String? localPath,
    int? qualityKbps,
  }) => Song(
    id: id,
    title: title,
    artist: artist,
    artistId: artistId,
    album: album,
    albumId: albumId,
    artworkUrl: artworkUrl,
    durationSeconds: durationSeconds,
    language: language,
    streamUrls: streamUrls,
    hasLyrics: hasLyrics,
    lyricsId: lyricsId,
    isExplicit: isExplicit,
    year: year,
    isLiked: isLiked ?? this.isLiked,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    localPath: localPath ?? this.localPath,
    qualityKbps: qualityKbps ?? this.qualityKbps,
  );
}
