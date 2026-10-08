import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/local_video.dart';
import '../models/profile.dart';
import '../models/video_source.dart';
import '../services/db.dart';
import '../services/engagement.dart';
import '../services/media_service.dart';
import '../services/video_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.db) {
    store = VideoStore();
    engage = Engagement(db);
  }

  final Db db;
  late final VideoStore store;
  late final Engagement engage;

  bool loading = true;
  bool permissionGranted = true;

  List<Profile> profiles = [];
  List<LocalVideo> localVideos = [];
  List<AssetEntity> deviceVideos = [];
  String? activeProfileId;

  List<String> _forYouOrder = [];

  Map<String, LocalVideo> _localById = {};
  Map<String, AssetEntity> _assetById = {};

  void _reindex() {
    _localById = {for (final v in localVideos) v.id: v};
    _assetById = {for (final a in deviceVideos) a.id: a};
  }

  LocalVideo? localById(String id) => _localById[id];
  AssetEntity? assetById(String id) => _assetById[id];

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();

    await store.init();
    engage.load();
    profiles = db.getProfiles();
    activeProfileId = db.getActiveProfileId();
    localVideos = db.getLocalVideos();
    // Drop entries whose copied file is gone.
    localVideos = localVideos
        .where((v) => v.path.isNotEmpty)
        .toList();
    deviceVideos = await MediaService.loadVideos();
    permissionGranted = await MediaService.requestPermission();
    _reindex();
    _ensureForYouOrder();

    loading = false;
    notifyListeners();
  }

  Future<void> refreshDeviceVideos() async {
    deviceVideos = await MediaService.loadVideos();
    _reindex();
    notifyListeners();
  }

  void _ensureForYouOrder() {
    final ids = localVideos.map((v) => v.id).toList();
    // Keep existing order for known ids, append new ones shuffled.
    final known = _forYouOrder.where(ids.contains).toList();
    final missing = ids.where((id) => !known.contains(id)).toList()
      ..shuffle(Random());
    _forYouOrder = [...known, ...missing];
  }

  void shuffleForYou() {
    _forYouOrder = localVideos.map((v) => v.id).toList()..shuffle(Random());
    notifyListeners();
  }

  /// For You = every copied video, shuffled.
  List<VideoSource> get forYou {
    _ensureForYouOrder();
    return _forYouOrder
        .map((id) => _localById[id])
        .whereType<LocalVideo>()
        .map(VideoSource.fromLocal)
        .toList();
  }

  /// All Videos = everything currently on the phone.
  List<VideoSource> get allVideos =>
      deviceVideos.map(VideoSource.fromAsset).toList();

  Profile? get activeProfile {
    for (final p in profiles) {
      if (p.id == activeProfileId) return p;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  /// Ordered videos of a profile.
  List<VideoSource> sourcesOf(Profile p) => p.videoIds
      .map((id) => _localById[id])
      .whereType<LocalVideo>()
      .map(VideoSource.fromLocal)
      .toList();

  /// First profile that contains this local video id.
  Profile? ownerOfLocal(String localId) {
    for (final p in profiles) {
      if (p.videoIds.contains(localId)) return p;
    }
    return null;
  }

  /// Owner of whatever a source points at (local id, or asset mapped to local).
  Profile? ownerOfSource(VideoSource s) {
    if (s.local != null) return ownerOfLocal(s.id);
    final lv = localVideos.firstWhere(
      (v) => v.srcAssetId == s.id,
      orElse: () => LocalVideo(id: '', srcAssetId: '', path: ''),
    );
    if (lv.id.isEmpty) return null;
    return ownerOfLocal(lv.id);
  }

  Future<void> _persist() async {
    await db.saveProfiles(profiles);
    await db.setActiveProfileId(activeProfileId);
    await db.saveLocalVideos(localVideos);
    notifyListeners();
  }

  Future<void> setActiveProfile(String? id) async {
    activeProfileId = id;
    await db.setActiveProfileId(id);
    notifyListeners();
  }

  Future<void> toggleLike(String id) async {
    await engage.toggleLike(id);
    notifyListeners();
  }

  Future<void> addComment(String id, String text) async {
    await engage.addComment(id, text);
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
    profiles = [for (final p in profiles) if (p.id == updated.id) updated else p];
    await _persist();
  }

  Future<void> deleteProfile(String id) async {
    profiles = profiles.where((p) => p.id != id).toList();
    if (activeProfileId == id) {
      activeProfileId = profiles.isEmpty ? null : profiles.first.id;
    }
    await _persist();
  }

  /// Copies [assets] into private storage (skipping already-copied) and sets
  /// the profile's ordered video list to exactly these.
  Future<void> importToProfile(String profileId, List<AssetEntity> assets) async {
    final copied = await store.copyAll(assets, existing: localVideos);
    // Merge new copies into localVideos.
    final known = {..._localById};
    for (final v in copied) {
      known[v.id] = v;
    }
    localVideos = known.values.toList();
    _reindex();

    final ids = copied.map((v) => v.id).toList();
    profiles = [
      for (final p in profiles) if (p.id == profileId) (p..videoIds = ids) else p,
    ];
    _ensureForYouOrder();
    await _persist();
  }

  /// Add (append) videos to a profile without removing existing order.
  Future<void> addToProfile(String profileId, List<AssetEntity> assets) async {
    final copied = await store.copyAll(assets, existing: localVideos);
    final known = {..._localById};
    for (final v in copied) {
      known[v.id] = v;
    }
    localVideos = known.values.toList();
    _reindex();

    profiles = [
      for (final p in profiles)
        if (p.id == profileId)
          (p
            ..videoIds = [
              ...p.videoIds,
              ...copied.map((v) => v.id).where((id) => !p.videoIds.contains(id)),
            ])
        else
          p,
    ];
    _ensureForYouOrder();
    await _persist();
  }

  Future<void> removeFromProfile(String profileId, String localId) async {
    profiles = [
      for (final p in profiles)
        if (p.id == profileId)
          (p..videoIds = p.videoIds.where((v) => v != localId).toList())
        else
          p,
    ];
    await _persist();
  }

  Future<void> addLocalToProfile(String profileId, String localId) async {
    profiles = [
      for (final p in profiles)
        if (p.id == profileId && !p.videoIds.contains(localId))
          (p..videoIds = [...p.videoIds, localId])
        else
          p,
    ];
    await _persist();
  }

  Future<void> setProfileVideos(String profileId, List<String> localIds) async {
    profiles = [
      for (final p in profiles)
        if (p.id == profileId) (p..videoIds = List<String>.from(localIds)) else p,
    ];
    await _persist();
  }

  /// Permanently delete a copied video everywhere (frees storage).
  Future<void> deleteLocalVideo(String localId) async {
    final v = _localById[localId];
    if (v == null) return;
    await store.deleteFiles(v);
    localVideos = localVideos.where((x) => x.id != localId).toList();
    profiles = [
      for (final p in profiles)
        (p..videoIds = p.videoIds.where((id) => id != localId).toList()),
    ];
    _forYouOrder = _forYouOrder.where((id) => id != localId).toList();
    _reindex();
    await _persist();
  }
}
