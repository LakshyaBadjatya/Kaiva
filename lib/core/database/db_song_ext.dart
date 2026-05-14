import '../database/kaiva_database.dart' show Song;
import '../models/song.dart' as model;

// Converts a Drift-generated Song row to the app's model Song.
extension DbSongToModel on Song {
  model.Song toModel() => model.Song(
    id: id,
    title: title,
    artist: artist,
    artistId: artistId,
    album: album,
    albumId: albumId ?? '',
    artworkUrl: artworkUrl,
    durationSeconds: duration,
    language: language,
    streamUrls: streamUrl != null
        ? [model.StreamUrl(quality: qualityKbps, url: streamUrl!)]
        : [],
    hasLyrics: hasLyrics,
    isExplicit: isExplicit,
    year: year,
    isDownloaded: isDownloaded,
    localPath: localPath,
    qualityKbps: qualityKbps,
  );
}

extension DbSongListToModel on List<Song> {
  List<model.Song> toModels() => map((s) => s.toModel()).toList();
}
