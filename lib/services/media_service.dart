import 'package:photo_manager/photo_manager.dart';

class MediaService {
  /// Requests media permission. Returns true if (limited or full) access granted.
  static Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.hasAccess;
  }

  /// Loads all device videos, newest first.
  static Future<List<AssetEntity>> loadVideos() async {
    final ok = await requestPermission();
    if (!ok) return [];

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );
    if (paths.isEmpty) return [];

    final all = <AssetEntity>[];
    for (final path in paths) {
      final count = await path.assetCountAsync;
      const page = 200;
      for (var start = 0; start < count; start += page) {
        final batch = await path.getAssetListPaged(
          page: start ~/ page,
          size: page,
        );
        all.addAll(batch);
      }
    }
    return all;
  }
}
