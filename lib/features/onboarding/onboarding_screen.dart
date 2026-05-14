import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kaiva_colors.dart';
import 'onboarding_provider.dart';
import 'pages/welcome_page.dart';
import 'pages/language_page.dart';
import 'pages/artist_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _total = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _total - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _back() {
    if (_page > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final languages = ref.read(selectedLanguagesProvider);
    final artists   = ref.read(selectedArtistsProvider);
    await completeOnboarding(languages: languages, artistIds: artists);
    ref.read(onboardingCompleteProvider.notifier).state = true;
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      body: Stack(
        children: [
          // Pages
          PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              WelcomePage(onNext: _next),
              LanguagePage(onNext: _next, onBack: _back),
              ArtistPage(onFinish: _finish, onBack: _back),
            ],
          ),

          // Progress dots — top-right (pages 1 & 2 only; welcome has its own flow)
          if (_page > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: _ProgressDots(current: _page - 1, total: _total - 1),
            ),

          // Back arrow (pages 1 & 2)
          if (_page > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: KaivaColors.textSecondary, size: 20),
                onPressed: _back,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────
class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? KaivaColors.accentPrimary
                : KaivaColors.borderDefault,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
