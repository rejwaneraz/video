import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import 'local_video.dart';

/// Where a playable video comes from: a private local copy, or a device asset.
class VideoSource {
  VideoSource({
    required this.id,
    this.local,
    this.asset,
  });

  final String id;
  final LocalVideo? local;
  final AssetEntity? asset;

  factory VideoSource.fromLocal(LocalVideo v) =>
      VideoSource(id: v.id, local: v);

  factory VideoSource.fromAsset(AssetEntity a) =>
      VideoSource(id: a.id, asset: a);

  String get title => local?.title ?? asset?.title ?? '';

  Duration get duration =>
      Duration(seconds: local?.durationSec ?? asset?.duration ?? 0);

  /// Local copied file if present and exists.
  File? get localFile {
    final p = local?.path;
    if (p == null) return null;
    final f = File(p);
    return f.existsSync() ? f : null;
  }

  /// Local thumbnail jpg if present.
  File? get localThumb {
    final p = local?.thumbPath;
    if (p == null) return null;
    final f = File(p);
    return f.existsSync() ? f : null;
  }

  /// Resolve a playable file: local copy first, else the device original.
  Future<File?> resolveFile() async {
    final lf = localFile;
    if (lf != null) return lf;
    final a = asset;
    if (a == null) return null;
    var f = await a.originFile;
    f ??= await a.file;
    return f;
  }
}
