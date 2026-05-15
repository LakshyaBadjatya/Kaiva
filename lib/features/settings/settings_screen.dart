import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/database/database_provider.dart';
import '../../core/firebase/auth_provider.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/firebase/sync_service.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../auth/auth_screen.dart';
import '../search/search_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  final _apiUrlCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _apiUrlCtrl.text = ref.read(apiBaseUrlProvider);
    _nameCtrl.text = ref.read(displayNameProvider);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamQuality = ref.watch(streamQualityProvider);
    final downloadQuality = ref.watch(downloadQualityProvider);
    final storageLimit = ref.watch(storageLimitProvider);
    final wifiOnly = ref.watch(wifiOnlyProvider);
    final mono = ref.watch(monoAudioProvider);
    final crossfade = ref.watch(crossfadeProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: KaivaColors.backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: KaivaColors.borderSubtle, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: KaivaColors.accentBright,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: KaivaTextStyles.headlineMedium.copyWith(
            color: KaivaColors.accentBright,
          ),
        ),
      ),
      body: ListView(
        children: [

          // ── Account ──────────────────────────────────────
          const _Header('Account'),
          _AccountTile(nameCtrl: _nameCtrl),

          // ── Import ───────────────────────────────────────
          const _Header('Import'),
          ListTile(
            leading: const Icon(Icons.library_music_outlined, color: KaivaColors.textMuted, size: 22),
            title: const Text('Import from Spotify', style: KaivaTextStyles.bodyMedium),
            subtitle: const Text('Import playlists & liked songs from Spotify', style: KaivaTextStyles.bodySmall),
            trailing: const Icon(Icons.chevron_right_rounded, color: KaivaColors.textMuted),
            onTap: () => context.push('/settings/spotify-import'),
          ),

          // ── Playback ─────────────────────────────────────
          const _Header('Playback'),
          _DropdownTile<String>(
            label: 'Stream Quality',
            value: streamQuality,
            items: const [
              DropdownMenuItem(value: '128', child: Text('128 kbps')),
              DropdownMenuItem(value: '160', child: Text('160 kbps')),
              DropdownMenuItem(value: '320', child: Text('320 kbps')),
            ],
            onChanged: (v) => v != null ? ref.read(streamQualityProvider.notifier).set(v) : null,
          ),
          ListTile(
            title: const Text('Crossfade', style: KaivaTextStyles.bodyMedium),
            subtitle: Text(
              crossfade == 0 ? 'Off' : '$crossfade s',
              style: KaivaTextStyles.bodySmall
                  .copyWith(color: KaivaColors.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: KaivaColors.textMuted),
            onTap: () => context.push('/settings/crossfade'),
          ),
          SwitchListTile(
            title: const Text('Mono Audio', style: KaivaTextStyles.bodyMedium),
            value: mono,
            onChanged: (v) => ref.read(monoAudioProvider.notifier).set(v),
          ),
          ListTile(
            title: const Text('Equalizer', style: KaivaTextStyles.bodyMedium),
            trailing: const Icon(Icons.chevron_right_rounded, color: KaivaColors.textMuted),
            onTap: () => context.push('/settings/equalizer'),
          ),

          // ── Downloads ────────────────────────────────────
          const _Header('Downloads'),
          _DropdownTile<String>(
            label: 'Download Quality',
            value: downloadQuality,
            items: const [
              DropdownMenuItem(value: '128', child: Text('128 kbps')),
              DropdownMenuItem(value: '160', child: Text('160 kbps')),
              DropdownMenuItem(value: '320', child: Text('320 kbps')),
            ],
            onChanged: (v) => v != null ? ref.read(downloadQualityProvider.notifier).set(v) : null,
          ),
          _SliderTile(
            label: 'Storage Limit',
            valueLabel: storageLimit >= 1024
                ? '${(storageLimit / 1024).round()} GB'
                : '$storageLimit MB',
            value: storageLimit.toDouble(),
            min: 256, max: 8192, divisions: 31,
            onChanged: (v) => ref.read(storageLimitProvider.notifier).set(v.round()),
          ),
          SwitchListTile(
            title: const Text('Wi-Fi Only Downloads', style: KaivaTextStyles.bodyMedium),
            value: wifiOnly,
            onChanged: (v) => ref.read(wifiOnlyProvider.notifier).set(v),
          ),
          ListTile(
            title: const Text('Manage Downloads', style: KaivaTextStyles.bodyMedium),
            trailing: const Icon(Icons.chevron_right_rounded, color: KaivaColors.textMuted),
            onTap: () => context.go('/downloads'),
          ),

          // ── Advanced ─────────────────────────────────────
          const _Header('Advanced'),
          _ApiUrlTile(controller: _apiUrlCtrl),
          ListTile(
            title: const Text('Clear Search History', style: KaivaTextStyles.bodyMedium),
            trailing: const Icon(Icons.delete_outline_rounded, color: KaivaColors.textMuted),
            onTap: () {
              ref.read(recentSearchesProvider.notifier).clear();
              _showSnack('Search history cleared');
            },
          ),
          ListTile(
            title: const Text('Clear Recently Played', style: KaivaTextStyles.bodyMedium),
            trailing: const Icon(Icons.delete_outline_rounded, color: KaivaColors.textMuted),
            onTap: () async {
              final db = ref.read(databaseProvider);
              await db.recentlyPlayedDao.clearHistory();
              _showSnack('Recently played cleared');
            },
          ),
          ListTile(
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: KaivaColors.error, fontSize: 13),
            ),
            trailing: const Icon(Icons.warning_amber_rounded, color: KaivaColors.error),
            onTap: () => _confirmClearAll(),
          ),

          // ── About ────────────────────────────────────────
          const _Header('About'),
          ListTile(
            title: const Text('App Version', style: KaivaTextStyles.bodyMedium),
            trailing: Text(_appVersion, style: KaivaTextStyles.bodySmall),
          ),
          const ListTile(
            title: Text('Powered by JioSaavn API (saavn.dev)',
                style: KaivaTextStyles.bodyMedium),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: KaivaTextStyles.bodyMedium),
        backgroundColor: KaivaColors.backgroundElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KaivaColors.backgroundSecondary,
        title: const Text('Clear all data?', style: KaivaTextStyles.headlineMedium),
        content: const Text(
          'This will delete all liked songs, playlists, downloads, and history.',
          style: KaivaTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: KaivaColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final db = ref.read(databaseProvider);
              await db.likedSongsDao.clearAll();
              await db.recentlyPlayedDao.clearHistory();
              ref.read(recentSearchesProvider.notifier).clear();
              _showSnack('All data cleared');
            },
            child: const Text('Clear',
                style: TextStyle(color: KaivaColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Account tile ──────────────────────────────────────────────
class _AccountTile extends ConsumerWidget {
  final TextEditingController nameCtrl;
  const _AccountTile({required this.nameCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.valueOrNull;

    if (user == null) {
      // Not signed in
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in to sync your liked songs and settings across devices.',
              style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.92,
                      maxChildSize: 0.95,
                      minChildSize: 0.6,
                      builder: (_, ctrl) => const ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        child: AuthScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In / Register'),
                  style: FilledButton.styleFrom(
                    backgroundColor: KaivaColors.accentPrimary,
                    foregroundColor: KaivaColors.textOnAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Signed in
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: KaivaColors.backgroundTertiary,
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? CachedNetworkImageProvider(user.photoURL!)
                : null,
            child: user.photoURL == null || user.photoURL!.isEmpty
                ? Text(
                    (user.displayName?.isNotEmpty == true
                        ? user.displayName![0]
                        : user.email?[0] ?? 'K'),
                    style: KaivaTextStyles.titleMedium.copyWith(color: KaivaColors.accentPrimary),
                  )
                : null,
          ),
          title: Text(user.displayName ?? 'Kaiva User', style: KaivaTextStyles.bodyMedium),
          subtitle: Text(user.email ?? '', style: KaivaTextStyles.bodySmall),
          trailing: TextButton(
            onPressed: () async {
              await FirebaseService.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out')),
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: KaivaColors.error)),
          ),
        ),
        // Edit display name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: nameCtrl,
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textPrimary),
            onSubmitted: (v) async {
              final trimmed = v.trim();
              if (trimmed.isEmpty) return;
              await FirebaseService.instance.updateDisplayName(trimmed);
            },
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: KaivaTextStyles.bodySmall,
              filled: true,
              fillColor: KaivaColors.backgroundTertiary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5)),
              suffixIcon: const Icon(Icons.edit_outlined, size: 18, color: KaivaColors.textMuted),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_sync_outlined, color: KaivaColors.textMuted, size: 20),
          title: const Text('Sync Now', style: KaivaTextStyles.bodyMedium),
          subtitle: const Text('Push local settings & liked songs to cloud', style: KaivaTextStyles.bodySmall),
          onTap: () async {
            await ref.read(syncServiceProvider).pushSettingsToCloud();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synced to cloud'),
                  backgroundColor: KaivaColors.success,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    // Editorial Noir section header: Playfair, underlined with border-white@10%
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KaivaSpacing.marginMobile,
        KaivaSpacing.xl,
        KaivaSpacing.marginMobile,
        KaivaSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.only(bottom: KaivaSpacing.xs),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: KaivaColors.borderSubtle, width: 1),
          ),
        ),
        child: Text(title, style: KaivaTextStyles.headlineMedium),
      ),
    );
  }
}

