import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../player/player_provider.dart';
import '../settings_provider.dart';

/// Crossfade settings — matches the Stitch "Crossfade Settings" mockup
/// (Editorial Noir). Hero duration card, auto-tune feature card with a
/// blended-waveform visual, how-it-works, preview, gapless / normalize.
class CrossfadeScreen extends ConsumerWidget {
  const CrossfadeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossfade = ref.watch(crossfadeProvider);
    final autoTune = ref.watch(autoTuneCrossfadeProvider);
    final gapless = ref.watch(gaplessPlaybackProvider);
    final normalize = ref.watch(volumeNormalizeProvider);
    final handler = ref.read(audioHandlerProvider);

    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Crossfade', style: KaivaTextStyles.headlineLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          Text(
            'Crossfade',
            style: KaivaTextStyles.displayMedium.copyWith(fontSize: 34),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15),
          const SizedBox(height: 6),
          Text(
            'Seamless transitions between tracks.',
            style: KaivaTextStyles.bodyMedium
                .copyWith(color: KaivaColors.textSecondary),
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 28),

          // ── Hero duration card ──────────────────────────────
          _GlassCard(
            child: Column(
              children: [
                Text(
                  crossfade == 0 ? 'Off' : '${crossfade}s',
                  style: KaivaTextStyles.displayMedium.copyWith(
                    fontSize: 56,
                    color: KaivaColors.accentBright,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Crossfade duration',
                    style: KaivaTextStyles.labelMedium
                        .copyWith(color: KaivaColors.textMuted)),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: KaivaColors.accentPrimary,
                    inactiveTrackColor: KaivaColors.borderSubtle,
                    thumbColor: KaivaColors.accentBright,
                    overlayColor: KaivaColors.accentGlow,
                    trackHeight: 6,
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: crossfade.toDouble(),
                    min: 0,
                    max: 12,
                    divisions: 12,
                    onChanged: (v) {
                      final secs = v.round();
                      ref.read(crossfadeProvider.notifier).set(secs);
                      handler.setCrossfade(secs);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0s',
                        style: KaivaTextStyles.labelSmall
                            .copyWith(color: KaivaColors.textMuted)),
                    Text('12s',
                        style: KaivaTextStyles.labelSmall
                            .copyWith(color: KaivaColors.textMuted)),
                  ],
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: 0.12),
          const SizedBox(height: 16),

          // ── Auto-tune feature card ──────────────────────────
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Auto-tune crossfade',
                          style: KaivaTextStyles.titleMedium),
                    ),
                    Switch(
                      value: autoTune,
                      activeColor: KaivaColors.textOnAccent,
                      activeTrackColor: KaivaColors.accentPrimary,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        ref
                            .read(autoTuneCrossfadeProvider.notifier)
                            .set(v);
                        handler.setAutoTuneCrossfade(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kaiva analyses each track\'s silence and adjusts the '
                  'crossfade automatically for a perfect blend.',
                  style: KaivaTextStyles.bodySmall
                      .copyWith(color: KaivaColors.textSecondary),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BlendWaveformPainter(active: autoTune),
                  ),
                ),
              ],
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 400.ms).slideY(begin: 0.12),
          const SizedBox(height: 16),

          // ── How it works ────────────────────────────────────
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOW IT WORKS',
                    style: KaivaTextStyles.labelSmall.copyWith(
                      color: KaivaColors.textMuted,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 14),
                _Step(
                    icon: Icons.graphic_eq_rounded,
                    text: 'Scans track endings'),
                _Step(
                    icon: Icons.volume_off_rounded,
                    text: 'Detects trailing silence'),
                _Step(
                    icon: Icons.tune_rounded,
                    text: 'Tunes the blend per song',
                    last: true),
              ],
            ),
          ).animate(delay: 280.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // ── Toggle cards ────────────────────────────────────
          _ToggleCard(
            title: 'Gapless playback',
            subtitle: 'No silence between tracks',
            value: gapless,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              ref.read(gaplessPlaybackProvider.notifier).set(v);
              handler.setGapless(v);
            },
          ).animate(delay: 320.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Volume normalization',
            subtitle: 'Even loudness across tracks',
            value: normalize,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              ref.read(volumeNormalizeProvider.notifier).set(v);
            },
          ).animate(delay: 360.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(KaivaRadius.lg),
        border: Border.all(color: KaivaColors.borderSubtle),
      ),
      child: child,
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool last;
  const _Step({required this.icon, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KaivaColors.accentGlow,
            ),
            child: Icon(icon, size: 18, color: KaivaColors.accentPrimary),
          ),
          const SizedBox(width: 14),
          Text(text,
              style: KaivaTextStyles.bodyMedium
                  .copyWith(color: KaivaColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KaivaTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: KaivaTextStyles.bodySmall
                        .copyWith(color: KaivaColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: KaivaColors.textOnAccent,
            activeTrackColor: KaivaColors.accentPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Two overlapping amber waveforms that visually blend at the centre —
/// the "auto-tune" feature visual from the mockup.
class _BlendWaveformPainter extends CustomPainter {
  final bool active;
  _BlendWaveformPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final baseColor = active
        ? KaivaColors.accentPrimary
        : KaivaColors.textMuted.withValues(alpha: 0.5);

    void wave(double phase, double dir, double opacity) {
      final paint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (double x = 0; x <= size.width; x += 3) {
        // Envelope: each wave fades toward the opposite edge so they
        // visually cross-blend in the middle.
        final t = x / size.width;
        final env = dir > 0 ? (1 - t) : t;
        final amp = (size.height * 0.34) * env;
        final y = mid +
            sin((x / size.width) * pi * 8 + phase) * amp;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    wave(0, 1, 0.95); // outgoing track (fades right)
    wave(pi / 2, -1, 0.7); // incoming track (fades left)
  }

  @override
  bool shouldRepaint(_BlendWaveformPainter old) => old.active != active;
}
