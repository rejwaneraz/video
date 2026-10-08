import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/profile.dart';
import '../models/video_source.dart';
import '../state/app_state_scope.dart';
import 'avatar.dart';

/// One page of a vertical feed. Owns its VideoPlayerController.
/// Video is shown *contained* (letterbox) so nothing is ever cropped.
class VideoPage extends StatefulWidget {
  const VideoPage({
    super.key,
    required this.source,
    required this.isActive,
    this.ownerName,
    this.owner,
    this.onFollow,
    this.following = false,
    this.onAssign,
    this.onOpenProfile,
    this.onOpenComments,
    this.showAssign = true,
  });

  final VideoSource source;
  final bool isActive;
  final String? ownerName;

  /// Owner profile (drives the rail avatar + follow badge).
  final Profile? owner;
  final VoidCallback? onFollow;
  final bool following;

  final VoidCallback? onAssign;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenComments;
  final bool showAssign;

  @override
  State<VideoPage> createState() => VideoPageState();
}

class VideoPageState extends State<VideoPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  VideoPlayerController? _c;
  bool _initializing = false;
  bool _ready = false;
  bool _error = false;

  late final AnimationController _disc = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

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
    _disc.dispose();
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

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline app — share ekhane somvob na (copy only).'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
    final id = widget.source.id;
    final saved = state.engage.isSaved(id);
    final bookmarks = state.engage.bookmarkCount(id) + (saved ? 1 : 0);
    final shares = state.engage.shareCount(id);

    return Positioned(
      right: 8,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.owner != null) _ownerAvatar(),
          _railButton(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            label: _fmt(likes),
            color: liked ? const Color(0xFFFF2D78) : Colors.white,
            onTap: () => state.toggleLike(id),
          ),
          _railButton(
            icon: Icons.mode_comment_outlined,
            label: _fmt(comments),
            onTap: widget.onOpenComments,
          ),
          _railButton(
            icon: saved ? Icons.bookmark : Icons.bookmark_border,
            label: _fmt(bookmarks),
            color: saved ? const Color(0xFFFFC53D) : Colors.white,
            onTap: () => state.toggleSave(id),
          ),
          _railButton(
            icon: Icons.reply_rounded,
            label: _fmt(shares),
            onTap: _share,
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
          _musicDisc(),
        ],
      ),
    );
  }

  Widget _ownerAvatar() {
    final o = widget.owner;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        width: 46,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.onOpenProfile,
              child: Avatar(
                path: o?.avatarPath,
                name: o?.name ?? '',
                size: 44,
              ),
            ),
            Positioned(
              bottom: -7,
              child: GestureDetector(
                onTap: widget.onFollow,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.following
                        ? Colors.grey.shade600
                        : const Color(0xFFFF2D78),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    widget.following ? Icons.check : Icons.add,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _musicDisc() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: RotationTransition(
        turns: _disc,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A2A32),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.music_note, size: 18, color: Colors.white),
        ),
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
