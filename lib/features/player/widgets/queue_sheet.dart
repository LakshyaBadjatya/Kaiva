import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../player_provider.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider).valueOrNull ?? [];
    final currentIndex = ref.watch(currentIndexProvider).valueOrNull;
    final handler = ref.read(audioHandlerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: KaivaColors.backgroundElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KaivaColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Queue', style: KaivaTextStyles.headlineMedium),
                  TextButton(
                    onPressed: () {
                      // Clear all except current
                      if (currentIndex != null) {
                        for (int i = queue.length - 1; i >= 0; i--) {
                          if (i != currentIndex) handler.removeFromQueue(i);
                        }
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const Divider(color: KaivaColors.borderSubtle),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: Text(
                        'Queue is empty',
                        style: TextStyle(color: KaivaColors.textMuted),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      itemCount: queue.length,
                      onReorder: (oldIndex, newIndex) {
                        HapticFeedback.lightImpact();
                        if (newIndex > oldIndex) newIndex--;
                        handler.reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, i) {
                        final item = queue[i];
                        final isCurrent = i == currentIndex;
                        return _QueueTile(
                          key: ValueKey(item.id + i.toString()),
                          item: item,
                          index: i,
                          isCurrent: isCurrent,
                          onTap: () => handler.skipToQueueItem(i),
                          onRemove: () => handler.removeFromQueue(i),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTile({
    super.key,
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${item.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        onRemove();
      },
      background: Container(
        alignment: Alignment.centerRight,
        color: KaivaColors.error.withValues(alpha: 0.15),
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: KaivaColors.error),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: isCurrent
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: KaivaColors.accentPrimary, width: 3),
                  ),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (isCurrent)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.equalizer, color: KaivaColors.accentPrimary, size: 18),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: KaivaTextStyles.titleMedium.copyWith(
                        color: isCurrent
                            ? KaivaColors.accentPrimary
                            : KaivaColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.artist ?? '',
                      style: KaivaTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.drag_handle, color: KaivaColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
