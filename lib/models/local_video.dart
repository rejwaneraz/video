class LocalVideo {
  String id;
  String srcAssetId;
  String path; // private .mtv copy inside app storage
  String? thumbPath; // private .jpg thumbnail
  String title;
  int width;
  int height;
  int durationSec;
  int addedAt;

  LocalVideo({
    required this.id,
    required this.srcAssetId,
    required this.path,
    this.thumbPath,
    this.title = '',
    this.width = 0,
    this.height = 0,
    this.durationSec = 0,
    int? addedAt,
  }) : addedAt = addedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'srcAssetId': srcAssetId,
        'path': path,
        'thumbPath': thumbPath,
        'title': title,
        'width': width,
        'height': height,
        'durationSec': durationSec,
        'addedAt': addedAt,
      };

  factory LocalVideo.fromMap(Map<String, dynamic> m) => LocalVideo(
        id: m['id'] as String,
        srcAssetId: (m['srcAssetId'] ?? '') as String,
        path: m['path'] as String,
        thumbPath: m['thumbPath'] as String?,
        title: (m['title'] ?? '') as String,
        width: (m['width'] ?? 0) as int,
        height: (m['height'] ?? 0) as int,
        durationSec: (m['durationSec'] ?? 0) as int,
        addedAt: (m['addedAt'] ?? 0) as int,
      );
}
