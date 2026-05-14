import 'package:flutter/material.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message = 'Something went wrong', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: KaivaColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(message, style: KaivaTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: KaivaColors.accentPrimary),
                label: const Text('Retry', style: TextStyle(color: KaivaColors.accentPrimary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
