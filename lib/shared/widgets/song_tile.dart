import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/downloads/download_manager.dart';
import '../../features/player/player_provider.dart';
import 'album_art.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
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
