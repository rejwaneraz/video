import 'package:flutter/material.dart';

import '../models/video_source.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import 'single_video_screen.dart';

/// Inbox tab: your own activity (comments you wrote + videos you liked),
/// reconstructed from prefs. Tap a row to open that video.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  static const Color _pink = Color(0xFFFF2D78);

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final eng = state.engage;

    final commentEntries = <MapEntry<String, String>>[];
    eng.allUserComments.forEach((vid, list) {
      for (final t in list) {
        commentEntries.add(MapEntry(vid, t));
      }
    });
    final likedIds = eng.likedIds.toList();
    final hasAny = commentEntries.isNotEmpty || likedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        foregroundColor: Colors.white,
        title: const Text('Inbox'),
      ),
      body: !hasAny
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Ekhono kono activity nei.\nVideo like ba comment korun, ekhane dekhabe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.5),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (commentEntries.isNotEmpty) const _Header('Your comments'),
                for (final e in commentEntries)
                  _activityRow(context, state,
                      videoId: e.key,
                      icon: Icons.mode_comment_outlined,
                      title: 'Commented on',
                      subtitle: e.value),
                if (likedIds.isNotEmpty) const _Header('Liked videos'),
                for (final id in likedIds)
                  _activityRow(context, state,
                      videoId: id, icon: Icons.favorite, title: 'You liked'),
              ],
            ),
    );
  }

  Widget _activityRow(
    BuildContext context,
    AppState state, {
    required String videoId,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final lv = state.localById(videoId);
    if (lv == null) return const SizedBox.shrink();
    final src = VideoSource.fromLocal(lv);
    final vtitle = lv.title.isEmpty ? 'video' : lv.title;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SingleVideoScreen(source: src, showAssign: false),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white12,
              child: Icon(icon, color: _pink, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title · $vtitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
