import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/video_source.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';
import '../widgets/thumb.dart';
import '../widgets/video_page.dart';
import 'comments_sheet.dart';
import 'edit_profile_screen.dart';
import 'select_videos_screen.dart';

const Color _pink = Color(0xFFFF2D78);
const Color _surface = Color(0xFF111114);
const Color _btnGrey = Color(0xFF2A2A32);

String _handle(String name) {
  final h = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  return h.isEmpty ? 'user' : h;
}

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

List<PopupMenuEntry<String>> _profileMenuItems() => const [
      PopupMenuItem(
        value: 'edit',
        child: Text('Edit profile', style: TextStyle(color: Colors.white)),
      ),
      PopupMenuItem(
        value: 'add',
        child: Text('Add videos', style: TextStyle(color: Colors.white)),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text('Delete profile',
            style: TextStyle(color: Color(0xFFFF6B8A))),
      ),
    ];

/// A profile shown as a pushed full screen (opened by swipe-left on the feed,
/// from the Me list, or the rail avatar). Swipe right here to pop back.
/// Resolves the freshest copy of [profile] from state so edits/deletes
/// reflect immediately.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.profile});

  final Profile profile;

  void _onMenu(BuildContext context, Profile p, String value) {
    final state = AppStateScope.read(context);
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditProfileScreen(profile: p)),
        );
        break;
      case 'add':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SelectVideosScreen(profile: p)),
        );
        break;
      case 'delete':
        _confirmDeleteProfile(context, state, p);
        break;
      case 'hi':
        _sayHi(context, state, p);
        break;
    }
  }

  Future<void> _confirmDeleteProfile(
      BuildContext context, AppState state, Profile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title:
            const Text('Delete profile?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Profile muche jabe. Video gulo abar For You te chole ashbe.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: _pink))),
        ],
      ),
    );
    if (ok != true) return;
    await state.deleteProfile(p.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _sayHi(BuildContext context, AppState state, Profile p) async {
    final vids = state.sourcesOf(p);
    if (vids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ei profile e ekhono kono video nei')),
      );
      return;
    }
    await showCommentsSheet(context, vids.last.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final p = state.profiles
        .firstWhere((x) => x.id == profile.id, orElse: () => profile);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: _surface,
          foregroundColor: Colors.white,
          title: Text(
            _handle(p.name),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            PopupMenuButton<String>(
              color: const Color(0xFF1E1E24),
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) => _onMenu(context, p, v),
              itemBuilder: (_) => _profileMenuItems(),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _ProfileBody(profile: p, onMenu: (v) => _onMenu(context, p, v)),
        ),
      ),
    );
  }
}

enum _Sort { latest, mostViewed }

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.profile, required this.onMenu});

  final Profile profile;
  final ValueChanged<String> onMenu;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  _Sort _sort = _Sort.latest;

  void _toggleSort() => setState(
      () => _sort = _sort == _Sort.latest ? _Sort.mostViewed : _Sort.latest);

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final p = widget.profile;
    final eng = state.engage;
    final following = state.isFollowing(p.id);

    var videos = state.sourcesOf(p);
    if (_sort == _Sort.mostViewed) {
      videos = [...videos]
        ..sort((a, b) =>
            eng.viewCount(b.id).compareTo(eng.viewCount(a.id)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        Center(
          child: Avatar(path: p.avatarPath, name: p.name, size: 110, ring: true),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            p.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '@${_handle(p.name)}',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stat(_fmtCount(eng.following(p.id)), 'Following'),
            const SizedBox(width: 34),
            _stat(_fmtCount(eng.followers(p.id)), 'Followers'),
            const SizedBox(width: 34),
            _stat(_fmtCount(eng.profileLikes(p.id)), 'Likes'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _followButton(state, p, following)),
            const SizedBox(width: 8),
            _sayHiButton(),
            const SizedBox(width: 8),
            _dropdownButton(),
          ],
        ),
        if (p.bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            p.bio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.3),
          ),
        ],
        const SizedBox(height: 20),
        _sortControl(),
        const SizedBox(height: 8),
        if (videos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Ekhono kono video nei.\n"Add videos" tap korun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.4)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 3 / 4,
            ),
            itemCount: videos.length,
            itemBuilder: (context, i) {
              final src = videos[i];
              return VideoThumb(
                source: src,
                width: 200,
                height: 267,
                viewsLabel: _fmtCount(eng.viewCount(src.id)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileFeed(videos: videos, index: i, owner: p),
                  ),
                ),
                onLongPress: () => _confirmDeleteVideo(context, state, src),
              );
            },
          ),
      ],
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      );

  Widget _followButton(AppState state, Profile p, bool following) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () => state.toggleFollow(p.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: following ? _btnGrey : _pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _sayHiButton() {
    return SizedBox(
      height: 44,
      child: Material(
        color: _btnGrey,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => widget.onMenu('hi'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Say hi',
                    style:
                        TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Text('👋'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownButton() {
    return PopupMenuButton<String>(
      color: const Color(0xFF1E1E24),
      onSelected: widget.onMenu,
      offset: const Offset(0, 44),
      itemBuilder: (_) => _profileMenuItems(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _btnGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      ),
    );
  }

  Widget _sortControl() {
    final latest = _sort == _Sort.latest;
    return Center(
      child: InkWell(
        onTap: _toggleSort,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(latest ? Icons.schedule : Icons.local_fire_department,
                  size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                latest ? 'Latest' : 'Most viewed',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteVideo(
      BuildContext context, AppState state, VideoSource src) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title:
            const Text('Delete video?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Copy muche jabe (storage khali hobe). Sob profile theke remove hobe.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: _pink))),
        ],
      ),
    );
    if (ok == true) await state.deleteLocalVideo(src.id);
  }
}

/// Full-screen vertical player over one profile's videos.
class ProfileFeed extends StatefulWidget {
  const ProfileFeed({
    super.key,
    required this.videos,
    required this.index,
    required this.owner,
  });

  final List<VideoSource> videos;
  final int index;
  final Profile owner;

  @override
  State<ProfileFeed> createState() => _ProfileFeedState();
}

class _ProfileFeedState extends State<ProfileFeed> {
  late final PageController _pc = PageController(initialPage: widget.index);
  late int _index = widget.index;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final src = widget.videos[i];
              final state = AppStateScope.of(context);
              return VideoPage(
                key: ValueKey(src.id),
                source: src,
                isActive: i == _index,
                ownerName: widget.owner.name,
                owner: widget.owner,
                following: state.isFollowing(widget.owner.id),
                onFollow: () => state.toggleFollow(widget.owner.id),
                showAssign: false,
                onOpenComments: () => showCommentsSheet(context, src.id),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  '@${widget.owner.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
