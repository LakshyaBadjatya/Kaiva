import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../onboarding_provider.dart';

class LanguagePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LanguagePage({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends ConsumerState<LanguagePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedLanguagesProvider);
    final canContinue = selected.isNotEmpty;

    // Separate Indian and International
    final indian = kOnboardingLanguages.where((l) => l.isIndian).toList();
    final intl   = kOnboardingLanguages.where((l) => !l.isIndian).toList();

    return SafeArea(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — leaves room for back arrow + dots rendered in shell
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What do you\nlisten to?',
                      style: KaivaTextStyles.displayLarge.copyWith(
                        color: KaivaColors.accentBright,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: KaivaSpacing.sm),
                    Text(
                      'Pick your languages — we\'ll tailor your feed.',
                      style: KaivaTextStyles.bodyMedium.copyWith(
                        color: KaivaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Scrollable chip grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Indian Languages'),
                      const SizedBox(height: 12),
                      _LanguageGrid(entries: indian),
                      const SizedBox(height: 24),
                      const _SectionLabel('International'),
                      const SizedBox(height: 12),
                      _LanguageGrid(entries: intl),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              _BottomBar(
                label: canContinue
                    ? 'Continue  →'
                    : 'Select at least one language',
                enabled: canContinue,
                onTap: canContinue ? widget.onNext : null,
                badge: canContinue ? '${selected.length} selected' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: KaivaTextStyles.sectionHeader.copyWith(
        color: KaivaColors.textMuted,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Wrap grid of language chips ───────────────────────────────
class _LanguageGrid extends ConsumerWidget {
  final List<LanguageEntry> entries;
  const _LanguageGrid({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(entries.length, (i) {
        return _LanguageChip(entry: entries[i])
            .animate()
            .fadeIn(delay: (35 * i).ms, duration: 280.ms)
            .slideY(begin: 0.25, curve: Curves.easeOutCubic)
            .scaleXY(begin: 0.9, curve: Curves.easeOutBack);
      }),
    );
  }
}

class _LanguageChip extends ConsumerStatefulWidget {
  final LanguageEntry entry;
  const _LanguageChip({required this.entry});

  @override
  ConsumerState<_LanguageChip> createState() => _LanguageChipState();
}

class _LanguageChipState extends ConsumerState<_LanguageChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        lowerBound: 0.92,
        upperBound: 1.0)
      ..value = 1.0;
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = ref.watch(selectedLanguagesProvider
        .select((s) => s.contains(widget.entry.name)));

    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        HapticFeedback.lightImpact();
        ref.read(selectedLanguagesProvider.notifier).toggle(widget.entry.name);
      },
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? KaivaColors.accentPrimary.withValues(alpha: 0.18)
                : KaivaColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected
                  ? KaivaColors.accentPrimary
                  : KaivaColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.entry.emoji,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                widget.entry.name,
                style: KaivaTextStyles.labelLarge.copyWith(
                  color: isSelected
                      ? KaivaColors.accentBright
                      : KaivaColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_rounded,
                    size: 14, color: KaivaColors.accentBright),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final String? badge;

  const _BottomBar({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: KaivaColors.backgroundPrimary,
        border: const Border(
          top: BorderSide(color: KaivaColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Text(
              badge!,
              style: KaivaTextStyles.bodySmall.copyWith(
                color: KaivaColors.accentBright,
              ),
            ),
            const SizedBox(height: 10),
          ],
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        colors: [KaivaColors.accentBright, KaivaColors.accentDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: enabled ? null : KaivaColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: KaivaTextStyles.labelLarge.copyWith(
                  fontSize: 15,
                  color: enabled
                      ? KaivaColors.textOnAccent
                      : KaivaColors.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