// ── API URL tile ──────────────────────────────────────────────
class _ApiUrlTile extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _ApiUrlTile({required this.controller});

  @override
  ConsumerState<_ApiUrlTile> createState() => _ApiUrlTileState();
}

class _ApiUrlTileState extends ConsumerState<_ApiUrlTile> {
  bool _testing = false;
  String? _testResult;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final url = widget.controller.text.trim();
    try {
      ApiClient.reinitialize(url);
      await ApiClient.instance().get(ApiEndpoints.searchSongs,
          params: {'query': 'test', 'limit': 1});
      if (mounted) setState(() => _testResult = 'Connected');
    } catch (_) {
      if (mounted) setState(() => _testResult = 'Failed');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'API Server URL',
              labelStyle: KaivaTextStyles.bodySmall,
              hintText: ApiEndpoints.defaultBaseUrl,
              filled: true,
              fillColor: KaivaColors.backgroundTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
              ),
            ),
            onSubmitted: (v) =>
                ref.read(apiBaseUrlProvider.notifier).setUrl(v.trim()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: _testing ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KaivaColors.accentPrimary,
                  side: const BorderSide(color: KaivaColors.accentPrimary, width: 0.8),
                ),
                child: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KaivaColors.accentPrimary,
                        ),
                      )
                    : const Text('Test Connection'),
              ),
              if (_testResult != null) ...[
                const SizedBox(width: 12),
                Text(
                  _testResult!,
                  style: KaivaTextStyles.bodySmall.copyWith(
                    color: _testResult == 'Connected'
                        ? KaivaColors.success
                        : KaivaColors.error,
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.controller.text = ApiEndpoints.defaultBaseUrl;
                  ref.read(apiBaseUrlProvider.notifier).setUrl(ApiEndpoints.defaultBaseUrl);
                },
                child: const Text('Reset',
                    style: TextStyle(color: KaivaColors.textMuted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dropdown tile — label left, dropdown right, aligned ──────
class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: KaivaTextStyles.bodyMedium),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            dropdownColor: KaivaColors.backgroundSecondary,
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textPrimary),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Slider tile — label + value label, full-width slider below ─
class _SliderTile extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: KaivaTextStyles.bodyMedium)),
              Text(valueLabel, style: KaivaTextStyles.bodySmall),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: KaivaColors.accentPrimary,
              inactiveColor: KaivaColors.backgroundTertiary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
