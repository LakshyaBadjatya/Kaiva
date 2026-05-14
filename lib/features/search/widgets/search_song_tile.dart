import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/song.dart';
import '../../../core/utils/song_loader.dart';
import '../../../features/player/player_provider.dart';
import '../../../shared/widgets/song_tile.dart';
import '../search_provider.dart';

class SearchSongTile extends ConsumerWidget {
  final Song song;
  final List<Song>? queue;
  final int? indexInQueue;

  const SearchSongTile({
    super.key,
    required this.song,
    this.queue,
    this.indexInQueue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = currentSong?.id == song.id;

    return SongTile(
      song: song,
      isPlaying: isPlaying,
      onTap: () async {
        ref.read(recentSearchSongsProvider.notifier).add(song);
        final q = queue ?? [song];
        final idx = indexInQueue ?? 0;
        final reordered = [q[idx], ...q.sublist(0, idx), ...q.sublist(idx + 1)];
        final fresh = await fetchFreshQueue(reordered);
        ref.read(audioHandlerProvider).playQueue(fresh, 0);
      },
    );
  }
}
