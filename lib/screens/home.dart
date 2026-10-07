import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import 'feed_page.dart';
import 'profile_screen.dart';

/// Horizontal pager: [0] For You feed, [1] Profile.
/// Swipe left on the feed -> profile (TikTok style).
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> implements HomeController {
  final PageController _pc = PageController();

  @override
  void goProfile() {
    if (_pc.hasClients) _pc.animateToPage(1, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  void goFeed() {
    if (_pc.hasClients) _pc.animateToPage(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
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
          children: const [
            FeedPage(),
            ProfileScreen(),
          ],
        ),
      ),
    );
  }
}
