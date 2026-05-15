import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marquee/marquee.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/models/song.dart';
import '../../shared/widgets/album_art.dart';
import 'player_provider.dart';

// ─────────────────────────────────────────────────────────────
//  Mini Player — Editorial Noir glass dock
//  · Backdrop-blur (24px) + 70% black fill + 1px white@10% border
//  · Small album art tile + Playfair title + DM Sans subtitle
//  · Favorite icon (warm sand), filled play button using on-surface color
// ─────────────────────────────────────────────────────────────

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider).valueOrNull;

    return AnimatedSlide(
      offset: song == null ? const Offset(0, 1) : Offset.zero,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: song == null ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: song == null ? const SizedBox.shrink() : _MiniPlayerContent(song: song),
      ),
    );
  }
}

class _MiniPlayerContent extends ConsumerStatefulWidget {
  final Song song;
  const _MiniPlayerContent({required this.song});

  @override
  ConsumerState<_MiniPlayerContent> createState() => _MiniPlayerContentState();
}

class _MiniPlayerContentState extends ConsumerState<_MiniPlayerContent> {
  double _dragDeltaX = 0;

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final handler = ref.read(audioHandlerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KaivaRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: KaivaColors.surfaceContainerHigh.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(KaivaRadius.md),
              border: Border.all(color: KaivaColors.borderSubtle, width: 1),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/player'),
                            onVerticalDragEnd: (d) {
                              if (d.primaryVelocity != null &&
                                  d.primaryVelocity! < -200) {
                                context.push('/player');
                              }
                            },
                            onHorizontalDragUpdate: (d) =>
                                _dragDeltaX += d.delta.dx,
                            onHorizontalDragEnd: (d) {
                              if (_dragDeltaX < -60) {
                                HapticFeedback.lightImpact();
                                handler.skipToNext();
                              } else if (_dragDeltaX > 60) {
                                HapticFeedback.lightImpact();
                                handler.skipToPrevious();
                              }
                              _dragDeltaX = 0;
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(KaivaRadius.sm),
                                  child: AlbumArt(
                                    url: widget.song.artworkUrl,
                                    size: 44,
                                    borderRadius: KaivaRadius.sm,
                                    heroTag: 'album_art_${widget.song.id}',
                                  ),
                                ),
                                const SizedBox(width: KaivaSpacing.sm),
                                Expanded(child: _buildTitle()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _LikeButton(songId: widget.song.id),
                        _PlayPauseButton(isPlaying: isPlaying, handler: handler),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 24),
                          color: KaivaColors.textPrimary,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            handler.skipToNext();
                          },
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const _MiniProgressBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final title = widget.song.title;
    final artist = widget.song.artist;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 18,
          child: title.length > 22
              ? Marquee(
                  text: title,
                  style: KaivaTextStyles.labelLarge,
                  scrollAxis: Axis.horizontal,
                  blankSpace: 40,
                  velocity: 30,
                  pauseAfterRound: const Duration(seconds: 2),
                )
              : Text(
                  title,
                  style: KaivaTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        const SizedBox(height: 2),
        Text(
          artist,
          style: KaivaTextStyles.labelSmall.copyWith(
            color: KaivaColors.textSecondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posData = ref.watch(positionDataProvider).valueOrNull;
    final progress = (posData != null &&
            posData.duration != null &&
            posData.duration!.inMilliseconds > 0)
        ? posData.position.inMilliseconds / posData.duration!.inMilliseconds
        : 0.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(KaivaRadius.md),
      ),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 2,
        backgroundColor: KaivaColors.seekBarTrack,
        valueColor: const AlwaysStoppedAnimation(KaivaColors.accentPrimary),
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  final String songId;
  const _LikeButton({required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref
            .watch(
              StreamProvider.autoDispose(
                (r) => r.watch(databaseProvider).likedSongsDao.watchIsLiked(songId),
              ),
            )
            .valueOrNull ??
        false;

    return IconButton(
      icon: Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 22,
      ),
      color: isLiked ? KaivaColors.accentPrimary : KaivaColors.textMuted,
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(databaseProvider).likedSongsDao.toggleLike(songId);
      },
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 20,
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final dynamic handler;
  const _PlayPauseButton({required this.isPlaying, required this.handler});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.isPlaying) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(_PlayPauseButton old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stitch design: solid white-ish circle with dark icon — uses on-surface fill
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.isPlaying ? widget.handler.pause() : widget.handler.play();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: KaivaColors.textPrimary, // on-surface (creamy off-white)
          shape: BoxShape.circle,
        ),
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _anim,
          color: KaivaColors.backgroundPrimary,
          size: 22,
        ),
      ),
    );
  }
}
