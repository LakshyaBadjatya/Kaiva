import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../player_provider.dart';
import 'sleep_timer_sheet.dart';

class PlayerControls extends ConsumerStatefulWidget {
  const PlayerControls({super.key});

  @override
  ConsumerState<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends ConsumerState<PlayerControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playPauseCtrl;
  late final Animation<double> _playPauseAnim;

  @override
  void initState() {
    super.initState();
    _playPauseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _playPauseAnim =
        CurvedAnimation(parent: _playPauseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _playPauseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final loopMode = ref.watch(loopModeProvider).valueOrNull ?? LoopMode.off;
    final shuffle = ref.watch(shuffleProvider).valueOrNull ?? false;
    final handler = ref.read(audioHandlerProvider);

    if (isPlaying) {
      _playPauseCtrl.forward();
    } else {
      _playPauseCtrl.reverse();
    }

    // Editorial Noir layout: shuffle | replay_10 prev BIG_PLAY next forward_10 | repeat
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ShuffleButton(shuffle: shuffle, handler: handler),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(
                icon: Icons.replay_10_rounded,
                size: 28,
                onTap: () {
                  HapticFeedback.lightImpact();
                  handler.customAction('seekBackward10');
                },
              ),
              const SizedBox(width: 16),
              _iconBtn(
                icon: Icons.skip_previous_rounded,
                size: 40,
                onTap: () {
                  HapticFeedback.lightImpact();
                  handler.skipToPrevious();
                },
              ),
              const SizedBox(width: 16),
              _PlayPauseCircle(
                isPlaying: isPlaying,
                anim: _playPauseAnim,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  isPlaying ? handler.pause() : handler.play();
                },
              ),
              const SizedBox(width: 16),
              _iconBtn(
                icon: Icons.skip_next_rounded,
                size: 40,
                onTap: () {
                  HapticFeedback.lightImpact();
                  handler.skipToNext();
                },
              ),
              const SizedBox(width: 16),
              _iconBtn(
                icon: Icons.forward_10_rounded,
                size: 28,
                onTap: () {
                  HapticFeedback.lightImpact();
                  handler.customAction('seekForward10');
                },
              ),
            ],
          ),
          _RepeatButton(loopMode: loopMode, handler: handler),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Icon(icon, color: KaivaColors.textSecondary, size: size),
    );
  }
}

class _PlayPauseCircle extends StatelessWidget {
  final bool isPlaying;
  final Animation<double> anim;
  final VoidCallback onTap;

  const _PlayPauseCircle({
    required this.isPlaying,
    required this.anim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: KaivaColors.accentPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x66EF9F27),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: anim,
            color: KaivaColors.textOnAccent,
            size: 44,
          ),
        ),
      ),
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  final bool shuffle;
  final dynamic handler;
  const _ShuffleButton({required this.shuffle, required this.handler});

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        handler.setShuffleMode(
          shuffle
              ? AudioServiceShuffleMode.none
              : AudioServiceShuffleMode.all,
        );
      },
      child: Icon(
        Icons.shuffle_rounded,
        color: shuffle ? KaivaColors.accentPrimary : KaivaColors.textMuted,
        size: 22,
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final LoopMode loopMode;
  final dynamic handler;
  const _RepeatButton({required this.loopMode, required this.handler});

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        final next = switch (loopMode) {
          LoopMode.off => AudioServiceRepeatMode.all,
          LoopMode.all => AudioServiceRepeatMode.one,
          LoopMode.one => AudioServiceRepeatMode.none,
        };
        handler.setRepeatMode(next);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            loopMode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: loopMode == LoopMode.off
                ? KaivaColors.textMuted
                : KaivaColors.accentPrimary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _SleepTimerButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(sleepTimerActiveProvider);
    return _ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SleepTimerSheet(),
        );
      },
      child: Icon(
        Icons.bedtime_outlined,
        color: isActive ? KaivaColors.accentPrimary : KaivaColors.textMuted,
        size: 22,
      ),
    );
  }
}

// Reusable scale-on-press wrapper
class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleOnTap({required this.child, required this.onTap});

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
