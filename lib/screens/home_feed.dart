import 'package:flutter/material.dart';

import 'all_videos_page.dart';
import 'feed_page.dart';
import 'search_screen.dart';

/// Home tab: a TikTok-style top tab bar (For You | All Videos) + search icon
/// floating over the vertical feed. Tabs switch by TAP; the feed keeps its own
/// horizontal gestures (right -> owner profile, left -> All Videos).
class HomeFeed extends StatefulWidget {
  const HomeFeed({
    super.key,
    required this.tabActive,
    this.onRequestAddVideos,
  });

  /// Whether the Home bottom-nav tab is visible; gates playback.
  final bool tabActive;
  final VoidCallback? onRequestAddVideos;

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  int _top = 0; // 0 For You, 1 All Videos

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _top,
          children: [
            FeedPage(
              tabActive: widget.tabActive && _top == 0,
              onOpenExplore: () => setState(() => _top = 1),
              onRequestAddVideos: widget.onRequestAddVideos,
            ),
            AllVideosPage(
              tabActive: widget.tabActive && _top == 1,
              showTitle: false,
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopTabs(
            top: _top,
            onTab: (i) => setState(() => _top = i),
            onSearch: _openSearch,
          ),
        ),
      ],
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({
    required this.top,
    required this.onTab,
    required this.onSearch,
  });

  final int top;
  final ValueChanged<int> onTab;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.55), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 46,
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tab('For You', 0),
                    const SizedBox(width: 20),
                    _tab('All Videos', 1),
                  ],
                ),
              ),
              Positioned(
                right: 2,
                top: 0,
                bottom: 0,
                child: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final sel = top == index;
    return GestureDetector(
      onTap: () => onTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 2,
            width: sel ? 26 : 0,
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
