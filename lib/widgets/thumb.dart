import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/video_source.dart';

/// Thumbnail for a [VideoSource]: local jpg first, else device asset thumb.
class VideoThumb extends StatefulWidget {
  const VideoThumb({
    super.key,
    required this.source,
    this.width = 160,
    this.height = 213, // ~3:4 grid cell
    this.selected,
    this.viewsLabel,
    this.onTap,
    this.onLongPress,
  });

  final VideoSource source;
  final double width;
  final double height;
  final bool? selected;

  /// When set, shows a "▶ <count>" chip at the bottom-left (profile grid).
  final String? viewsLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<VideoThumb> {
  Uint8List? _bytes;
  File? _local;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VideoThumb old) {
    super.didUpdateWidget(old);
    if (old.source.id != widget.source.id) _load();
  }

  Future<void> _load() async {
    final lf = widget.source.localThumb;
    if (lf != null) {
      if (!mounted) return;
      setState(() {
        _local = lf;
        _loading = false;
      });
      return;
    }
    final a = widget.source.asset;
    if (a != null) {
      final bytes = await a.thumbnailDataWithSize(
        ThumbnailSize(widget.width.toInt(), widget.height.toInt()),
        quality: 70,
      );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String get _dur {
    final d = widget.source.duration;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_local != null)
              Image.file(_local!, fit: BoxFit.cover)
            else if (_bytes != null)
              Image.memory(_bytes!, fit: BoxFit.cover)
            else
              Container(
                color: const Color(0xFF1A1A1E),
                child: const Icon(Icons.movie, color: Colors.white24),
              ),
            if (_loading)
              const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _dur,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            if (viewsLabel != null)
              Positioned(
                left: 4,
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 13, color: Colors.white),
                    const SizedBox(width: 1),
                    Text(
                      viewsLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                      ),
                    ),
                  ],
                ),
              ),
            if (sel != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: sel ? const Color(0x33FF2D78) : Colors.transparent,
                  border: Border.all(
                    color: sel ? const Color(0xFFFF2D78) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sel ? const Color(0xFFFF2D78) : Colors.black45,
                    border: Border.all(color: Colors.white70),
                  ),
                  child: sel
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
