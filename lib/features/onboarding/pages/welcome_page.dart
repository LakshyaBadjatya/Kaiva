import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../../core/firebase/firebase_service.dart';

class WelcomePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const WelcomePage({super.key, required this.onNext});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseService.instance.signInWithGoogle();
      widget.onNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}',
                style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textPrimary)),
            backgroundColor: KaivaColors.backgroundElevated,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo / wordmark
                _LogoMark(),

                const SizedBox(height: 40),

                // Editorial Noir display headline (Playfair, warm sand)
                Text(
                  'Your music,\nyour vibe.',
                  textAlign: TextAlign.center,
                  style: KaivaTextStyles.displayLarge.copyWith(
                    color: KaivaColors.accentBright,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: KaivaSpacing.md),
                Text(
                  'Millions of songs across every\nIndian language and beyond.',
                  textAlign: TextAlign.center,
                  style: KaivaTextStyles.bodyLarge.copyWith(
                    color: KaivaColors.textSecondary,
                    fontSize: 16,
                  ),
                ),

                const Spacer(flex: 3),

                // Sign-in buttons
                _SignInButton(
                  onTap: _isLoading ? null : _signInWithGoogle,
                  isLoading: _isLoading,
                  icon: _GoogleIcon(),
                  label: 'Continue with Google',
                  filled: true,
                ),
                const SizedBox(height: 12),
                _SignInButton(
                  onTap: _isLoading ? null : widget.onNext,
                  icon: const Icon(Icons.email_outlined,
                      size: 20, color: KaivaColors.textPrimary),
                  label: 'Continue with Email',
                  filled: false,
                ),

                const SizedBox(height: 28),

                // Skip / browse anonymously
                GestureDetector(
                  onTap: _isLoading ? null : widget.onNext,
                  child: Text(
                    'Explore without account →',
                    style: KaivaTextStyles.bodySmall.copyWith(
                      color: KaivaColors.textMuted,
                      decoration: TextDecoration.underline,
                      decorationColor: KaivaColors.textMuted,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Terms
                Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: KaivaTextStyles.labelSmall.copyWith(
                    color: KaivaColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo mark ─────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FFFFFF),
                blurRadius: 40,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x1A8CD4FF),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/kaiva_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'KAIVA',
          style: KaivaTextStyles.displayMedium.copyWith(
            letterSpacing: 6,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: KaivaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Sign-in button ────────────────────────────────────────────
class _SignInButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final bool filled;
  final bool isLoading;

  const _SignInButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.filled,
    this.isLoading = false,
  });

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80), lowerBound: 0.95, upperBound: 1.0)
      ..value = 1.0;
    _scale = _press;
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _press.reverse() : null,
      onTapUp: widget.onTap != null ? (_) { _press.forward(); widget.onTap?.call(); } : null,
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: widget.filled
                ? KaivaColors.textPrimary
                : Colors.transparent,
            border: widget.filled
                ? null
                : Border.all(color: KaivaColors.borderDefault, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        widget.filled
                            ? KaivaColors.backgroundPrimary
                            : KaivaColors.accentPrimary,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.icon,
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: KaivaTextStyles.labelLarge.copyWith(
                        fontSize: 15,
                        color: widget.filled
                            ? KaivaColors.backgroundPrimary
                            : KaivaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Google icon (painted, no package dep) ─────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final sweeps = [90.0, 90.0, 90.0, 90.0];
    final starts = [-45.0, 45.0, 135.0, 225.0];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        starts[i] * 3.14159 / 180,
        sweeps[i] * 3.14159 / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
