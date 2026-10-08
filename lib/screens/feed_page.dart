import 'package:flutter/material.dart';

import '../models/video_source.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/video_page.dart';
import 'assign_sheet.dart';
import 'comments_sheet.dart';

/// The vertical "For You" feed: every copied video, shuffled.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.currentVideoId});

  /// Reports the currently-visible video id up to [Home].
  final ValueNotifier<String?>? currentVideoId;

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

  void _report(List<VideoSource> list) {
    if (_index < list.length) {
      widget.currentVideoId?.value = list[_index].id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final videos = state.forYou;
    _report(videos);

    if (videos.isEmpty) {
      return const _EmptyFeed();
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: const Color(0xFFFF2D78),
          onRefresh: () async => state.shuffleForYou(),
          child: PageView.builder(
            controller: _pc,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _report(videos);
            },
            itemBuilder: (context, i) {
              final src = videos[i];
              final owner = state.ownerOfSource(src);
              return VideoPage(
                key: ValueKey(src.id),
                source: src,
                isActive: i == _index,
                ownerName: owner?.name,
                onAssign: () => showAssignSheet(context, src.id),
                onOpenComments: () => showCommentsSheet(context, src.id),
                onOpenProfile: owner == null
                    ? null
                    : () => _goToProfile(context, state, owner.id),
              );
            },
          ),
        ),
        Positioned(
          top: 44,
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
    HomeSwitcher.of(context)?.goProfile();
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined,
                color: Colors.white38, size: 56),
            const SizedBox(height: 14),
            const Text(
              'For You te ekhono kono video nei.\nProfile theke "Add videos" kore copy korun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => HomeSwitcher.of(context)?.goProfile(),
              icon: const Icon(Icons.person),
              label: const Text('Go to Profile'),
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

/// Lets any descendant ask [Home] to flip tabs.
class HomeSwitcher extends InheritedWidget {
  const HomeSwitcher(
      {super.key, required this.controller, required super.child});

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
  void goAll();
}
