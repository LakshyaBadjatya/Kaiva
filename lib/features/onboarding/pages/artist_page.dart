import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../onboarding_provider.dart';

class ArtistPage extends ConsumerStatefulWidget {
  final Future<void> Function() onFinish;
  final VoidCallback onBack;

  const ArtistPage({super.key, required this.onFinish, required this.onBack});

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _isFinishing = false;

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

  Future<void> _handleFinish() async {
    setState(() => _isFinishing = true);
    try {
      await widget.onFinish();
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguages = ref.watch(selectedLanguagesProvider);
    final selectedArtists   = ref.watch(selectedArtistsProvider);
    final artists           = sortedArtistsFor(selectedLanguages);
    final canFinish         = selectedArtists.length >= 3;

    return SafeArea(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Space for shell's back arrow + dots
              const SizedBox(height: 64),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick your\nfavourite artists.',
                      style: KaivaTextStyles.displayLarge.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose 3 or more to personalise your home.',
                      style: KaivaTextStyles.bodyMedium.copyWith(
                        color: KaivaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language group labels hint
              if (selectedLanguages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 8),
                  child: Text(
                    '${selectedLanguages.first} artists first · more below',
                    style: KaivaTextStyles.bodySmall.copyWith(
                      color: KaivaColors.accentBright.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ),

              // Artist grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (ctx, i) {
                    return _ArtistCard(
                      artist: artists[i],
                      animIndex: i,
                    );
                  },
                ),
              ),

              // Bottom CTA
              _FinishBar(
                selectedCount: selectedArtists.length,
                canFinish: canFinish,
                isLoading: _isFinishing,
                onTap: canFinish && !_isFinishing ? _handleFinish : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Artist card ───────────────────────────────────────────────
class _ArtistCard extends ConsumerStatefulWidget {
  final ArtistEntry artist;
  final int animIndex;

  const _ArtistCard({required this.artist, required this.animIndex});

  @override
  ConsumerState<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends ConsumerState<_ArtistCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.90,
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
    final isSelected = ref.watch(selectedArtistsProvider
        .select((s) => s.contains(widget.artist.id)));

    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        HapticFeedback.selectionClick();
        ref.read(selectedArtistsProvider.notifier).toggle(widget.artist.id);
      },
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: Column(
          children: [
            // Avatar with selection ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.all(isSelected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [KaivaColors.accentBright, KaivaColors.accentDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Container(
                padding: EdgeInsets.all(isSelected ? 2 : 0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KaivaColors.backgroundSecondary,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child: CachedNetworkImage(
                      imageUrl: widget.artist.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: KaivaColors.backgroundTertiary,
                        child: const Icon(Icons.person_rounded,
                            color: KaivaColors.textMuted, size: 36),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: KaivaColors.backgroundTertiary,
                        child: Center(
                          child: Text(
                            widget.artist.name[0],
                            style: KaivaTextStyles.displayMedium.copyWith(
                              color: KaivaColors.accentPrimary,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              widget.artist.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KaivaTextStyles.labelLarge.copyWith(
                fontSize: 12,
                color: isSelected
                    ? KaivaColors.accentBright
                    : KaivaColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

            // Check badge
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle_rounded,
                    size: 16, color: KaivaColors.accentBright),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Finish bar ────────────────────────────────────────────────
class _FinishBar extends StatelessWidget {
  final int selectedCount;
  final bool canFinish;
  final bool isLoading;
  final VoidCallback? onTap;

  const _FinishBar({
    required this.selectedCount,
    required this.canFinish,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - selectedCount;
    final String label = canFinish
        ? 'Start listening  🎵'
        : remaining == 1
            ? 'Select 1 more artist'
            : 'Select $remaining more artists';

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: KaivaColors.backgroundPrimary,
        border: const Border(
            top: BorderSide(color: KaivaColors.borderSubtle, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0) ...[
            Text(
              '$selectedCount artist${selectedCount == 1 ? '' : 's'} selected',
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
                gradient: canFinish
                    ? const LinearGradient(
                        colors: [KaivaColors.accentBright, KaivaColors.accentDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canFinish ? null : KaivaColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(KaivaColors.textOnAccent),
                      ),
                    )
                  : Text(
                      label,
                      style: KaivaTextStyles.labelLarge.copyWith(
                        fontSize: 15,
                        color: canFinish
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
