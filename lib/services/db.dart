import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_video.dart';
import '../models/profile.dart';

class Db {
  static const _kProfiles = 'profiles';
  static const _kActiveProfile = 'active_profile';
  static const _kLocalVideos = 'local_videos';
  static const _kLiked = 'liked_ids';
  static const _kUserComments = 'user_comments';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<Profile> getProfiles() {
    final raw = _prefs.getString(_kProfiles);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Profile.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProfiles(List<Profile> profiles) async {
    await _prefs.setString(_kProfiles, Profile.encodeList(profiles));
  }

  String? getActiveProfileId() => _prefs.getString(_kActiveProfile);

  Future<void> setActiveProfileId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kActiveProfile);
    } else {
      await _prefs.setString(_kActiveProfile, id);
    }
  }

  List<LocalVideo> getLocalVideos() {
    final raw = _prefs.getString(_kLocalVideos);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw) as List;
      return data
          .map((e) => LocalVideo.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalVideos(List<LocalVideo> list) async {
    await _prefs.setString(
        _kLocalVideos, jsonEncode(list.map((v) => v.toMap()).toList()));
  }

  Set<String> getLikedIds() {
    return (_prefs.getStringList(_kLiked) ?? []).toSet();
  }

  Future<void> saveLikedIds(Set<String> ids) async {
    await _prefs.setStringList(_kLiked, ids.toList());
  }

  Map<String, List<String>> getUserComments() {
    final raw = _prefs.getString(_kUserComments);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map;
      return data.map((k, v) =>
          MapEntry(k as String, (v as List).map((e) => e.toString()).toList()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveUserComments(Map<String, List<String>> m) async {
    await _prefs.setString(_kUserComments, jsonEncode(m));
  }
}
