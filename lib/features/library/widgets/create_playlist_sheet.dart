import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/kaiva_database.dart' show LocalPlaylistsCompanion;
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';

class CreatePlaylistSheet extends ConsumerStatefulWidget {
  const CreatePlaylistSheet({super.key});

  @override
  ConsumerState<CreatePlaylistSheet> createState() =>
      _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends ConsumerState<CreatePlaylistSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      await db.playlistsDao.createPlaylist(LocalPlaylistsCompanion(
        id: Value(const Uuid().v4()),
        name: Value(name),
        description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return Container(
      decoration: const BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KaivaColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('New Playlist', style: KaivaTextStyles.headlineMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: KaivaTextStyles.bodyMedium.copyWith(
              color: KaivaColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: KaivaTextStyles.bodySmall,
              filled: true,
              fillColor: KaivaColors.backgroundTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: KaivaColors.accentPrimary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: KaivaTextStyles.bodyMedium.copyWith(
              color: KaivaColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: KaivaTextStyles.bodySmall,
              filled: true,
              fillColor: KaivaColors.backgroundTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: KaivaColors.accentPrimary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: KaivaColors.accentPrimary,
              foregroundColor: KaivaColors.textOnAccent,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KaivaColors.textOnAccent,
                    ),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }
}
