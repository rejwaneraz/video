import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/video_page.dart';
import 'assign_sheet.dart';
import 'comments_sheet.dart';
import 'profile_screen.dart';

/// The vertical "For You" feed: every copied video, shuffled.
///
/// Horizontal swipe right -> that video's owner profile (pushed).
/// Horizontal swipe left -> Explore tab (All Videos).
class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    this.onOpenExplore,
    this.onRequestAddVideos,
    this.tabActive = true,
  });

  /// Called on left swipe so the shell can switch to Explore.
  final VoidCallback? onOpenExplore;

  /// Opens add-videos for the active profile (used by the empty state).
  final VoidCallback? onRequestAddVideos;

  /// Whether this feed's tab is currently visible; gates playback.
  final bool tabActive;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PageController _pc = PageController();
  int _index = 0;
  double _hDrag = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _openOwnerProfile(AppState state) {
    final videos = state.forYou;
    if (_index >= videos.length) return;
    final owner = state.ownerOfSource(videos[_index]);
    if (owner == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(profile: owner)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final videos = state.forYou;

    if (videos.isEmpty) {
      return _EmptyFeed(onAdd: widget.onRequestAddVideos);
    }

    return GestureDetector(
      onHorizontalDragStart: (_) => _hDrag = 0,
      onHorizontalDragUpdate: (d) => _hDrag += d.delta.dx,
      onHorizontalDragEnd: (_) {
        if (_hDrag > 60) {
          _openOwnerProfile(state);
        } else if (_hDrag < -60) {
          widget.onOpenExplore?.call();
        }
        _hDrag = 0;
      },
      child: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFFFF2D78),
            onRefresh: () async => state.shuffleForYou(),
            child: PageView.builder(
              controller: _pc,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final src = videos[i];
                final owner = state.ownerOfSource(src);
                return VideoPage(
                  key: ValueKey(src.id),
                  source: src,
                  isActive: i == _index && widget.tabActive,
                  ownerName: owner?.name,
                  owner: owner,
                  following: owner != null && state.isFollowing(owner.id),
                  onFollow:
                      owner == null ? null : () => state.toggleFollow(owner.id),
                  onAssign: () => showAssignSheet(context, src.id),
                  onOpenComments: () => showCommentsSheet(context, src.id),
                  onOpenProfile: owner == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProfilePage(profile: owner)),
                          ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111114),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined,
                color: Colors.white38, size: 56),
            const SizedBox(height: 14),
            const Text(
              'For You te ekhono kono video nei.\n"Add videos" theke copy korun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add videos'),
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
