import 'package:flutter/material.dart';

import '../data/comment_pool.dart';
import '../state/app_state_scope.dart';
import 'commenter_profile_screen.dart';

/// Bottom sheet listing auto + user comments, with an input to add your own.
Future<void> showCommentsSheet(BuildContext context, String videoId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF17171B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => CommentsSheet(videoId: videoId),
  );
}

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.videoId});

  final String videoId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    await AppStateScope.read(context).addComment(widget.videoId, t);
    _ctrl.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final auto = state.engage.autoCommentsNamed(widget.videoId);
    final user = state.engage.userComments(widget.videoId);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${auto.length + user.length} comments',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final c in user) _row('You', c, mine: true),
                  for (final c in auto)
                    _row(
                      c.name,
                      c.text,
                      mine: false,
                      username: c.username,
                      avatarAsset: c.photo >= 0 && c.photo < kCommenterAvatars.length
                          ? kCommenterAvatars[c.photo]
                          : null,
                      onTapIdentity: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommenterProfileScreen(person: c.person),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Comment likhun...',
                        hintStyle: TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Color(0xFF232329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Color(0xFFFF2D78)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String name, String text,
      {required bool mine,
      String? username,
      String? avatarAsset,
      VoidCallback? onTapIdentity}) {
    final avatar = _avatar(name, mine: mine, asset: avatarAsset);
    final nameRow = Row(
      children: [
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mine ? const Color(0xFFFF2D78) : Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (username != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              username,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onTapIdentity == null
              ? avatar
              : GestureDetector(onTap: onTapIdentity, child: avatar),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                onTapIdentity == null
                    ? nameRow
                    : GestureDetector(onTap: onTapIdentity, child: nameRow),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Deterministic gradient initial-avatar per commenter name.
  Widget _avatar(String name, {required bool mine, String? asset}) {
    final fallback = _gradientAvatar(name, mine: mine);
    if (asset == null) return fallback;
    return ClipOval(
      child: Image.asset(
        asset,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _gradientAvatar(String name, {required bool mine}) {
    const palette = [
      Color(0xFFFF2D78),
      Color(0xFF7C4DFF),
      Color(0xFF00B8D4),
      Color(0xFFFF6D00),
      Color(0xFF00C853),
      Color(0xFF3D5AFE),
      Color(0xFFD81B60),
      Color(0xFF00897B),
    ];
    var h = 0;
    for (final cu in name.codeUnits) {
      h = (h * 31 + cu) & 0x7fffffff;
    }
    final c = mine ? const Color(0xFFFF2D78) : palette[h % palette.length];
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [c, c.withOpacity(0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: mine
          ? const Icon(Icons.person, size: 16, color: Colors.white)
          : Text(
              initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
    );
  }
}
