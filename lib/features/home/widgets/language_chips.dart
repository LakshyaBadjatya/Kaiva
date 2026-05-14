import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../home_provider.dart';

const _languages = [
  ('Hindi',     'hindi'),
  ('English',   'english'),
  ('Tamil',     'tamil'),
  ('Telugu',    'telugu'),
  ('Punjabi',   'punjabi'),
  ('Marathi',   'marathi'),
  ('Bengali',   'bengali'),
  ('Kannada',   'kannada'),
  ('Malayalam', 'malayalam'),
];

class LanguageChips extends ConsumerWidget {
  const LanguageChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedLanguageProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value) = _languages[i];
          final isSelected = selected == value;

          return GestureDetector(
            onTap: () => ref.read(selectedLanguageProvider.notifier).select(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? KaivaColors.accentPrimary
                    : KaivaColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isSelected
                      ? KaivaColors.accentPrimary
                      : KaivaColors.borderDefault,
                  width: 0.5,
                ),
              ),
              child: Text(
                label,
                style: KaivaTextStyles.chipLabel.copyWith(
                  color: isSelected
                      ? KaivaColors.textOnAccent
                      : KaivaColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
