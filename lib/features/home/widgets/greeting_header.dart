import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../../core/utils/settings_keys.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = Hive.box('kaiva_settings')
        .get(SettingsKeys.displayName, defaultValue: 'Lakshya') as String;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: KaivaTextStyles.bodyMedium.copyWith(
              color: KaivaColors.textSecondary,
            ),
          ),
          Text(
            name,
            style: KaivaTextStyles.displayMedium,
          ),
        ],
      ),
    );
  }
}
