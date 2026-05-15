import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../player_provider.dart';

class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key});

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _draggingValue;
  int _lastHapticBucket = -1;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _hapticTick(double fraction) {
    // Light selection click roughly every 5% scrubbed.
    final bucket = (fraction * 20).floor();
    if (bucket != _lastHapticBucket) {
      _lastHapticBucket = bucket;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final posData = ref.watch(positionDataProvider).valueOrNull;

    final duration = posData?.duration ?? Duration.zero;
    final maxMs = duration.inMilliseconds.toDouble();

    final position = _draggingValue != null
        ? Duration(milliseconds: _draggingValue!.toInt())
        : (posData?.position ?? Duration.zero);
    final posMs = position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);
    final bufferedMs = (posData?.bufferedPosition.inMilliseconds.toDouble() ?? 0)
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    final isDragging = _draggingValue != null;
    final bufferedFraction = maxMs > 0 ? bufferedMs / maxMs : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: KaivaColors.accentPrimary,
            inactiveTrackColor: Colors.transparent,
            thumbColor: KaivaColors.accentPrimary,
            overlayColor: KaivaColors.accentGlow,
            trackHeight: 4,
            thumbShape: _GlowThumbShape(
              radius: isDragging ? 8 : 4,
              glow: isDragging,
            ),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 18),
            trackShape: _BufferedTrackShape(
              bufferedFraction: bufferedFraction,
            ),
          ),
          child: Slider(
            value: maxMs > 0 ? posMs / maxMs : 0,
            onChangeStart: (_) => setState(() {
              _draggingValue = posMs;
              _lastHapticBucket = -1;
            }),
            onChanged: (v) {
              _hapticTick(v);
              setState(
                  () => _draggingValue = (v * maxMs).clamp(0.0, maxMs));
            },
            onChangeEnd: (v) {
              HapticFeedback.lightImpact();
              ref
                  .read(audioHandlerProvider)
                  .seek(Duration(milliseconds: (v * maxMs).toInt()));
              setState(() => _draggingValue = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position),
                  style: KaivaTextStyles.durationLabel),
              Text(_fmt(duration),
                  style: KaivaTextStyles.durationLabel),
            ],
          ),
        ),
      ],
    );
  }
}

/// Track that renders: base (subtle) → buffered (muted) → active (sand).
class _BufferedTrackShape extends RoundedRectSliderTrackShape {
  final double bufferedFraction;
  const _BufferedTrackShape({required this.bufferedFraction});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Rect rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    final canvas = context.canvas;

    // Base track
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = KaivaColors.borderSubtle,
    );

    // Buffered portion
    if (bufferedFraction > 0) {
      final bufRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * bufferedFraction.clamp(0.0, 1.0),
        rect.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bufRect, radius),
        Paint()..color = KaivaColors.textMuted.withValues(alpha: 0.4),
      );
    }

    // Active portion
    final activeRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      thumbCenter.dx,
      rect.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, radius),
      Paint()..color = KaivaColors.accentPrimary,
    );
  }
}

/// Thumb with an optional amber glow halo while scrubbing.
class _GlowThumbShape extends SliderComponentShape {
  final double radius;
  final bool glow;
  const _GlowThumbShape({required this.radius, required this.glow});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    if (glow) {
      canvas.drawCircle(
        center,
        radius + 9,
        Paint()
          ..color = KaivaColors.accentPrimary.withValues(alpha: 0.28)
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    if (radius > 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = KaivaColors.accentPrimary,
      );
    }
  }
}
