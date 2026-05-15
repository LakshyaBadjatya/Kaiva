import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../features/player/mini_player.dart';
import 'celebration_overlay.dart';
import 'offline_banner.dart';

class KaivaScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;

  const KaivaScaffold({super.key, required this.shell});

  static const _tabs = [
    (icon: Icons.home_outlined,          activeIcon: Icons.home,           label: 'Home'),
    (icon: Icons.search,                 activeIcon: Icons.search,          label: 'Search'),
    (icon: Icons.library_music_outlined, activeIcon: Icons.library_music,  label: 'Library'),
    (icon: Icons.download_outlined,      activeIcon: Icons.download_done,   label: 'Downloads'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(child: shell),
              // MiniPlayer sits above bottom nav (Column, never Stack)
              const MiniPlayer(),
              _buildBottomNav(context),
            ],
          ),
          // App-wide celebration layer (first-like confetti, etc.)
          const Positioned.fill(child: CelebrationOverlay()),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: shell.currentIndex,
      onTap: (index) => shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      ),
      items: _tabs
          .map((t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                activeIcon: Icon(t.activeIcon, color: KaivaColors.accentPrimary),
                label: t.label,
              ))
          .toList(),
    );
  }
}
