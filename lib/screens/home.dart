import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import 'all_videos_page.dart';
import 'feed_page.dart';
import 'profile_screen.dart';

/// Horizontal pager: [0] Profile, [1] For You, [2] All Videos.
/// Swipe right on the feed -> that video's profile. Swipe left -> All Videos.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> implements HomeController {
  final PageController _pc = PageController(initialPage: 1);
  final ValueNotifier<String?> _currentVideoId = ValueNotifier(null);

  @override
  void goProfile() => _go(0);

  @override
  void goFeed() => _go(1);

  @override
  void goAll() => _go(2);

  void _go(int i) {
    if (_pc.hasClients) {
      _pc.animateToPage(i,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _currentVideoId.dispose();
    super.dispose();
  }

  void _onPageChanged(int page, AppState state) {
    if (page != 0) return;
    // Opening the profile tab: show the owner of the video being watched.
    final id = _currentVideoId.value;
    if (id == null) return;
    final matches = state.forYou.where((s) => s.id == id);
    if (matches.isEmpty) return;
    final owner = state.ownerOfSource(matches.first);
    if (owner != null) state.setActiveProfile(owner.id);
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

    return HomeSwitcher(
      controller: this,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView(
          controller: _pc,
          onPageChanged: (p) => _onPageChanged(p, state),
          children: [
            const ProfileScreen(),
            FeedPage(currentVideoId: _currentVideoId),
            const AllVideosPage(),
          ],
        ),
      ),
    );
  }
}
