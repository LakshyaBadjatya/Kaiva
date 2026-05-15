import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/kaiva_database.dart' show SongsCompanion;
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/downloads/download_manager.dart';
import '../../features/player/player_provider.dart';
import 'album_art.dart';
import 'celebration_overlay.dart';
import 'waveform_animation.dart';

class SongTile extends ConsumerWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final int? trackNumber;
  final bool showArt;
  final bool showDownload;

  const SongTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    this.onTap,
    this.onMoreTap,
    this.trackNumber,
    this.showArt = true,
    this.showDownload = true,
  });

  Future<void> _ensureSongRow(WidgetRef ref) async {
    await ref.read(databaseProvider).songsDao.upsertSong(SongsCompanion(
          id: Value(song.id),
          title: Value(song.title),
          artist: Value(song.artist),
          artistId: Value(song.artistId),
          album: Value(song.album),
          albumId: Value(song.albumId),
          artworkUrl: Value(song.artworkUrl),
          duration: Value(song.durationSeconds),
          language: Value(song.language),
          streamUrl: Value(song.bestStreamUrl),
          hasLyrics: Value(song.hasLyrics),
          isExplicit: Value(song.isExplicit),
          year: Value(song.year),
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey('swipe_${song.id}_${trackNumber ?? ''}'),
        // Action swipes — never actually dismiss the tile.
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            // Swipe right → like
            await _ensureSongRow(ref);
            final db = ref.read(databaseProvider);
            final wasLiked =
                await db.likedSongsDao.watchIsLiked(song.id).first;
            await db.likedSongsDao.toggleLike(song.id);
            if (!wasLiked) celebrateFirstLikeIfNeeded(ref);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Updated Liked Songs',
                      style: KaivaTextStyles.bodySmall),
                  backgroundColor: KaivaColors.backgroundElevated,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Swipe left → add to queue
            await ref.read(audioHandlerProvider).addToQueue(song);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${song.title}" to queue',
                      style: KaivaTextStyles.bodySmall),
                  backgroundColor: KaivaColors.backgroundElevated,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
          return false; // spring back
        },
        background: const _SwipeBg(
          alignment: Alignment.centerLeft,
          icon: Icons.favorite_rounded,
          label: 'Like',
        ),
        secondaryBackground: const _SwipeBg(
          alignment: Alignment.centerRight,
          icon: Icons.queue_music_rounded,
          label: 'Queue',
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              if (trackNumber != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    '$trackNumber',
                    style: KaivaTextStyles.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (showArt) ...[
                AlbumArt(
                  url: song.artworkUrl,
                  size: 48,
                  borderRadius: 6,
                  heroTag: trackNumber == null ? 'album_art_${song.id}' : null,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: KaivaTextStyles.titleMedium.copyWith(
                        color: isPlaying
                            ? KaivaColors.accentPrimary
                            : KaivaColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: KaivaTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPlaying)
                _PlayingIndicator(song: song)
              else ...[
                Text(song.formattedDuration, style: KaivaTextStyles.durationLabel),
                if (showDownload) _DownloadIcon(song: song, ref: ref),
              ],
              if (onMoreTap != null) ...[
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: onMoreTap,
                  color: KaivaColors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Swipe action background ───────────────────────────────────
class _SwipeBg extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final String label;

  const _SwipeBg({
    required this.alignment,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      color: KaivaColors.accentGlow,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Text(label,
                style: KaivaTextStyles.labelMedium
                    .copyWith(color: KaivaColors.accentPrimary)),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: KaivaColors.accentPrimary, size: 22),
          if (isLeft) ...[
            const SizedBox(width: 8),
            Text(label,
                style: KaivaTextStyles.labelMedium
                    .copyWith(color: KaivaColors.accentPrimary)),
          ],
        ],
      ),
    );
  }
}

class _PlayingIndicator extends ConsumerWidget {
  final Song song;
  const _PlayingIndicator({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    return WaveformAnimation(isPlaying: isPlaying);
  }
}

class _DownloadIcon extends StatelessWidget {
  final Song song;
  final WidgetRef ref;
  const _DownloadIcon({required this.song, required this.ref});

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<bool>(
      stream: db.songsDao
          .watchAllSongs()
          .map((list) => list.any((s) => s.id == song.id && s.isDownloaded)),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? song.isDownloaded;
        return IconButton(
          icon: Icon(
            isDownloaded
                ? Icons.download_done_rounded
                : Icons.download_outlined,
            size: 20,
            color: isDownloaded ? KaivaColors.accentPrimary : KaivaColors.textMuted,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: isDownloaded
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  ref.read(downloadManagerProvider).downloadSong(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading "${song.title}"',
                          style: KaivaTextStyles.bodySmall),
                      backgroundColor: KaivaColors.backgroundElevated,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
        );
      },
    );
  }
}
