import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/video_source.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';
import '../widgets/thumb.dart';
import 'profile_screen.dart';
import 'single_video_screen.dart';

/// Local-only search: videos by title + profiles by name.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final q = _q.trim().toLowerCase();

    final profiles = q.isEmpty
        ? const <Profile>[]
        : state.profiles
            .where((p) => p.name.toLowerCase().contains(q))
            .toList();
    final videos = q.isEmpty
        ? const <VideoSource>[]
        : state.localVideos
            .where((v) => v.title.toLowerCase().contains(q))
            .map(VideoSource.fromLocal)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(
            hintText: 'Video ba profile khuje dekhlam...',
            hintStyle: TextStyle(color: Colors.white30),
            border: InputBorder.none,
          ),
        ),
      ),
      body: q.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Video title ba profile naam likhun.\nShudhu apnar device er jinis khujbe (offline).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.5),
                ),
              ),
            )
          : (profiles.isEmpty && videos.isEmpty)
              ? const Center(
                  child: Text('Kichu pawa jay ni',
                      style: TextStyle(color: Colors.white38)),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (profiles.isNotEmpty)
                      const _SectionHeader('Profiles'),
                    for (final p in profiles) _profileRow(context, p),
                    if (videos.isNotEmpty)
                      const _SectionHeader('Videos'),
                    for (final v in videos) _videoRow(context, state, v),
                  ],
                ),
    );
  }

  Widget _profileRow(BuildContext context, Profile p) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(profile: p)),
      ),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Avatar(path: p.avatarPath, name: p.name, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _videoRow(BuildContext context, AppState state, VideoSource src) {
    final owner = state.ownerOfSource(src);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SingleVideoScreen(source: src, ownerName: owner?.name),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            VideoThumb(source: src, width: 54, height: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    src.title.isEmpty ? 'Video' : src.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (owner != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '@${owner.name}',
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
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
