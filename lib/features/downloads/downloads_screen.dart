import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';
import 'download_manager.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(downloadedSongsProvider);
    final storageAsync = ref.watch(storageInfoProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Downloads', style: KaivaTextStyles.headlineLarge),
          ),

          // Storage bar
          SliverToBoxAdapter(
            child: storageAsync.when(
              data: (info) => _StorageBar(info: info),
              loading: () => const _StorageBarShimmer(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Songs list
          songsAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const ShimmerSongTile(),
                childCount: 10,
              ),
            ),
            error: (_, __) => const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Could not load downloads.',
                  style: KaivaTextStyles.bodyMedium,
                ),
              ),
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyDownloads(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == songs.length) return const SizedBox(height: 80);
                    final song = songs[i];
                    final currentSong =
                        ref.watch(currentSongProvider).valueOrNull;
                    return Dismissible(
                      key: Key(song.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: KaivaColors.error,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) => ref
                          .read(downloadManagerProvider)
                          .deleteDownload(song),
                      child: SongTile(
                        song: song,
                        isPlaying: currentSong?.id == song.id,
                        onTap: () => ref
                            .read(audioHandlerProvider)
                            .playQueue(songs, i),
                        onMoreTap: () => _showOptions(context, ref, song),
                      ),
                    );
                  },
                  childCount: songs.length + 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KaivaColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: KaivaColors.error),
              title: Text('Delete download',
                  style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.error)),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(downloadManagerProvider).deleteDownload(song);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Storage bar ───────────────────────────────────────────────
class _StorageBar extends StatelessWidget {
  final StorageInfo info;
  const _StorageBar({required this.info});

  @override
  Widget build(BuildContext context) {
    final fraction = info.totalBytes > 0
        ? (info.kaivaUsedBytes / info.totalBytes).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Used by Kaiva', style: KaivaTextStyles.bodySmall),
              Text(
                '${info.kaivaFormatted} · ${info.freeFormatted} free',
                style: KaivaTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: KaivaColors.backgroundTertiary,
              color: KaivaColors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageBarShimmer extends StatelessWidget {
  const _StorageBarShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ShimmerCard(width: double.infinity, height: 40),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_outlined,
            size: 52,
            color: KaivaColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'No downloads yet.\nDownload songs to listen offline.',
            style: KaivaTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
