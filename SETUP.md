# Mini TikTok (offline) — setup

A Flutter app: vertical "For You" feed of your device videos, swipe left to open
profiles, assign videos to profiles, avatars + bios, 3-column 3:4 grid.

## 1. Generate the platform folders

This repo ships only the Dart source + `pubspec.yaml`. In this folder run:

```bash
flutter create . --project-name mini_tiktok --platforms=android,ios
```

That creates `android/`, `ios/`, etc. It will NOT overwrite `lib/` or `pubspec.yaml`
if you answer no to replacing them — but to be safe, back those up first. If it
overwrites `lib/main.dart`, restore the one from this repo.

Then:

```bash
flutter pub get
```

## 2. Android permissions

Edit `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`
(above `<application>`):

```xml
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

In `android/app/build.gradle` set a min SDK that photo_manager supports:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        // ...
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

## 3. iOS permissions

Edit `ios/Runner/Info.plist` and add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>App ta apnar video gulo dekhanor jonno photo library access chay.</string>
```

Also ensure the iOS deployment target is >= 12 in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

## 4. Run / build

```bash
flutter run                    # debug
flutter run --release          # real performance
flutter build apk --release    # Android APK -> build/app/outputs/flutter-apk/
```

## Features

- **For You**: vertical swipe feed of every device video that isn't assigned.
  - Tap = pause/play, double-tap left/right = seek ∓10s, rail = mute / assign / profile.
- **Swipe left** from the feed → Profile tab.
- **Profiles**: avatar (pick photo), name, bio. Create / edit / delete.
- **Assign**: any video → one profile. Assigned videos leave For You and appear
  on that profile's 3×(3:4) grid.
- **Select videos**: grid picker to bulk-assign a profile's videos.
- Multiple profiles via the switcher row at the top of the Profile tab.

## Structure

```
lib/
  main.dart                      app entry, theme, bootstrap
  models/profile.dart            Profile model + JSON
  services/db.dart               shared_preferences persistence
  services/media_service.dart    photo_manager video loading + permissions
  state/app_state.dart           ChangeNotifier: profiles, videos, assign logic
  state/app_state_scope.dart     InheritedNotifier to read state
  screens/home.dart              horizontal pager (feed | profile)
  screens/feed_page.dart         For You vertical feed + empty state
  screens/profile_screen.dart    profile header, grid, switcher, ProfileFeed player
  screens/edit_profile_screen.dart  create/edit profile + avatar picker
  screens/select_videos_screen.dart bulk video picker
  screens/assign_sheet.dart      bottom sheet to assign a video
  widgets/video_page.dart        the player page (autoplay, loop, lifecycle-aware)
  widgets/avatar.dart            avatar with initials fallback + gradient ring
  widgets/thumb.dart             cached video thumbnail w/ duration + checkbox
```

## Notes / known limits

- A video belongs to at most one profile (keeps For You clean). Re-assigning moves it.
- `originFile` is used first, falling back to a cached copy — iCloud-only videos
  may return null and show "Video load kora jay ni".
- Data (profiles + assignments) is stored via `shared_preferences`; avatars are
  copied into the app documents dir. No backend, fully offline.
