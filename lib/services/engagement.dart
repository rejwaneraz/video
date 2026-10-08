import '../data/comment_pool.dart';
import 'db.dart';

/// One auto comment with a deterministic author identity.
class NamedComment {
  const NamedComment(this.name, this.username, this.text, this.photo, this.person);
  final String name;
  final String username;
  final String text;

  /// Index into kCommenterAvatars.
  final int photo;

  /// Index into kPeople, used to build a stable fake-profile id ("cm<person>").
  final int person;
}

/// Per-video likes + comments. A deterministic "auto" layer (stable per video)
/// plus user-added comments/likes persisted in [Db].
class Engagement {
  Engagement(this.db);

  final Db db;

  final Set<String> _liked = {};
  final Set<String> _saved = {};
  final Map<String, List<String>> _userComments = {};

  void load() {
    _liked
      ..clear()
      ..addAll(db.getLikedIds());
    _saved
      ..clear()
      ..addAll(db.getSavedIds());
    _userComments
      ..clear()
      ..addAll(db.getUserComments());
  }

  /// Everything the user has engaged with (used by the Inbox).
  Set<String> get likedIds => Set<String>.unmodifiable(_liked);
  Map<String, List<String>> get allUserComments => _userComments;

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

  /// Deterministic play count for a video (stable across runs).
  int viewCount(String id) => 1000 + (hashId(id) % 2000000);

  /// Deterministic per-profile stats (offline "fake" numbers).
  int followers(String profileId) => 100 + (hashId('${profileId}_fl') % 500000);
  int following(String profileId) => hashId('${profileId}_fg') % 900;
  int profileLikes(String profileId) =>
      1000 + (hashId('${profileId}_lk') % 2000000);

  /// Deterministic bookmark / share counts shown on the rail.
  int bookmarkCount(String id) => 50 + (hashId('${id}_bm') % 20000);
  int shareCount(String id) => 10 + (hashId('${id}_sh') % 5000);

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

  bool isSaved(String id) => _saved.contains(id);

  Future<void> toggleSave(String id) async {
    if (_saved.contains(id)) {
      _saved.remove(id);
    } else {
      _saved.add(id);
    }
    await db.saveSavedIds(_saved);
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

  /// Auto comments paired with a deterministic author identity.
  List<NamedComment> autoCommentsNamed(String id) {
    final h = hashId(id);
    final n = 4 + (h % 8); // 4..11 comments
    final start = h % kCommentPool.length;
    final nStart = h % kPeople.length;
    final out = <NamedComment>[];
    for (var i = 0; i < n; i++) {
      final idx = (nStart + i * 5) % kPeople.length;
      final p = kPeople[idx];
      out.add(NamedComment(
        p.name,
        p.username,
        kCommentPool[(start + i * 7) % kCommentPool.length],
        p.photo,
        idx,
      ));
    }
    return out;
  }

  /// Stable fake-profile id for a commenter index (drives deterministic stats).
  static String commenterId(int person) => 'cm$person';

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
