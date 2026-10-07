import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';
import '../widgets/thumb.dart';
import '../widgets/video_page.dart';
import 'edit_profile_screen.dart';
import 'select_videos_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    if (state.profiles.isEmpty) {
      return _NoProfile(state: state);
    }

    final profile = state.activeProfile ?? state.profiles.first;

    return Column(
      children: [
        if (state.profiles.length > 1) _ProfileSwitcher(state: state),
        Expanded(child: _ProfileBody(profile: profile)),
      ],
    );
  }
}

class _NoProfile extends StatelessWidget {
  const _NoProfile({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, color: Colors.white38, size: 60),
            const SizedBox(height: 14),
            const Text(
              'Profile nei.\nEkta profile banan, tarpor video assign korun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create profile'),
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

class _ProfileSwitcher extends StatelessWidget {
  const _ProfileSwitcher({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          for (final p in state.profiles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => state.setActiveProfile(p.id),
                child: Column(
                  children: [
                    Avatar(
                      path: p.avatarPath,
                      name: p.name,
                      size: 46,
                      ring: state.activeProfile?.id == p.id,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 62,
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: state.activeProfile?.id == p.id
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.add, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  const Text('Add',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final videos = state.videosOf(profile);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Row(
          children: [
            Avatar(path: profile.avatarPath, name: profile.name, size: 78, ring: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${videos.length} videos',
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(profile.bio,
                        style: const TextStyle(color: Colors.white70, height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _action(context, Icons.edit_outlined, 'Edit profile', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: profile),
                  ),
                );
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _action(context, Icons.add_photo_alternate_outlined,
                  'Add videos', () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectVideosScreen(profile: profile),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
              final asset = videos[i];
              return Thumb(
                asset: asset,
                width: 200,
                height: 267,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileFeed(videos: videos, index: i, owner: profile),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _action(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1B1B21),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
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

  final List<AssetEntity> videos;
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
              final asset = widget.videos[i];
              return VideoPage(
                key: ValueKey(asset.id),
                asset: asset,
                isActive: i == _index,
                caption: asset.title,
                ownerName: widget.owner.name,
                ownerAvatar: widget.owner.avatarPath,
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
