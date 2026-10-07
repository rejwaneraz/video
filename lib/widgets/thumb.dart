import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Async thumbnail for a video asset, with duration badge.
class VideoThumb extends StatefulWidget {
  const VideoThumb({
    super.key,
    required this.asset,
    this.width = 160,
    this.height = 213, // ~3:4 grid cell
    this.selected,
    this.onTap,
  });

  final AssetEntity asset;
  final double width;
  final double height;
  final bool? selected;
  final VoidCallback? onTap;

  @override
  State<VideoThumb> createState() => _ThumbState();
}

class _ThumbState extends State<VideoThumb> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VideoThumb old) {
    super.didUpdateWidget(old);
    if (old.asset.id != widget.asset.id) _load();
  }

  Future<void> _load() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      ThumbnailSize(widget.width.toInt(), widget.height.toInt()),
      quality: 70,
    );
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  String get _dur {
    final d = Duration(seconds: widget.asset.duration);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _bytes != null
                ? Image.memory(_bytes!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF1A1A1E)),
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
