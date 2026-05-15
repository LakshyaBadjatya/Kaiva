import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../audio_handler.dart';
import '../player_provider.dart';

// ── Sleep timer service ───────────────────────────────────────
enum SleepTimerOption {
  min5, min10, min15, min30, hour1, endOfTrack, custom,
}

extension SleepTimerOptionLabel on SleepTimerOption {
  String get label => switch (this) {
    SleepTimerOption.min5       => '5 minutes',
    SleepTimerOption.min10      => '10 minutes',
    SleepTimerOption.min15      => '15 minutes',
    SleepTimerOption.min30      => '30 minutes',
    SleepTimerOption.hour1      => '1 hour',
    SleepTimerOption.endOfTrack => 'End of track',
    SleepTimerOption.custom     => 'Custom',
  };

  Duration? get duration => switch (this) {
    SleepTimerOption.min5       => const Duration(minutes: 5),
    SleepTimerOption.min10      => const Duration(minutes: 10),
    SleepTimerOption.min15      => const Duration(minutes: 15),
    SleepTimerOption.min30      => const Duration(minutes: 30),
    SleepTimerOption.hour1      => const Duration(hours: 1),
    _                           => null,
  };
}

class SleepTimerService {
  Timer? _timer;
  StreamController<Duration>? _remainingCtrl;
  Timer? _countdownTick;
  Duration _remaining = Duration.zero;

  Stream<Duration> get remainingStream =>
      _remainingCtrl?.stream ?? const Stream.empty();

  bool get isActive => _timer?.isActive ?? false;

  void start(Duration duration, KaivaAudioHandler handler) {
    cancel();
    _remaining = duration;
    _remainingCtrl = StreamController<Duration>.broadcast();
    _remainingCtrl!.add(_remaining);

    _countdownTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _remaining -= const Duration(seconds: 1);
      _remainingCtrl?.add(_remaining);
      if (_remaining <= Duration.zero) {
        cancel();
        handler.stop();
      }
    });

    _timer = Timer(duration, () {
      handler.stop();
      cancel();
    });
  }

  void startEndOfTrack(KaivaAudioHandler handler) {
    cancel();
    // Listen to playback state — pause when next track would start
    _remaining = const Duration(seconds: -1); // sentinel for "end of track"
    _remainingCtrl = StreamController<Duration>.broadcast();
    _remainingCtrl!.add(const Duration(seconds: -1));
    // Mark handler so it stops after current track completes
    handler.stopAfterCurrentTrack = true;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _countdownTick?.cancel();
    _countdownTick = null;
    _remainingCtrl?.close();
    _remainingCtrl = null;
  }
}

final sleepTimerServiceProvider = Provider<SleepTimerService>(
  (ref) {
    final s = SleepTimerService();
    ref.onDispose(s.cancel);
    return s;
  },
);

final sleepTimerActiveProvider = StateProvider<bool>((ref) => false);
final sleepTimerRemainingProvider = StateProvider<Duration>((ref) => Duration.zero);
// Total configured duration — used to draw the countdown ring.
final sleepTimerTotalProvider = StateProvider<Duration>((ref) => Duration.zero);

// ── Sheet UI ──────────────────────────────────────────────────
class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  double _customMinutes = 30;
  bool _showCustom = false;

  void _start(Duration duration) {
    final handler = ref.read(audioHandlerProvider);
    final service = ref.read(sleepTimerServiceProvider);
    service.start(duration, handler);
    ref.read(sleepTimerActiveProvider.notifier).state = true;
    ref.read(sleepTimerTotalProvider.notifier).state = duration;

    // Update remaining countdown
    service.remainingStream.listen((d) {
      if (mounted) {
        ref.read(sleepTimerRemainingProvider.notifier).state = d;
      }
    });

    Navigator.of(context).pop();
  }

  void _startEndOfTrack() {
    final handler = ref.read(audioHandlerProvider);
    final service = ref.read(sleepTimerServiceProvider);
    service.startEndOfTrack(handler);
    ref.read(sleepTimerActiveProvider.notifier).state = true;
    Navigator.of(context).pop();
  }

  void _cancel() {
    final service = ref.read(sleepTimerServiceProvider);
    service.cancel();
    ref.read(sleepTimerActiveProvider.notifier).state = false;
    ref.read(sleepTimerTotalProvider.notifier).state = Duration.zero;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(sleepTimerActiveProvider);
    final remaining = ref.watch(sleepTimerRemainingProvider);

    return Container(
      decoration: const BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: KaivaColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.bedtime_outlined, color: KaivaColors.accentPrimary),
              const SizedBox(width: 10),
              const Text('Sleep Timer', style: KaivaTextStyles.headlineMedium),
              const Spacer(),
              if (isActive)
                Text(
                  _formatRemaining(remaining),
                  style: KaivaTextStyles.bodyMedium.copyWith(
                    color: KaivaColors.accentPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isActive)
            _OptionRow(
              label: 'Cancel timer',
              icon: Icons.timer_off_outlined,
              isDestructive: true,
              onTap: _cancel,
            ),
          const Divider(color: KaivaColors.borderSubtle, height: 1),
          for (final opt in SleepTimerOption.values.where(
              (o) => o != SleepTimerOption.custom && o != SleepTimerOption.endOfTrack))
            _OptionRow(
              label: opt.label,
              icon: Icons.timer_outlined,
              onTap: () => _start(opt.duration!),
            ),
          _OptionRow(
            label: SleepTimerOption.endOfTrack.label,
            icon: Icons.skip_next_outlined,
            onTap: _startEndOfTrack,
          ),
          _OptionRow(
            label: 'Custom',
            icon: Icons.tune_outlined,
            onTap: () => setState(() => _showCustom = !_showCustom),
          ),
          if (_showCustom) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _customMinutes,
                      min: 1,
                      max: 120,
                      divisions: 119,
                      activeColor: KaivaColors.accentPrimary,
                      inactiveColor: KaivaColors.backgroundTertiary,
                      onChanged: (v) => setState(() => _customMinutes = v),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${_customMinutes.round()} min',
                      style: KaivaTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => _start(Duration(minutes: _customMinutes.round())),
              style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary,
                foregroundColor: KaivaColors.textOnAccent,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Start ${_customMinutes.round()} min timer'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inSeconds < 0) return 'End of track';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? KaivaColors.error : KaivaColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: KaivaTextStyles.bodyMedium.copyWith(color: color)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
