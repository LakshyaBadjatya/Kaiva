import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/artist.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';

final artistDetailProvider =
    FutureProvider.family<Artist, String>((ref, id) async {
  final response = await ApiClient.instance().get(ApiEndpoints.artist(id));
  final data =
      (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?
          ?? {};
  return Artist.fromJson(data);
});

class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailProvider(artistId));

    return artistAsync.when(
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
          child: Text('Could not load artist.', style: KaivaTextStyles.bodyMedium),
        ),
      ),
      data: (artist) => _ArtistScaffold(artist: artist),
    );
  }
}

class _ArtistScaffold extends ConsumerWidget {
  final Artist artist;
  const _ArtistScaffold({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final songs = artist.topSongs;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: KaivaTextStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (artist.highResImageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: artist.highResImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: KaivaColors.backgroundTertiary),
                      errorWidget: (_, __, ___) =>
                          Container(color: KaivaColors.backgroundTertiary),
                    )
                  else
                    Container(color: KaivaColors.backgroundTertiary),
                  // Gradient for readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, KaivaColors.backgroundPrimary],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Follower count + play button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (artist.followerCount != null)
                          Text(
                            '${_formatCount(artist.followerCount!)} followers',
                            style: KaivaTextStyles.bodySmall,
                          ),
                        if (artist.bio != null && artist.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              artist.bio!,
                              style: KaivaTextStyles.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
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

          // Popular Songs section
          if (songs.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Popular Songs', style: KaivaTextStyles.sectionHeader),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == songs.length) return const SizedBox.shrink();
                  final song = songs[i];
                  return SongTile(
                    song: song,
                    isPlaying: currentSong?.id == song.id,
                    trackNumber: i + 1,
                    showArt: true,
                    onTap: () =>
                        ref.read(audioHandlerProvider).playQueue(songs, i),
                  );
                },
                childCount: songs.length,
              ),
            ),
          ],

          // Albums section
          if (artist.albums.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Albums', style: KaivaTextStyles.sectionHeader),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: artist.albums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final album = artist.albums[i];
                    return GestureDetector(
                      onTap: () => context.push('/album/${album.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: album.highResArtworkUrl,
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 130,
                                height: 130,
                                color: KaivaColors.backgroundTertiary,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 130,
                                height: 130,
                                color: KaivaColors.backgroundTertiary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 130,
                            child: Text(
                              album.name,
                              style: KaivaTextStyles.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Similar artists
          if (artist.similarArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Similar Artists', style: KaivaTextStyles.sectionHeader),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: artist.similarArtists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final a = artist.similarArtists[i];
                    return GestureDetector(
                      onTap: () => context.push('/artist/${a.id}'),
                      child: Column(
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: a.highResImageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 72,
                                height: 72,
                                color: KaivaColors.backgroundTertiary,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: KaivaColors.backgroundTertiary,
                                child: const Icon(Icons.person_outline,
                                    color: KaivaColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 72,
                            child: Text(
                              a.name,
                              style: KaivaTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return '$count';
  }
}
