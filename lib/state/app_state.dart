import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/profile.dart';
import '../services/db.dart';
import '../services/media_service.dart';

class AppState extends ChangeNotifier {
  AppState(this.db);

  final Db db;

  bool loading = true;
  bool permissionGranted = true;
  List<Profile> profiles = [];
  List<AssetEntity> videos = [];
  String? activeProfileId;

  Map<String, AssetEntity> _byId = {};
  AssetEntity? videoById(String id) => _byId[id];

  void _reindex() {
    _byId = {for (final v in videos) v.id: v};
  }

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();

    profiles = db.getProfiles();
    activeProfileId = db.getActiveProfileId();
    videos = await MediaService.loadVideos();
    permissionGranted = await MediaService.requestPermission();
    _reindex();

    loading = false;
    notifyListeners();
  }

  Future<void> refreshVideos() async {
    videos = await MediaService.loadVideos();
    _reindex();
    notifyListeners();
  }

  /// Videos not assigned to any profile -> the "For You" feed.
  List<AssetEntity> get forYou {
    final assigned = <String>{};
    for (final p in profiles) {
      assigned.addAll(p.videoIds);
    }
    return videos.where((v) => !assigned.contains(v.id)).toList();
  }

  Profile? get activeProfile {
    for (final p in profiles) {
      if (p.id == activeProfileId) return p;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  List<AssetEntity> videosOf(Profile p) =>
      p.videoIds.map((id) => _byId[id]).whereType<AssetEntity>().toList();

  /// Which profile (if any) currently owns this video id.
  Profile? ownerOf(String videoId) {
    for (final p in profiles) {
      if (p.videoIds.contains(videoId)) return p;
    }
    return null;
  }

  Future<void> _persist() async {
    await db.saveProfiles(profiles);
    await db.setActiveProfileId(activeProfileId);
    notifyListeners();
  }

  Future<void> setActiveProfile(String? id) async {
    activeProfileId = id;
    await db.setActiveProfileId(id);
    notifyListeners();
  }

  Future<Profile> createProfile({
    required String name,
    String bio = '',
    String? avatarPath,
  }) async {
    final p = Profile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      bio: bio,
      avatarPath: avatarPath,
    );
    profiles = [...profiles, p];
    activeProfileId ??= p.id;
    await _persist();
    return p;
  }

  Future<void> updateProfile(Profile updated) async {
    profiles = [
      for (final p in profiles)
        if (p.id == updated.id) updated else p,
    ];
    await _persist();
  }

  Future<void> deleteProfile(String id) async {
    profiles = profiles.where((p) => p.id != id).toList();
    if (activeProfileId == id) {
      activeProfileId = profiles.isEmpty ? null : profiles.first.id;
    }
    await _persist();
  }

  /// Assign a video to a profile. Removes it from any other profile first.
  Future<void> assign(String videoId, String profileId) async {
    profiles = [
      for (final p in profiles)
        if (p.id == profileId)
          (p.videoIds.contains(videoId)
              ? p
              : (p..videoIds = [...p.videoIds, videoId]))
        else
          (p.videoIds.contains(videoId)
              ? (p..videoIds = p.videoIds.where((v) => v != videoId).toList())
              : p),
    ];
    await _persist();
  }

  Future<void> unassign(String videoId) async {
    profiles = [
      for (final p in profiles)
        if (p.videoIds.contains(videoId))
          (p..videoIds = p.videoIds.where((v) => v != videoId).toList())
        else
          p,
    ];
    await _persist();
  }

  /// Bulk set of a profile's video list (used by the select-videos grid).
  Future<void> setProfileVideos(String profileId, List<String> videoIds) async {
    final others = <String>{};
    for (final p in profiles) {
      if (p.id != profileId) others.addAll(p.videoIds);
    }
    // A video can only live on one profile; last write wins for this profile.
    final clean = videoIds.where((id) => !others.contains(id)).toList();
    profiles = [
      for (final p in profiles)
        if (p.id == profileId) (p..videoIds = clean) else p,
    ];
    await _persist();
  }
}
