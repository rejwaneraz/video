import 'package:flutter/material.dart';

import '../data/comment_pool.dart';
import '../services/engagement.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';

const Color _pink = Color(0xFFFF2D78);
const Color _surface = Color(0xFF111114);
const Color _btnGrey = Color(0xFF2A2A32);

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// Fake profile for an auto-commenter (opened by tapping an identity in the
/// comments sheet). Mirrors the real profile look but always has no videos.
/// Stats/follow/bio are deterministic off the "cm<person>" id.
class CommenterProfileScreen extends StatelessWidget {
  const CommenterProfileScreen({super.key, required this.person});

  final int person;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final idx = person % kPeople.length;
    final p = kPeople[idx];
    final id = Engagement.commenterId(idx);
    final eng = state.engage;
    final following = state.isFollowing(id);
    final bio = kBioPool[Engagement.hashId(id) % kBioPool.length];
    final avatarAsset = (p.photo >= 0 && p.photo < kCommenterAvatars.length)
        ? kCommenterAvatars[p.photo]
        : null;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        title: Text(
          p.username,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Center(child: _avatar(p.name, avatarAsset)),
            const SizedBox(height: 14),
            Center(
              child: Text(
                p.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                p.username,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat(_fmtCount(eng.following(id)), 'Following'),
                const SizedBox(width: 34),
                _stat(_fmtCount(eng.followers(id)), 'Followers'),
                const SizedBox(width: 34),
                _stat(_fmtCount(eng.profileLikes(id)), 'Likes'),
              ],
            ),
            const SizedBox(height: 20),
            _followButton(state, id, following),
            const SizedBox(height: 16),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.3),
            ),
            const SizedBox(height: 28),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'এখনো কোনো ভিডিও নেই',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name, String? asset) {
    final size = 110.0;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_pink, Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0],
        style: const TextStyle(
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
      ),
    );
    final ring = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _pink, width: 2),
      ),
      child: asset == null
          ? fallback
          : ClipOval(
              child: Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
    );
    return ring;
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

  Widget _followButton(AppState state, String id, bool following) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () => state.toggleFollow(id),
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
}
