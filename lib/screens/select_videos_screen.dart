import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/profile.dart';
import '../models/video_source.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/thumb.dart';

/// Grid of device videos. Pick which to copy into this profile.
/// Already-copied videos are preselected; new ones get copied on Done.
class SelectVideosScreen extends StatefulWidget {
  const SelectVideosScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<SelectVideosScreen> createState() => _SelectVideosScreenState();
}

class _SelectVideosScreenState extends State<SelectVideosScreen> {
  late Set<String> _selected; // asset ids

  @override
  void initState() {
    super.initState();
    final state = AppStateScope.read(context);
    _selected = {};
    for (final id in widget.profile.videoIds) {
      final lv = state.localById(id);
      if (lv != null) _selected.add(lv.srcAssetId);
    }
  }

  Future<void> _done() async {
    final state = AppStateScope.read(context);
    final assets = state.deviceVideos
        .where((a) => _selected.contains(a.id))
        .toList();
    await state.importToProfile(widget.profile.id, assets);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final videos = state.deviceVideos;

    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        foregroundColor: Colors.white,
        title: Text('Select videos · ${_selected.length}'),
        actions: [
          AnimatedBuilder(
            animation: state.store,
            builder: (context, _) {
              final copying = state.store.copying;
              return TextButton(
                onPressed: copying ? null : _done,
                child: copying
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: state.store.progress,
                          color: const Color(0xFFFF2D78),
                        ),
                      )
                    : const Text('Done',
                        style: TextStyle(
                            color: Color(0xFFFF2D78),
                            fontWeight: FontWeight.w700)),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: state.store,
        builder: (context, child) {
          final store = state.store;
          return Column(
            children: [
              if (store.copying)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1B1B21),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: store.progress,
                        color: const Color(0xFFFF2D78),
                        backgroundColor: Colors.white12,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Copy hocche ${store.done}/${store.total}: ${store.current ?? ""}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Expanded(child: child!),
            ],
          );
        },
        child: videos.isEmpty
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
                  final src = VideoSource.fromAsset(asset);
                  final selected = _selected.contains(asset.id);
                  return VideoThumb(
                    source: src,
                    width: 200,
                    height: 267,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _selected.remove(asset.id);
                      } else {
                        _selected.add(asset.id);
                      }
                    }),
                  );
                },
              ),
      ),
    );
  }
}
