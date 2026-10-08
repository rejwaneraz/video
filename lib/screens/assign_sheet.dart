import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';
import 'edit_profile_screen.dart';

/// Bottom sheet: add/remove a copied video to/from profiles.
Future<void> showAssignSheet(BuildContext context, String localId) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF17171B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => AssignSheet(localId: localId),
  );
}

class AssignSheet extends StatelessWidget {
  const AssignSheet({super.key, required this.localId});

  final String localId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    const pink = Color(0xFFFF2D78);
    final members = state.profiles
        .where((p) => p.videoIds.contains(localId))
        .map((p) => p.name)
        .toList();

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
              'Add to profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              members.isEmpty
                  ? 'For You te ache. Profile-e add korun.'
                  : 'Ekhon: @${members.join(", @")}',
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
                        leading:
                            Avatar(path: p.avatarPath, name: p.name, size: 40),
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: p.videoIds.contains(localId)
                            ? const Icon(Icons.check_circle, color: pink)
                            : const Icon(Icons.add_circle_outline,
                                color: Colors.white24),
                        onTap: () async {
                          if (p.videoIds.contains(localId)) {
                            await state.removeFromProfile(p.id, localId);
                          } else {
                            await state.addLocalToProfile(p.id, localId);
                          }
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              icon: const Icon(Icons.person_add_alt, color: pink),
              label:
                  const Text('New profile', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
