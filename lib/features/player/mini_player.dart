import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marquee/marquee.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/models/song.dart';
import '../../shared/widgets/album_art.dart';
import 'player_provider.dart';

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
    // Only watch isPlaying here — NOT positionDataProvider
    final isPlaying = ref.watch(isPlayingProvider);
    final handler = ref.read(audioHandlerProvider);

    return GestureDetector(
      onTap: () => context.push('/player'),
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
          context.push('/player');
        }
      },
      onHorizontalDragUpdate: (d) => _dragDeltaX += d.delta.dx,
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
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1E34), Color(0xFF12151C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
          border: Border.fromBorderSide(
              BorderSide(color: KaivaColors.borderDefault, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Color(0x407C6EF0),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    AlbumArt(
                      url: widget.song.artworkUrl,
                      size: 48,
                      borderRadius: 8,
                      heroTag: 'album_art_${widget.song.id}',
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTitle()),
                    _LikeButton(songId: widget.song.id),
                    _PlayPauseButton(isPlaying: isPlaying, handler: handler),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 22),
                      color: KaivaColors.textSecondary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        handler.skipToNext();
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ),
            // Progress bar is a separate leaf widget — only it rebuilds on ticks
            const _MiniProgressBar(),
          ],
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
          height: 20,
          child: title.length > 22
              ? Marquee(
                  text: title,
                  style: KaivaTextStyles.titleMedium,
                  scrollAxis: Axis.horizontal,
                  blankSpace: 40,
                  velocity: 30,
                  pauseAfterRound: const Duration(seconds: 2),
                )
              : Text(title,
                  style: KaivaTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 2),
        Text(
          artist,
          style: KaivaTextStyles.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Isolated progress bar — only this widget rebuilds every tick ──
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
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 2,
        backgroundColor: KaivaColors.seekBarTrack,
        valueColor: const AlwaysStoppedAnimation(KaivaColors.accentPrimary),
      ),
    );
  }
}

// ── Like button ───────────────────────────────────────────────
class _LikeButton extends ConsumerWidget {
  final String songId;
  const _LikeButton({required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.favorite_border, size: 20),
      color: KaivaColors.textMuted,
      onPressed: () => HapticFeedback.lightImpact(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

// ── Play/pause button ─────────────────────────────────────────
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
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _anim,
        color: KaivaColors.textPrimary,
        size: 26,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.isPlaying ? widget.handler.pause() : widget.handler.play();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
