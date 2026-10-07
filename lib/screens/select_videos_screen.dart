import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/thumb.dart';

/// Grid of every device video. Pick which ones belong to [profile].
class SelectVideosScreen extends StatefulWidget {
  const SelectVideosScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<SelectVideosScreen> createState() => _SelectVideosScreenState();
}

class _SelectVideosScreenState extends State<SelectVideosScreen> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.profile.videoIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final videos = state.videos;

    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        foregroundColor: Colors.white,
        title: Text('Select videos · ${_selected.length}'),
        actions: [
          TextButton(
            onPressed: () async {
              await state.setProfileVideos(widget.profile.id, _selected.toList());
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Done',
                style: TextStyle(
                    color: Color(0xFFFF2D78), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: videos.isEmpty
          ? const Center(
              child: Text('Kono video pawa jay ni',
                  style: TextStyle(color: Colors.white54)))
          : GridView.builder(
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
                final owner = state.ownerOf(asset.id);
                final ownedByOther = owner != null && owner.id != widget.profile.id;
                final selected = _selected.contains(asset.id);
                return _Cell(
                  asset: asset,
                  selected: selected,
                  ownedByOther: ownedByOther,
                  otherName: ownedByOther ? owner.name : null,
                  onTap: ownedByOther
                      ? null
                      : () => setState(() {
                            if (selected) {
                              _selected.remove(asset.id);
                            } else {
                              _selected.add(asset.id);
                            }
                          }),
                );
              },
            ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.asset,
    required this.selected,
    required this.ownedByOther,
    this.otherName,
    this.onTap,
  });

  final AssetEntity asset;
  final bool selected;
  final bool ownedByOther;
  final String? otherName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Thumb(
          asset: asset,
          width: 200,
          height: 267,
          selected: selected,
          onTap: onTap,
        ),
        if (ownedByOther)
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Colors.white38, size: 20),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '@$otherName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
