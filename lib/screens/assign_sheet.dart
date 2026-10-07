import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';
import 'edit_profile_screen.dart';

/// Bottom sheet: assign the given video to a profile (or remove it).
Future<void> showAssignSheet(BuildContext context, String videoId) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF17171B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => AssignSheet(videoId: videoId),
  );
}

class AssignSheet extends StatelessWidget {
  const AssignSheet({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final current = state.ownerOf(videoId);
    const pink = Color(0xFFFF2D78);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Assign to profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              current == null
                  ? 'For You feed-e ache. Ekta profile-e add korun.'
                  : 'Ekhon @${current.name} er profile-e ache.',
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            if (state.profiles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Kono profile nei. Age ekta profile banan.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in state.profiles)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Avatar(path: p.avatarPath, name: p.name, size: 40),
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: current?.id == p.id
                            ? const Icon(Icons.check_circle, color: pink)
                            : const Icon(Icons.circle_outlined,
                                color: Colors.white24),
                        onTap: () async {
                          if (current?.id == p.id) {
                            await state.unassign(videoId);
                          } else {
                            await state.assign(videoId, p.id);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt, color: pink),
                    label: const Text('New profile',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                if (current != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await state.unassign(videoId);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.white70),
                      label: const Text('Remove',
                          style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
