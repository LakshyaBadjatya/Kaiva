import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../settings/settings_provider.dart';
import 'download_manager.dart';
import 'smart_download.dart';
import 'smart_download_scheduler.dart';

/// Smart Download settings — matches the Stitch "Smart Download" mockup.
class SmartDownloadScreen extends ConsumerStatefulWidget {
  const SmartDownloadScreen({super.key});

  @override
  ConsumerState<SmartDownloadScreen> createState() =>
      _SmartDownloadScreenState();
}

class _SmartDownloadScreenState
    extends ConsumerState<SmartDownloadScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    HapticFeedback.mediumImpact();
    final result =
        await ref.read(smartDownloadProvider).sync(force: true);
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Sync complete',
            style: KaivaTextStyles.bodySmall),
        backgroundColor: KaivaColors.backgroundElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _applyScheduler() async {
    final enabled = ref.read(smartDownloadEnabledProvider);
    final wifi = ref.read(smartDownloadWifiOnlyProvider);
    if (enabled) {
      await SmartDownloadScheduler.instance.enablePeriodic(wifiOnly: wifi);
    } else {
      await SmartDownloadScheduler.instance.disablePeriodic();
    }
  }

  String _fmtLastRun(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return sameDay ? 'Today $hh:$mm' : '${dt.day}/${dt.month} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(smartDownloadEnabledProvider);
    final liked = ref.watch(smartDownloadLikedProvider);
    final mostPlayed = ref.watch(smartDownloadMostPlayedProvider);
    final wifiOnly = ref.watch(smartDownloadWifiOnlyProvider);
    final maxSongs = ref.watch(smartDownloadMaxSongsProvider);
    final storage = ref.watch(storageInfoProvider).valueOrNull;
    final downloadedCount =
        ref.watch(downloadedSongsProvider).valueOrNull?.length ?? 0;
    final lastRun = ref.read(smartDownloadProvider).lastRun;

    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Smart Download',
            style: KaivaTextStyles.headlineLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          Text('Smart Download',
                  style:
                      KaivaTextStyles.displayMedium.copyWith(fontSize: 32))
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.15),
          const SizedBox(height: 6),
          Text(
            'Keep your favourites offline, automatically.',
            style: KaivaTextStyles.bodyMedium
                .copyWith(color: KaivaColors.textSecondary),
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 24),

          // ── Hero enable card ────────────────────────────────
          _GlassCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: KaivaColors.accentGlow,
                  ),
                  child: const Icon(Icons.cloud_download_rounded,
                      color: KaivaColors.accentPrimary, size: 26),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Enable Smart Download',
                      style: KaivaTextStyles.titleMedium),
                ),
                Switch(
                  value: enabled,
                  activeColor: KaivaColors.textOnAccent,
                  activeTrackColor: KaivaColors.accentPrimary,
                  onChanged: (v) async {
                    HapticFeedback.lightImpact();
                    ref
                        .read(smartDownloadEnabledProvider.notifier)
                        .set(v);
                    await _applyScheduler();
                  },
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          // ── Storage status card with ring ───────────────────
          _GlassCard(
            child: Row(
              children: [
                _StorageRing(
                  fraction: storage == null || storage.totalBytes == 0
                      ? 0
                      : (storage.kaivaUsedBytes / storage.totalBytes)
                          .clamp(0.0, 1.0),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$downloadedCount songs downloaded',
                          style: KaivaTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        storage == null
                            ? '—'
                            : '${storage.kaivaFormatted} used · ${storage.freeFormatted} free',
                        style: KaivaTextStyles.bodySmall
                            .copyWith(color: KaivaColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // ── Settings list ───────────────────────────────────
          _ToggleCard(
            title: 'Download liked songs',
            subtitle: 'Automatically save your likes',
            value: liked,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              ref.read(smartDownloadLikedProvider.notifier).set(v);
            },
          ).animate(delay: 260.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Download most-played',
            subtitle: 'Keep your daily hits ready',
            value: mostPlayed,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              ref
                  .read(smartDownloadMostPlayedProvider.notifier)
                  .set(v);
            },
          ).animate(delay: 300.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Wi-Fi only',
            subtitle: 'Save data on the go',
            value: wifiOnly,
            onChanged: (v) async {
              HapticFeedback.lightImpact();
              ref
                  .read(smartDownloadWifiOnlyProvider.notifier)
                  .set(v);
              await _applyScheduler();
            },
          ).animate(delay: 340.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 12),

          // Max songs stepper
          _GlassCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max songs',
                          style: KaivaTextStyles.titleMedium),
                      SizedBox(height: 2),
                      Text('Storage limit',
                          style: KaivaTextStyles.bodySmall),
                    ],
                  ),
                ),
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final v = (maxSongs - 10).clamp(10, 500);
                    ref
                        .read(smartDownloadMaxSongsProvider.notifier)
                        .set(v);
                  },
                ),
                SizedBox(
                  width: 48,
                  child: Text('$maxSongs',
                      textAlign: TextAlign.center,
                      style: KaivaTextStyles.titleMedium
                          .copyWith(color: KaivaColors.accentBright)),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    final v = (maxSongs + 10).clamp(10, 500);
                    ref
                        .read(smartDownloadMaxSongsProvider.notifier)
                        .set(v);
                  },
                ),
              ],
            ),
          ).animate(delay: 380.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 12),

          // Run overnight + Sync now
          _GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Run overnight',
                          style: KaivaTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text('Last run: ${_fmtLastRun(lastRun)}',
                          style: KaivaTextStyles.bodySmall
                              .copyWith(color: KaivaColors.textMuted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _syncing ? null : _syncNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: KaivaColors.accentPrimary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KaivaColors.textOnAccent,
                            ),
                          )
                        : const Text('Sync now',
                            style: TextStyle(
                              color: KaivaColors.textOnAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                  ),
                ),
              ],
            ),
          ).animate(delay: 420.ms).fadeIn(duration: 350.ms),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(KaivaRadius.lg),
        border: Border.all(color: KaivaColors.borderSubtle),
      ),
      child: child,
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KaivaColors.backgroundTertiary,
          border: Border.all(color: KaivaColors.borderDefault),
        ),
        child: Icon(icon, size: 18, color: KaivaColors.textPrimary),
      ),
    );
  }
}

class _StorageRing extends StatelessWidget {
  final double fraction;
  const _StorageRing({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, value, __) => CustomPaint(
          painter: _RingPainter(value),
          child: Center(
            child: Text(
              '${(value * 100).round()}%',
              style: KaivaTextStyles.labelSmall
                  .copyWith(color: KaivaColors.accentBright),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  _RingPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final track = Paint()
      ..color = KaivaColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final arc = Paint()
      ..color = KaivaColors.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * fraction,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
