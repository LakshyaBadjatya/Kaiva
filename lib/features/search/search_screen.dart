import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../core/utils/song_loader.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'search_provider.dart';
import 'widgets/search_song_tile.dart';

// Browse category data
const _categories = [
  (label: 'Bollywood',  icon: Icons.movie_outlined,      color: Color(0xFFE91E63)),
  (label: 'Pop',        icon: Icons.music_note_outlined,  color: Color(0xFF9C27B0)),
  (label: 'Rock',       icon: Icons.electric_bolt,        color: Color(0xFF3F51B5)),
  (label: 'Hip-Hop',    icon: Icons.headphones_outlined,  color: Color(0xFF009688)),
  (label: 'Classical',  icon: Icons.piano_outlined,       color: Color(0xFFFF5722)),
  (label: 'Devotional', icon: Icons.spa_outlined,         color: Color(0xFFFF9800)),
  (label: 'Punjabi',    icon: Icons.celebration_outlined, color: Color(0xFF4CAF50)),
  (label: 'Romance',    icon: Icons.favorite_border,      color: Color(0xFFF44336)),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  bool _isActive    = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    setState(() => _isActive = q.isNotEmpty);
    ref.read(searchQueryProvider.notifier).state = q;
    ref.read(searchResultsProvider.notifier).search(q);
  }

  void _submitQuery(String q) {
    if (q.trim().isEmpty) return;
    _focusNode.unfocus();
    context.push('/search/results?q=${Uri.encodeComponent(q.trim())}');
  }

  void _clearSearch() {
    _controller.clear();
    _onQueryChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchResultsProvider);
    final recent      = ref.watch(recentSearchSongsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onSubmitted: _submitQuery,
              onClear: _clearSearch,
              isActive: _isActive,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !_isActive
                    ? _IdleView(
                        key: const ValueKey('idle'),
                        recent: recent,
                        onRecentTap: (q) {
                          _controller.text = q;
                          _onQueryChanged(q);
                          _focusNode.unfocus();
                          context.push('/search/results?q=${Uri.encodeComponent(q)}');
                        },
                        onRecentDelete: (q) =>
                            ref.read(recentSearchesProvider.notifier).remove(q),
                        onClearAll: () =>
                            ref.read(recentSearchesProvider.notifier).clear(),
                        onCategoryTap: (label) {
                          _controller.text = label;
                          _onQueryChanged(label);
                          _focusNode.unfocus();
                          context.push('/search/results?q=${Uri.encodeComponent(label)}');
                        },
                      )
                    : searchState.when(
                        data: (result) {
                          if (result == null) return const SizedBox.shrink();
                          final songs = result.songs;
                          if (songs.isEmpty &&
                              result.albums.isEmpty &&
                              result.artists.isEmpty &&
                              result.playlists.isEmpty) {
                            return _EmptyResults(query: _controller.text);
                          }
                          return _QuickResults(
                            key: ValueKey(_controller.text),
                            songs: songs,
                            query: _controller.text,
                            onShowAll: () => _submitQuery(_controller.text),
                          );
                        },
                        loading: () => const _SearchShimmer(key: ValueKey('loading')),
                        error: (_, __) => const _SearchError(key: ValueKey('error')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool isActive;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: KaivaTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Songs, artists, albums…',
          hintStyle: KaivaTextStyles.bodyMedium.copyWith(
            color: KaivaColors.textMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: KaivaColors.textMuted),
          suffixIcon: isActive
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: KaivaColors.textMuted),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: KaivaColors.backgroundTertiary,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Idle: recent + browse grid ────────────────────────────────
class _IdleView extends StatelessWidget {
  final List<String> recent;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRecentDelete;
  final VoidCallback onClearAll;
  final ValueChanged<String> onCategoryTap;

  const _IdleView({
    super.key,
    required this.recent,
    required this.onRecentTap,
    required this.onRecentDelete,
    required this.onClearAll,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent', style: KaivaTextStyles.sectionHeader),
              TextButton(
                onPressed: onClearAll,
                child: Text(
                  'Clear all',
                  style: KaivaTextStyles.bodySmall.copyWith(
                    color: KaivaColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          ...recent.map(
            (q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, color: KaivaColors.textMuted, size: 20),
              title: Text(q, style: KaivaTextStyles.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: KaivaColors.textMuted),
                onPressed: () => onRecentDelete(q),
              ),
              onTap: () => onRecentTap(q),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Browse categories', style: KaivaTextStyles.sectionHeader),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, i) {
            final cat = _categories[i];
            return _CategoryTile(
              label: cat.label,
              icon: cat.icon,
              color: cat.color,
              onTap: () => onCategoryTap(cat.label),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: KaivaTextStyles.bodyMedium.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick results (top songs inline, "See all" → full results) ─
class _QuickResults extends StatelessWidget {
  final List songs;
  final String query;
  final VoidCallback onShowAll;

  const _QuickResults({
    super.key,
    required this.songs,
    required this.query,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (songs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Top Songs', style: KaivaTextStyles.sectionHeader),
          ),
          ...songs.take(5).map(
                (song) => SearchSongTile(song: song),
              ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.open_in_full_rounded, size: 16),
            label: Text('See all results for "$query"'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KaivaColors.accentPrimary,
              side: const BorderSide(color: KaivaColors.accentPrimary, width: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Shimmer while searching ───────────────────────────────────
class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) => const ShimmerSongTile(),
    );
  }
}

// ── No results ────────────────────────────────────────────────
class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: KaivaColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Network error ─────────────────────────────────────────────
class _SearchError extends StatelessWidget {
  const _SearchError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: KaivaColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Could not reach server.\nCheck your connection.',
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
