import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';

// TODO: Lakshya will provide custom button design — these are functional placeholders

// ── Primary button ────────────────────────────────────────────
class KaivaPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final IconData? icon;

  const KaivaPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.icon,
  });

  @override
  State<KaivaPrimaryButton> createState() => _KaivaPrimaryButtonState();
}

class _KaivaPrimaryButtonState extends State<KaivaPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.isDisabled || widget.isLoading) return;
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled && !widget.isLoading) _ctrl.reverse();
      },
      onTapUp: (_) {
        _ctrl.forward();
        _onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? KaivaColors.backgroundTertiary
                : KaivaColors.accentPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: KaivaColors.textOnAccent,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.isDisabled
                            ? KaivaColors.textDisabled
                            : KaivaColors.textOnAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: KaivaTextStyles.labelLarge.copyWith(
                        color: widget.isDisabled
                            ? KaivaColors.textDisabled
                            : KaivaColors.textOnAccent,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Secondary (outlined) button ───────────────────────────────
class KaivaSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final IconData? icon;

  const KaivaSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.icon,
  });

  @override
  State<KaivaSecondaryButton> createState() => _KaivaSecondaryButtonState();
}

class _KaivaSecondaryButtonState extends State<KaivaSecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled && !widget.isLoading) _ctrl.reverse();
      },
      onTapUp: (_) {
        _ctrl.forward();
        if (!widget.isDisabled && !widget.isLoading) {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        }
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: widget.isDisabled
                  ? KaivaColors.borderSubtle
                  : KaivaColors.accentPrimary,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: KaivaColors.accentPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.isDisabled
                            ? KaivaColors.textDisabled
                            : KaivaColors.accentPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: KaivaTextStyles.labelLarge.copyWith(
                        color: widget.isDisabled
                            ? KaivaColors.textDisabled
                            : KaivaColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────────────
class KaivaIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool isDisabled;

  const KaivaIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.color,
    this.size = 24,
    this.isDisabled = false,
  });

  @override
  State<KaivaIconButton> createState() => _KaivaIconButtonState();
}

class _KaivaIconButtonState extends State<KaivaIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = ScaleTransition(
      scale: _ctrl,
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isDisabled) _ctrl.reverse();
        },
        onTapUp: (_) {
          _ctrl.forward();
          if (!widget.isDisabled) {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          }
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          width: widget.size + 16,
          height: widget.size + 16,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.isDisabled
                ? KaivaColors.textDisabled
                : (widget.color ?? KaivaColors.textSecondary),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: iconWidget);
    }
    return iconWidget;
  }
}

// ── Play/Pause button ─────────────────────────────────────────
class KaivaPlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const KaivaPlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 64,
  });

  @override
  State<KaivaPlayPauseButton> createState() => _KaivaPlayPauseButtonState();
}

class _KaivaPlayPauseButtonState extends State<KaivaPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    if (widget.isPlaying) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(KaivaPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: KaivaColors.accentPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: KaivaColors.accentGlow,
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
          color: KaivaColors.textOnAccent,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

// ── Chip button ───────────────────────────────────────────────
class KaivaChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const KaivaChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KaivaColors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? KaivaColors.accentPrimary : KaivaColors.borderDefault,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? KaivaColors.textOnAccent : KaivaColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: KaivaTextStyles.chipLabel.copyWith(
                color: isSelected ? KaivaColors.textOnAccent : KaivaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Download button ───────────────────────────────────────────
enum KaivaDownloadState { idle, downloading, downloaded }

class KaivaDownloadButton extends StatefulWidget {
  final KaivaDownloadState downloadState;
  final double progress; // 0.0 – 1.0
  final VoidCallback onTap;

  const KaivaDownloadButton({
    super.key,
    required this.downloadState,
    required this.onTap,
    this.progress = 0,
  });

  @override
  State<KaivaDownloadButton> createState() => _KaivaDownloadButtonState();
}

class _KaivaDownloadButtonState extends State<KaivaDownloadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.downloadState != KaivaDownloadState.downloading) _ctrl.reverse();
      },
      onTapUp: (_) {
        _ctrl.forward();
        if (widget.downloadState != KaivaDownloadState.downloading) {
          HapticFeedback.lightImpact();
          widget.onTap();
        }
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: SizedBox(
          width: 32,
          height: 32,
          child: switch (widget.downloadState) {
            KaivaDownloadState.idle => const Icon(
                Icons.download_outlined,
                color: KaivaColors.textMuted,
                size: 22,
              ),
            KaivaDownloadState.downloading => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: widget.progress > 0 ? widget.progress : null,
                    color: KaivaColors.accentPrimary,
                    strokeWidth: 2,
                  ),
                  const Icon(Icons.close_rounded, size: 12, color: KaivaColors.textMuted),
                ],
              ),
            KaivaDownloadState.downloaded => const Icon(
                Icons.download_done_rounded,
                color: KaivaColors.accentPrimary,
                size: 22,
              ),
          },
        ),
      ),
    );
  }
}

// ── Like button ───────────────────────────────────────────────
class KaivaLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;

  const KaivaLikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 26,
  });

  @override
  State<KaivaLikeButton> createState() => _KaivaLikeButtonState();
}

class _KaivaLikeButtonState extends State<KaivaLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void didUpdateWidget(KaivaLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _burstCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _burstCtrl,
        builder: (context, child) {
          final scale = widget.isLiked
              ? 1.0 + 0.3 * Curves.elasticOut.transform(_burstCtrl.value) * (1 - _burstCtrl.value)
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Icon(
              widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.isLiked ? KaivaColors.error : KaivaColors.textSecondary,
              size: widget.size,
            ),
          );
        },
      ),
    );
  }
}
