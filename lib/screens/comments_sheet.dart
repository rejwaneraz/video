import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';

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
    final auto = state.engage.autoComments(widget.videoId);
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
                  for (final c in user)
                    _row(c, mine: true),
                  for (final c in auto)
                    _row(c, mine: false),
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

  Widget _row(String text, {required bool mine}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: mine ? const Color(0xFFFF2D78) : Colors.white12,
            child: Icon(
              mine ? Icons.person : Icons.smart_toy_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : Colors.white70,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
