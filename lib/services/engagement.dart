import '../data/comment_pool.dart';
import 'db.dart';

/// Per-video likes + comments. A deterministic "auto" layer (stable per video)
/// plus user-added comments/likes persisted in [Db].
class Engagement {
  Engagement(this.db);

  final Db db;

  final Set<String> _liked = {};
  final Map<String, List<String>> _userComments = {};

  void load() {
    _liked
      ..clear()
      ..addAll(db.getLikedIds());
    _userComments
      ..clear()
      ..addAll(db.getUserComments());
  }

  /// Stable FNV-1a hash so counts/comments never change between runs.
  static int hashId(String id) {
    var h = 0x811c9dc5;
    for (final cu in id.codeUnits) {
      h ^= cu;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  int baseLikes(String id) => 420 + (hashId(id) % 96000);

  bool isLiked(String id) => _liked.contains(id);

  int likeCount(String id) => baseLikes(id) + (isLiked(id) ? 1 : 0);

  Future<void> toggleLike(String id) async {
    if (_liked.contains(id)) {
      _liked.remove(id);
    } else {
      _liked.add(id);
    }
    await db.saveLikedIds(_liked);
  }

  /// Deterministic auto comments for a video (stable subset of the pool).
  List<String> autoComments(String id) {
    final h = hashId(id);
    final n = 4 + (h % 8); // 4..11 comments
    final start = h % kCommentPool.length;
    final out = <String>[];
    for (var i = 0; i < n; i++) {
      out.add(kCommentPool[(start + i * 7) % kCommentPool.length]);
    }
    return out;
  }

  List<String> userComments(String id) => _userComments[id] ?? const [];

  List<String> allComments(String id) =>
      [...autoComments(id), ...userComments(id)];

  int commentCount(String id) => allComments(id).length;

  Future<void> addComment(String id, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = List<String>.from(_userComments[id] ?? const []);
    list.add(t);
    _userComments[id] = list;
    await db.saveUserComments(_userComments);
  }
}
