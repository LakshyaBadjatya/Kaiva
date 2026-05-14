import 'dart:io';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../player/player_provider.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  bool _enabled = false;
  List<String> _presets = [];
  String? _selectedPreset;
  List<int> _freqs = [];
  List<int> _levels = [];
  List<int> _bandRange = [0, 0];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _loadEq();
  }

  Future<void> _loadEq() async {
    try {
      final handler = ref.read(audioHandlerProvider);
      final sessionId = handler.player.androidAudioSessionId ?? 0;
      await EqualizerFlutter.init(sessionId);
      final presets = await EqualizerFlutter.getPresetNames();
      final freqs = await EqualizerFlutter.getCenterBandFreqs();
      final range = await EqualizerFlutter.getBandLevelRange();
      final levels = await Future.wait(
        List.generate(freqs.length, (i) => EqualizerFlutter.getBandLevel(i)),
      );
      if (mounted) {
        setState(() {
          _presets = presets;
          _freqs = freqs;
          _levels = levels;
          _bandRange = range;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer', style: KaivaTextStyles.headlineLarge),
      ),
      body: !Platform.isAndroid
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Equalizer is only supported on Android.',
                  style: KaivaTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _loading
              ? const Center(
                  child: CircularProgressIndicator(color: KaivaColors.accentPrimary),
                )
              : _EqBody(
                  enabled: _enabled,
                  presets: _presets,
                  selectedPreset: _selectedPreset,
                  freqs: _freqs,
                  levels: _levels,
                  bandRange: _bandRange,
                  onToggle: (v) async {
                    await EqualizerFlutter.setEnabled(v);
                    setState(() => _enabled = v);
                  },
                  onPresetChanged: (p) async {
                    await EqualizerFlutter.setPreset(p);
                    setState(() => _selectedPreset = p);
                    // Reload levels after preset change
                    final levels = await Future.wait(
                      List.generate(
                          _freqs.length, (i) => EqualizerFlutter.getBandLevel(i)),
                    );
                    if (mounted) setState(() => _levels = levels);
                  },
                  onBandChanged: (bandId, level) async {
                    await EqualizerFlutter.setBandLevel(bandId, level);
                    final newLevels = List<int>.from(_levels);
                    newLevels[bandId] = level;
                    setState(() => _levels = newLevels);
                  },
                ),
    );
  }
}

class _EqBody extends StatelessWidget {
  final bool enabled;
  final List<String> presets;
  final String? selectedPreset;
  final List<int> freqs;
  final List<int> levels;
  final List<int> bandRange;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onPresetChanged;
  final void Function(int bandId, int level) onBandChanged;

  const _EqBody({
    required this.enabled,
    required this.presets,
    required this.selectedPreset,
    required this.freqs,
    required this.levels,
    required this.bandRange,
    required this.onToggle,
    required this.onPresetChanged,
    required this.onBandChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Enable Equalizer', style: KaivaTextStyles.bodyMedium),
          value: enabled,
          onChanged: onToggle,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(color: KaivaColors.borderSubtle),
        if (presets.isNotEmpty) ...[
          const Text('Preset', style: KaivaTextStyles.sectionHeader),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p),
                          selected: selectedPreset == p,
                          selectedColor: KaivaColors.accentPrimary,
                          backgroundColor: KaivaColors.backgroundTertiary,
                          labelStyle: KaivaTextStyles.chipLabel.copyWith(
                            color: selectedPreset == p
                                ? KaivaColors.textOnAccent
                                : KaivaColors.textSecondary,
                          ),
                          onSelected: (_) => onPresetChanged(p),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Bands', style: KaivaTextStyles.sectionHeader),
        const SizedBox(height: 12),
        if (freqs.isEmpty)
          const Text('No EQ bands available.', style: KaivaTextStyles.bodyMedium)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(freqs.length, (i) {
              final freq = freqs[i];
              final label = freq >= 1000
                  ? '${(freq / 1000).round()}k'
                  : '$freq';
              final level = i < levels.length ? levels[i] : 0;
              final min = bandRange.isNotEmpty ? bandRange.first.toDouble() : -6.0;
              final max = bandRange.length > 1 ? bandRange.last.toDouble() : 6.0;

              return Column(
                children: [
                  Text(
                    '$level',
                    style: KaivaTextStyles.labelSmall,
                  ),
                  SizedBox(
                    height: 160,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: level.toDouble().clamp(min, max),
                        min: min,
                        max: max,
                        activeColor: KaivaColors.accentPrimary,
                        inactiveColor: KaivaColors.backgroundTertiary,
                        onChanged: enabled
                            ? (v) => onBandChanged(i, v.round())
                            : null,
                      ),
                    ),
                  ),
                  Text(label, style: KaivaTextStyles.labelSmall),
                ],
              );
            }),
          ),
      ],
    );
  }
}
