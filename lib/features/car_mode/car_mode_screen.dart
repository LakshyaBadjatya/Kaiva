import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../player/player_provider.dart';

/// Distraction-light, large-target playback UI for driving.
/// Whole screen is swipe-able: left/right = skip, down = exit.
class CarModeScreen extends ConsumerStatefulWidget {
  const CarModeScreen({super.key});

  @override
  ConsumerState<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends ConsumerState<CarModeScreen> {
  double _dragX = 0;
  double _dragY = 0;

  @override
  void initState() {
    super.initState();
    // Keep the screen fully visible & uncluttered while driving.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Car Mode is a landscape dashboard layout.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Restore portrait for the rest of the app.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider);
    final handler = ref.read(audioHandlerProvider);

    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      body: GestureDetector(
        onHorizontalDragUpdate: (d) => _dragX += d.delta.dx,
        onHorizontalDragEnd: (_) {
          if (_dragX < -70) {
            HapticFeedback.mediumImpact();
            handler.skipToNext();
          } else if (_dragX > 70) {
            HapticFeedback.mediumImpact();
            handler.skipToPrevious();
          }
          _dragX = 0;
        },
        onVerticalDragUpdate: (d) => _dragY += d.delta.dy,
        onVerticalDragEnd: (_) {
          if (_dragY > 90) {
            HapticFeedback.mediumImpact();
            context.pop();
          }
          _dragY = 0;
        },
        child: SafeArea(
          child: song == null
              ? _empty(context)
              : _content(context, song, isPlaying, handler),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_rounded,
              size: 64, color: KaivaColors.textMuted),
          const SizedBox(height: 16),
          Text('Nothing playing',
              style: KaivaTextStyles.headlineMedium
                  .copyWith(color: KaivaColors.textSecondary)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Exit Car Mode',
                style: KaivaTextStyles.bodyLarge
                    .copyWith(color: KaivaColors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    Song song,
    bool isPlaying,
    dynamic handler,
  ) {
    final posData = ref.watch(positionDataProvider).valueOrNull;
    final position = posData?.position ?? Duration.zero;
    final duration = posData?.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        // Two-column landscape dashboard: art left · controls right
        Row(
          children: [
            // ── LEFT: album art ──
            Expanded(
              flex: 42,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: song.highResArtworkUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: KaivaColors.backgroundTertiary,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: KaivaColors.backgroundTertiary,
                          child: const Icon(Icons.music_note,
                              color: KaivaColors.textMuted, size: 72),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── RIGHT: info + seek + transport ──
            Expanded(
              flex: 58,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 56, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'NOW PLAYING',
                      style: KaivaTextStyles.sectionHeader
                          .copyWith(color: KaivaColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KaivaTextStyles.displayMedium.copyWith(
                        fontSize: 38,
                        color: KaivaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KaivaTextStyles.headlineMedium.copyWith(
                        fontSize: 22,
                        color: KaivaColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 26),
                    // Seek bar (read-only progress — driving safety)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: KaivaColors.seekBarTrack,
                            valueColor: const AlwaysStoppedAnimation(
                                KaivaColors.accentPrimary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(position),
                                style: KaivaTextStyles.durationLabel),
                            Text(_fmt(duration),
                                style: KaivaTextStyles.durationLabel),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),
                    // Transport — centered, huge targets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundButton(
                          icon: Icons.skip_previous_rounded,
                          size: 88,
                          iconSize: 46,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            handler.skipToPrevious();
                          },
                        ),
                        const SizedBox(width: 30),
                        _RoundButton(
                          icon: isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 116,
                          iconSize: 60,
                          filled: true,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            isPlaying
                                ? handler.pause()
                                : handler.play();
                          },
                        ),
                        const SizedBox(width: 30),
                        _RoundButton(
                          icon: Icons.skip_next_rounded,
                          size: 88,
                          iconSize: 46,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            handler.skipToNext();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Exit button — top-right overlay
        Positioned(
          top: 20,
          right: 24,
          child: _RoundButton(
            icon: Icons.close_rounded,
            size: 56,
            iconSize: 26,
            onTap: () => context.pop(),
          ),
        ),

        // Swipe hint — bottom-right
        Positioned(
          bottom: 18,
          right: 56,
          child: Text(
            'Swipe ←  → to change · swipe down to exit',
            style: KaivaTextStyles.bodySmall
                .copyWith(color: KaivaColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final bool filled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.size,
    this.iconSize = 32,
    this.filled = false,
    required this.onTap,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.filled
                ? KaivaColors.accentPrimary
                : KaivaColors.backgroundTertiary,
            border: widget.filled
                ? null
                : Border.all(color: KaivaColors.borderDefault),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.filled
                ? KaivaColors.textOnAccent
                : KaivaColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
