import 'package:flutter/material.dart';

import '../models/video_source.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/video_page.dart';
import 'comments_sheet.dart';

/// Vertical feed of every video currently on the phone (not copied).
class AllVideosPage extends StatefulWidget {
  const AllVideosPage({super.key});

  @override
  State<AllVideosPage> createState() => _AllVideosPageState();
}

class _AllVideosPageState extends State<AllVideosPage> {
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
    final videos = state.allVideos;

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white38, size: 56),
            const SizedBox(height: 14),
            const Text(
              'Phone-e kono video pawa jay ni,\noba permission day ni.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: state.refreshDeviceVideos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D78),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pc,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final src = videos[i];
            return VideoPage(
              key: ValueKey(src.id),
              source: src,
              isActive: i == _index,
              showAssign: false,
              onOpenComments: () => showCommentsSheet(context, src.id),
              onAssign: null,
            );
          },
        ),
        Positioned(
          top: 44,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Text(
                'All Videos',
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
}

/// Copies the current device video into storage + active profile.
Future<void> importCurrentToActiveProfile(
    BuildContext context, VideoSource src) async {
  final state = AppStateScope.read(context);
  final a = src.asset;
  final p = state.activeProfile;
  if (a == null || p == null) return;
  await state.addToProfile(p.id, [a]);
}
