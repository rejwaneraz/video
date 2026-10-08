import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/local_video.dart';

/// Copies selected device videos into the app's private internal storage so
/// they survive deletion of the originals and stay invisible to other apps.
class VideoStore extends ChangeNotifier {
  late Directory videosDir;
  late Directory thumbsDir;

  int total = 0;
  int done = 0;
  bool copying = false;
  String? current;

  Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    videosDir = Directory(p.join(base.path, 'videos'));
    thumbsDir = Directory(p.join(base.path, 'thumbs'));
    if (!await videosDir.exists()) await videosDir.create(recursive: true);
    if (!await thumbsDir.exists()) await thumbsDir.create(recursive: true);
  }

  double get progress => total == 0 ? 0 : done / total;

  String _newId(int i) =>
      '${DateTime.now().microsecondsSinceEpoch}_$i';

  Future<LocalVideo> copyAsset(AssetEntity a, int seq) async {
    final id = _newId(seq);
    final src = await a.originFile ?? await a.file;
    final destPath = p.join(videosDir.path, '$id.mtv');

    if (src != null && src.existsSync()) {
      await src.copy(destPath);
    }

    String? thumbPath;
    try {
      final bytes = await a.thumbnailDataWithSize(
        const ThumbnailSize(360, 480),
        quality: 80,
      );
      if (bytes != null) {
        thumbPath = p.join(thumbsDir.path, '$id.jpg');
        await File(thumbPath).writeAsBytes(bytes);
      }
    } catch (_) {
      thumbPath = null;
    }

    return LocalVideo(
      id: id,
      srcAssetId: a.id,
      path: destPath,
      thumbPath: thumbPath,
      title: a.title ?? '',
      width: a.width,
      height: a.height,
      durationSec: a.duration,
    );
  }

  /// Copies every asset sequentially with progress. Skips assets already
  /// copied (matched by srcAssetId) and returns the existing entries for them.
  Future<List<LocalVideo>> copyAll(
    List<AssetEntity> assets, {
    required List<LocalVideo> existing,
  }) async {
    final bySrc = {for (final v in existing) v.srcAssetId: v};
    final out = <LocalVideo>[];
    final toCopy = <AssetEntity>[];

    for (final a in assets) {
      final prev = bySrc[a.id];
      if (prev != null && File(prev.path).existsSync()) {
        out.add(prev);
      } else {
        toCopy.add(a);
      }
    }

    total = toCopy.length;
    done = 0;
    copying = toCopy.isNotEmpty;
    notifyListeners();

    var seq = 0;
    for (final a in toCopy) {
      current = a.title ?? 'video';
      notifyListeners();
      try {
        final v = await copyAsset(a, seq++);
        out.add(v);
      } catch (_) {
        // skip unreadable asset
      }
      done++;
      notifyListeners();
    }

    copying = false;
    current = null;
    notifyListeners();
    return out;
  }

  Future<void> deleteFiles(LocalVideo v) async {
    try {
      final f = File(v.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final t = v.thumbPath;
    if (t != null) {
      try {
        final f = File(t);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}
