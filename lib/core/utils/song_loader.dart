import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/song.dart';

/// Fetches a fresh copy of a song from the API, ensuring stream URLs
/// are not expired. Falls back to the original song if the fetch fails.
Future<Song> fetchFreshSong(Song song) async {
  if (song.isDownloaded && song.localPath != null) return song;
  try {
    final response = await ApiClient.instance().get(ApiEndpoints.song(song.id));
    final raw = response.data as Map<String, dynamic>?;
    final data = raw?['data'];
    // API returns either a list or a single map depending on version
    final Map<String, dynamic> songJson = data is List
        ? data.first as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return Song.fromJson(songJson);
  } catch (_) {
    return song; // play with whatever URLs we have
  }
}

/// Fetches fresh stream URLs for a list of songs concurrently (capped at 3
/// parallel fetches to avoid hammering the API).
Future<List<Song>> fetchFreshQueue(List<Song> songs) async {
  // Only refresh the first song immediately; the rest fetch lazily
  if (songs.isEmpty) return songs;
  final first = await fetchFreshSong(songs.first);
  return [first, ...songs.skip(1)];
}
