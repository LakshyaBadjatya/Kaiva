import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/utils/settings_keys.dart';

/// Bump this to fire a one-shot celebration from anywhere.
final celebrationTriggerProvider = StateProvider<int>((ref) => 0);

/// Fires a confetti burst the very first time the user likes a song.
/// Safe to call on every like — it self-guards via a Hive flag.
void celebrateFirstLikeIfNeeded(WidgetRef ref) {
  final box = Hive.box('kaiva_settings');
  final done =
      box.get(SettingsKeys.firstLikeCelebrated, defaultValue: false) as bool;
  if (done) return;
  box.put(SettingsKeys.firstLikeCelebrated, true);
  ref.read(celebrationTriggerProvider.notifier).state++;
}

/// App-wide confetti layer. Mount once near the root (above the shell).
class CelebrationOverlay extends ConsumerStatefulWidget {
  const CelebrationOverlay({super.key});

  @override
  ConsumerState<CelebrationOverlay> createState() =>
      _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(celebrationTriggerProvider, (prev, next) {
      if (next > (prev ?? 0)) _confetti.play();
    });

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 24,
          maxBlastForce: 22,
          minBlastForce: 8,
          gravity: 0.28,
          colors: const [
            KaivaColors.accentPrimary,
            KaivaColors.accentBright,
            KaivaColors.secondaryAccent,
            KaivaColors.textPrimary,
          ],
        ),
      ),
    );
  }
}
