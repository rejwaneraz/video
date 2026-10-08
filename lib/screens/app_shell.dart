import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import 'all_videos_page.dart';
import 'edit_profile_screen.dart';
import 'home_feed.dart';
import 'inbox_screen.dart';
import 'profiles_list_screen.dart';
import 'select_videos_screen.dart';

/// TikTok-style shell: bottom nav with 5 slots
/// (Home, Explore, [+], Inbox, Me). The `+` is an action, not a tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Nav index: 0 Home, 1 Explore, 2 = add (action), 3 Inbox, 4 Me.
  int _tab = 0;

  int get _stackIndex {
    switch (_tab) {
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _openAddVideos() async {
    final AppState state = AppStateScope.read(context);
    final p = state.activeProfile;
    final route = p == null
        ? MaterialPageRoute(builder: (_) => const EditProfileScreen())
        : MaterialPageRoute(builder: (_) => SelectVideosScreen(profile: p));
    await Navigator.push(context, route);
  }

  void _onNavTap(int i) {
    if (i == 2) {
      _openAddVideos();
      return;
    }
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    if (state.loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2D78)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _stackIndex,
        children: [
          HomeFeed(
            tabActive: _tab == 0,
            onRequestAddVideos: _openAddVideos,
          ),
          AllVideosPage(tabActive: _tab == 1),
          const InboxScreen(),
          const ProfilesListScreen(),
        ],
      ),
      bottomNavigationBar: _BottomBar(current: _tab, onTap: _onNavTap),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  static const Color _pink = Color(0xFFFF2D78);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _item(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _item(1, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
              _addButton(),
              _item(
                  3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline, 'Inbox'),
              _item(4, Icons.person_rounded, Icons.person_outline, 'Me'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData activeIcon, IconData inactiveIcon,
      String label) {
    final sel = current == index;
    final color = sel ? _pink : Colors.white54;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sel ? activeIcon : inactiveIcon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(2),
        child: Center(
          child: Container(
            width: 44,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _pink, width: 1.5),
            ),
            child: const Icon(Icons.add, size: 20, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
