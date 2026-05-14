import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../../core/models/song.dart';
import '../player_provider.dart';
import '../../../shared/widgets/waveform_animation.dart';
import 'lyrics_view.dart';

class FullscreenArtView extends ConsumerStatefulWidget {
  final Song song;

  const FullscreenArtView({super.key, required this.song});

  @override
  ConsumerState<FullscreenArtView> createState() => _FullscreenArtViewState();
}

class _FullscreenArtViewState extends ConsumerState<FullscreenArtView>
    with SingleTickerProviderStateMixin {
  bool _controlsVisible = true;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );

    _scheduleAutoHide();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _scheduleAutoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controlsVisible) _hideControls();
    });
  }

  void _hideControls() {
    if (!mounted) return;
    _fadeCtrl.reverse();
    setState(() => _controlsVisible = false);
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideControls();
    } else {
      _fadeCtrl.forward();
      setState(() => _controlsVisible = true);
      _scheduleAutoHide();
    }
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    final handler = ref.read(audioHandlerProvider);
    final isPlaying = ref.read(isPlayingProvider);
    isPlaying ? handler.pause() : handler.play();
  }

  void _exit() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider).valueOrNull ?? widget.song;
    final isPlaying = ref.watch(isPlayingProvider);
    final dominantColor =
        ref.watch(dominantColorProvider(song.highResArtworkUrl)).valueOrNull ??
            const Color(0xFF0B0D12);
    final bgColor = Color.lerp(dominantColor, const Color(0xFF000000), 0.55)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-bleed artwork background ──────────────────────
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: song.highResArtworkUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: KaivaColors.backgroundPrimary),
              errorWidget: (_, __, ___) =>
                  Container(color: KaivaColors.backgroundPrimary),
            ),
          ),

          // ── Full screen darkening overlay ──────────────────────
          Positioned.fill(
            child: Container(color: const Color(0x88000000)),
          ),

          // ── Left half: stronger dark scrim ────────────────────
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          bgColor.withValues(alpha: 0.6),
                          bgColor.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right panel: solid dark scrim so text is always legible
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xCC000000),
                  ),
                ),
              ],
            ),
          ),

          // ── Main landscape layout ──────────────────────────────
          SafeArea(
            child: Row(
              children: [
                // Left: album art — tap toggles controls
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleControls,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Hero(
                        tag: 'album_art_${song.id}',
                        child: AnimatedScale(
                          scale: isPlaying ? 1.0 : 0.92,
                          duration: const Duration(milliseconds: 300),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: song.highResArtworkUrl,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Container(
                                color: KaivaColors.backgroundTertiary,
                                child: const Icon(Icons.music_note,
                                    color: KaivaColors.textMuted, size: 80),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: KaivaColors.backgroundTertiary,
                                child: const Icon(Icons.music_note,
                                    color: KaivaColors.textMuted, size: 80),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right: song info + lyrics — tap plays/pauses
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePlayPause,
                    child: Column(
                      children: [
                        // ── Song info header ─────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 36, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.music_note_rounded,
                                      size: 12, color: KaivaColors.accentBright),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PLAYING TRACK',
                                    style: KaivaTextStyles.labelSmall.copyWith(
                                      color: KaivaColors.accentBright,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.title,
                                style: KaivaTextStyles.displayMedium.copyWith(
                                  color: KaivaColors.textPrimary,
                                  shadows: [
                                    const Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (song.artistId.isNotEmpty) {
                                        _exit();
                                        context.push('/artist/${song.artistId}');
                                      }
                                    },
                                    child: Text(
                                      song.artist,
                                      style: KaivaTextStyles.bodyMedium.copyWith(
                                        color: KaivaColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Spacer(),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_filled_rounded,
                                      key: ValueKey(isPlaying),
                                      color: KaivaColors.accentPrimary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _FullscreenWaveform(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Divider(
                          height: 1,
                          color: KaivaColors.borderSubtle,
                          indent: 20,
                          endIndent: 36,
                        ),

                        // ── Lyrics cascade ────────────────────────
                        Expanded(
                          child: LyricsView(
                            key: ValueKey(song.id),
                            songId: song.id,
                            fullscreen: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Back button — always visible, fades with controls ──
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: _exit,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: KaivaColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenWaveform extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    return WaveformAnimation(
      isPlaying: isPlaying,
      width: 44,
      height: 26,
      barCount: 6,
    );
  }
}
