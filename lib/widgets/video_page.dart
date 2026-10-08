import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/video_source.dart';
import '../state/app_state_scope.dart';

/// One page of a vertical feed. Owns its VideoPlayerController.
/// Video is shown *contained* (letterbox) so nothing is ever cropped.
class VideoPage extends StatefulWidget {
  const VideoPage({
    super.key,
    required this.source,
    required this.isActive,
    this.ownerName,
    this.onAssign,
    this.onOpenProfile,
    this.onOpenComments,
    this.showAssign = true,
  });

  final VideoSource source;
  final bool isActive;
  final String? ownerName;
  final VoidCallback? onAssign;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenComments;
  final bool showAssign;

  @override
  State<VideoPage> createState() => VideoPageState();
}

class VideoPageState extends State<VideoPage> with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _initializing = false;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _init();
  }

  @override
  void didUpdateWidget(covariant VideoPage old) {
    super.didUpdateWidget(old);
    if (widget.source.id != old.source.id) {
      _c?.dispose();
      _c = null;
      _ready = false;
      _error = false;
      _initializing = false;
      if (widget.isActive) _init();
      return;
    }
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

    final file = await widget.source.resolveFile();
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
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = true;
      });
      _c = null;
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    await controller.setLooping(true);
    controller.addListener(_onTick);
    if (!mounted) return;
    setState(() {
      _ready = true;
      _initializing = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final state = AppStateScope.of(context);
    final id = widget.source.id;
    final liked = state.engage.isLiked(id);
    final likes = state.engage.likeCount(id);
    final comments = state.engage.commentCount(id);

    return GestureDetector(
      onTap: togglePlay,
      onDoubleTapDown: (d) {
        const seek = Duration(seconds: 10);
        if (d.globalPosition.dx < size.width / 2) {
          seekRelative(-seek);
        } else {
          seekRelative(seek);
        }
      },
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
            else if (widget.source.localThumb != null)
              Center(
                child: Image.file(widget.source.localThumb!,
                    fit: BoxFit.contain),
              )
            else
              const SizedBox.shrink(),
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
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF2D78)),
              ),
            ),
            _buildCaption(),
            _buildRail(liked: liked, likes: likes, comments: comments),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final title = widget.source.title;
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

  Widget _buildRail({
    required bool liked,
    required int likes,
    required int comments,
  }) {
    final state = AppStateScope.read(context);
    return Positioned(
      right: 8,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _railButton(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            label: _fmt(likes),
            color: liked ? const Color(0xFFFF2D78) : Colors.white,
            onTap: () => state.toggleLike(widget.source.id),
          ),
          _railButton(
            icon: Icons.mode_comment_outlined,
            label: _fmt(comments),
            onTap: widget.onOpenComments,
          ),
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
          if (widget.showAssign && widget.onAssign != null)
            _railButton(
              icon: Icons.playlist_add_rounded,
              label: 'Assign',
              onTap: widget.onAssign,
            ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _railButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color color = Colors.white,
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
