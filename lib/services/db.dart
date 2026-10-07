import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

class Db {
  static const _kProfiles = 'profiles';
  static const _kActiveProfile = 'active_profile';

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
}
