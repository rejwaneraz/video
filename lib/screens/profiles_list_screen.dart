import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';
import 'edit_profile_screen.dart';
import 'profile_screen.dart';

/// "Me" tab: an FB-friend-list style vertical list of every profile.
/// Tap a row to open it; the pinned first row creates a new profile.
class ProfilesListScreen extends StatelessWidget {
  const ProfilesListScreen({super.key});

  static const Color _pink = Color(0xFFFF2D78);

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        foregroundColor: Colors.white,
        title: const Text('Me'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _newProfileRow(context),
          if (state.profiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'Ekhono kono profile nei.\n"+ New profile" theke shuru korun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.4),
                ),
              ),
            )
          else
            for (final p in state.profiles) _profileRow(context, p),
        ],
      ),
    );
  }

  Widget _newProfileRow(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _pink),
              ),
              child: const Icon(Icons.add, color: _pink),
            ),
            const SizedBox(width: 12),
            const Text(
              'New profile',
              style: TextStyle(
                  color: _pink, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(BuildContext context, Profile p) {
    final n = p.videoIds.length;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(profile: p)),
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Avatar(path: p.avatarPath, name: p.name, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$n videos',
                    style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
