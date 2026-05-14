import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/album.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';

final albumDetailProvider =
    FutureProvider.family<Album, String>((ref, id) async {
  final response = await ApiClient.instance().get(ApiEndpoints.album(id));
  final data =
      (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?
          ?? {};
  return Album.fromJson(data);
});

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));

    return albumAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView.builder(
          itemCount: 12,
          itemBuilder: (_, __) => const ShimmerSongTile(),
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Could not load album.', style: KaivaTextStyles.bodyMedium),
        ),
      ),
      data: (album) => _AlbumScaffold(album: album),
    );
  }
}

class _AlbumScaffold extends ConsumerWidget {
  final Album album;
  const _AlbumScaffold({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final songs = album.songs;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                album.name,
                style: KaivaTextStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: CachedNetworkImage(
                imageUrl: album.highResArtworkUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: KaivaColors.backgroundTertiary),
                errorWidget: (_, __, ___) =>
                    Container(color: KaivaColors.backgroundTertiary),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (album.artistName != null)
                          Text(album.artistName!, style: KaivaTextStyles.titleMedium),
                        Text(
                          [
                            if (album.year != null) '${album.year}',
                            '${songs.length} songs',
                            if (album.language != null) album.language!,
                          ].join(' · '),
                          style: KaivaTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (songs.isNotEmpty)
                    FloatingActionButton.small(
                      backgroundColor: KaivaColors.accentPrimary,
                      foregroundColor: KaivaColors.textOnAccent,
                      onPressed: () =>
                          ref.read(audioHandlerProvider).playQueue(songs, 0),
                      child: const Icon(Icons.play_arrow_rounded),
                    ),
                ],
              ),
            ),
          ),
          if (songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No tracks available.',
                  style: KaivaTextStyles.bodyMedium,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == songs.length) return const SizedBox(height: 80);
                  final song = songs[i];
                  return SongTile(
                    song: song,
                    isPlaying: currentSong?.id == song.id,
                    trackNumber: i + 1,
                    showArt: false,
                    onTap: () =>
                        ref.read(audioHandlerProvider).playQueue(songs, i),
                  );
                },
                childCount: songs.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}
