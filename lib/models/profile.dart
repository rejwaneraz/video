import 'dart:convert';

class Profile {
  String id;
  String name;
  String bio;
  String? avatarPath;
  List<String> videoIds;
  int createdAt;

  Profile({
    required this.id,
    required this.name,
    this.bio = '',
    this.avatarPath,
    List<String>? videoIds,
    int? createdAt,
  })  : videoIds = videoIds ?? [],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'bio': bio,
        'avatarPath': avatarPath,
        'videoIds': videoIds,
        'createdAt': createdAt,
      };

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        name: (m['name'] ?? '') as String,
        bio: (m['bio'] ?? '') as String,
        avatarPath: m['avatarPath'] as String?,
        videoIds: ((m['videoIds'] ?? []) as List).cast<String>(),
        createdAt: (m['createdAt'] ?? 0) as int,
      );

  static String encodeList(List<Profile> list) =>
      jsonEncode(list.map((p) => p.toMap()).toList());

  static List<Profile> decodeList(String raw) {
    final data = jsonDecode(raw) as List;
    return data
        .map((e) => Profile.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Profile copy() => Profile(
        id: id,
        name: name,
        bio: bio,
        avatarPath: avatarPath,
        videoIds: List<String>.from(videoIds),
        createdAt: createdAt,
      );
}
