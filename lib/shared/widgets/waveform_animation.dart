import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/kaiva_colors.dart';

/// Animated equalizer bars shown next to the currently-playing song.
/// Pass [isPlaying] = false to freeze the bars (paused state).
class WaveformAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color? color;
  final double width;
  final double height;
  final int barCount;

  const WaveformAnimation({
    super.key,
    required this.isPlaying,
    this.color,
    this.width = 20,
    this.height = 16,
    this.barCount = 4,
  });

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _speeds = [320, 450, 280, 380];
  static const _phases = [0.0, 0.4, 0.8, 0.2];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _speeds[i % _speeds.length]),
      );
    });

    _animations = List.generate(widget.barCount, (i) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    _startOrStop();
  }

  void _startOrStop() {
    for (var i = 0; i < _controllers.length; i++) {
      if (widget.isPlaying) {
        Future.delayed(
          Duration(milliseconds: (_phases[i % _phases.length] * 300).round()),
          () {
            if (mounted) _controllers[i].repeat(reverse: true);
          },
        );
      } else {
        _controllers[i].stop();
      }
    }
  }

  @override
  void didUpdateWidget(WaveformAnimation old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) _startOrStop();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? KaivaColors.accentPrimary;
    final barWidth = (widget.width - (widget.barCount - 1) * 2) / widget.barCount;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              final heightFraction = widget.isPlaying
                  ? _animations[i].value
                  : 0.35 + (math.sin(i * 1.2) * 0.15).abs();
              return Container(
                width: barWidth,
                height: widget.height * heightFraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
