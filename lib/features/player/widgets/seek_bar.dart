import 'package:flutter/material.dart';
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

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final posData = ref.watch(positionDataProvider).valueOrNull;
    final handler = ref.read(audioHandlerProvider);

    final position = _draggingValue != null
        ? Duration(milliseconds: _draggingValue!.toInt())
        : (posData?.position ?? Duration.zero);
    final duration = posData?.duration ?? Duration.zero;

    final maxMs = duration.inMilliseconds.toDouble();
    final posMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: KaivaColors.accentPrimary,
            inactiveTrackColor: KaivaColors.seekBarTrack,
            thumbColor: KaivaColors.seekBarThumb,
            overlayColor: KaivaColors.accentGlow,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: maxMs > 0 ? posMs / maxMs : 0,
            onChangeStart: (_) => setState(() => _draggingValue = posMs),
            onChanged: (v) => setState(
              () => _draggingValue = (v * maxMs).clamp(0.0, maxMs),
            ),
            onChangeEnd: (v) {
              handler.seek(Duration(milliseconds: (v * maxMs).toInt()));
              setState(() => _draggingValue = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position), style: KaivaTextStyles.durationLabel),
              Text(_fmt(duration), style: KaivaTextStyles.durationLabel),
            ],
          ),
        ),
      ],
    );
  }
}
