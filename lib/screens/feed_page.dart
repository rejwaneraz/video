import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/video_page.dart';
import 'assign_sheet.dart';

/// The vertical "For You" feed of unassigned device videos.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PageController _pc = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final videos = state.forYou;

    if (videos.isEmpty) {
      return const _EmptyFeed();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pc,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final asset = videos[i];
            final owner = state.ownerOf(asset.id);
            return VideoPage(
              key: ValueKey(asset.id),
              asset: asset,
              isActive: i == _index,
              caption: asset.title,
              ownerName: owner?.name,
              ownerAvatar: owner?.avatarPath,
              onAssign: () => showAssignSheet(context, asset.id),
              onOpenProfile: owner == null
                  ? null
                  : () => _goToProfile(context, state, owner.id),
            );
          },
        ),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Text(
                'For You',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goToProfile(BuildContext context, AppState state, String profileId) {
    state.setActiveProfile(profileId);
    // Ask Home to switch the horizontal pager to the profile tab.
    HomeSwitcher.of(context)?.goProfile();
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.read(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined,
                color: Colors.white38, size: 56),
            const SizedBox(height: 14),
            Text(
              state.permissionGranted
                  ? 'For You te ekhon kono video nei.\nSob video profile-e assign kora.'
                  : 'Video permission day, tarpor abar try korun.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: state.refreshVideos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload videos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D78),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets any descendant ask [Home] to flip to the profile tab.
class HomeSwitcher extends InheritedWidget {
  const HomeSwitcher({super.key, required this.controller, required super.child});

  final HomeController controller;

  static HomeController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeSwitcher>()?.controller;

  @override
  bool updateShouldNotify(covariant HomeSwitcher old) =>
      controller != old.controller;
}

abstract class HomeController {
  void goProfile();
  void goFeed();
}
