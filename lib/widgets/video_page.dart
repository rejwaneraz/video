import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

/// One page of the vertical feed. Owns its VideoPlayerController and
/// disposes it when the page is disposed.
class VideoPage extends StatefulWidget {
  const VideoPage({
    super.key,
    required this.asset,
    required this.isActive,
    this.caption,
    this.ownerName,
    this.ownerAvatar,
    this.onAssign,
    this.onOpenProfile,
  });

  final AssetEntity asset;
  final bool isActive;
  final String? caption;
  final String? ownerName;
  final String? ownerAvatar;
  final VoidCallback? onAssign;
  final VoidCallback? onOpenProfile;

  @override
  State<VideoPage> createState() => VideoPageState();
}

class VideoPageState extends State<VideoPage> with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _initializing = false;
  bool _ready = false;
  bool _error = false;
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.asset
        .thumbnailDataWithSize(const ThumbnailSize(360, 480), quality: 70)
        .then((b) {
      if (mounted) setState(() => _thumb = b);
    });
    if (widget.isActive) _init();
  }

  @override
  void didUpdateWidget(covariant VideoPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      if (_ready) {
        _c?.play();
      } else if (!_initializing && _c == null) {
        _init();
      }
    } else if (!widget.isActive && old.isActive) {
      _c?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive || _c == null) return;
    if (state == AppLifecycleState.resumed) {
      _c!.play();
    } else {
      _c!.pause();
    }
  }

  Future<void> _init() async {
    if (_initializing || _c != null) return;
    _initializing = true;

    // Prefer the original file; fall back to a cached copy.
    File? file = await widget.asset.originFile;
    file ??= await widget.asset.file;
    if (file == null) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = true;
      });
      return;
    }

    final controller = VideoPlayerController.file(file);
    _c = controller;
    try {
      await controller.initialize();
    } catch (_) {
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _initializing = false;
        _error = true;
      });
      controller.dispose();
      _c = null;
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    await controller.setLooping(true);
    setState(() {
      _ready = true;
      _initializing = false;
    });
    controller.addListener(_onTick);
    if (widget.isActive) controller.play();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.removeListener(_onTick);
    _c?.dispose();
    _c = null;
    super.dispose();
  }

  void togglePlay() {
    final c = _c;
    if (c == null || !_ready) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  void seekRelative(Duration d) {
    final c = _c;
    if (c == null || !_ready) return;
    var t = c.value.position + d;
    if (t < Duration.zero) t = Duration.zero;
    if (t > c.value.duration) t = c.value.duration;
    c.seekTo(t);
  }

  void toggleMute() {
    final c = _c;
    if (c == null || !_ready) return;
    setState(() {
      c.setVolume(c.value.volume == 0 ? 1 : 0);
    });
  }

  double get progress {
    final c = _c;
    if (c == null || !_ready) return 0;
    final total = c.value.duration.inMilliseconds;
    if (total == 0) return 0;
    return (c.value.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  bool get isMuted => _c?.value.volume == 0;
  bool get isPaused => !(_c?.value.isPlaying ?? false);
  bool get isReady => _ready;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: togglePlay,
      onDoubleTapDown: (d) => _doubleTap(d, size),
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_ready && _c != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _c!.value.aspectRatio,
                  child: VideoPlayer(_c!),
                ),
              )
            else if (_thumb != null)
              SizedBox.expand(
                child: Image.memory(_thumb!, fit: BoxFit.cover),
              ),
            if (!_ready && !_error)
              const CircularProgressIndicator(color: Color(0xFFFF2D78)),
            if (_error)
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                  SizedBox(height: 8),
                  Text('Video load kora jay ni',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            if (_ready && isPaused)
              const Icon(Icons.play_arrow, color: Colors.white38, size: 72),
            Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFFFF2D78)),
              ),
            ),
            _buildCaption(context),
            _buildRail(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    final title = widget.caption ?? widget.asset.title ?? '';
    final owner = widget.ownerName;
    return Positioned(
      left: 12,
      right: 76,
      bottom: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (owner != null && owner.isNotEmpty)
            Text(
              '@$owner',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onOpenProfile != null)
            _railButton(
              icon: Icons.person_rounded,
              label: widget.ownerName ?? 'Profile',
              onTap: widget.onOpenProfile,
            ),
          _railButton(
            icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            label: isMuted ? 'Unmute' : 'Mute',
            onTap: toggleMute,
          ),
          _railButton(
            icon: Icons.playlist_add_rounded,
            label: 'Assign',
            onTap: widget.onAssign,
          ),
        ],
      ),
    );
  }

  Widget _railButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _doubleTap(TapDownDetails d, Size size) {
    final seek = Duration(seconds: 10);
    if (d.globalPosition.dx < size.width / 2) {
      seekRelative(-seek);
    } else {
      seekRelative(seek);
    }
  }
}
