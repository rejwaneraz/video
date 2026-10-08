# TRD — Technical Requirements & Design ("Videos")

## 1. Stack

- Flutter 3.24.x (CI pins 3.24.3), Dart >=3.0. Android-first.
- Packages: `video_player`, `photo_manager`, `image_picker`, `shared_preferences`,
  `path_provider`, `path`, `local_auth`.
- No backend. Persistence = SharedPreferences (JSON) + files in app-internal dir.
- CI: GitHub Actions (`ubuntu-latest`) generates `android/` via `flutter create`,
  patches gradle/manifest, builds release APK, uploads artifact.

## 2. Architecture

```
lib/
  main.dart                 entry, theme, LockGate (local_auth), title "Videos"
  models/profile.dart       Profile {id,name,bio,avatarPath,videoIds[],createdAt}
  models/local_video.dart   LocalVideo {id,srcAssetId,path,thumbPath,title,w,h,durationSec,addedAt}
  models/video_source.dart  VideoSource {id, local?, asset?} + resolveFile()/localThumb
  data/comment_pool.dart    const 150-comment pool
  services/db.dart          SharedPreferences keys + (de)serialization
  services/media_service.dart  photo_manager permission + paged video load
  services/video_store.dart copy queue -> videos/<id>.mtv + thumbs/<id>.jpg, progress
  services/engagement.dart  FNV hash -> baseLikes/views, autoComments; liked ids; user comments
  state/app_state.dart      ChangeNotifier: profiles, localVideos, deviceVideos, forYou(shuffled),
                            owners, import/add/remove, likes/comments passthrough
  state/app_state_scope.dart InheritedNotifier<AppState>
  screens/home.dart         horizontal pager [Profile, ForYou, AllVideos]  <-- v3: restructure
  screens/feed_page.dart    For You vertical PageView + HomeSwitcher/HomeController
  screens/all_videos_page.dart  device videos vertical PageView
  screens/profile_screen.dart   profile header+grid+switcher, ProfileFeed player
  screens/edit_profile_screen.dart  create/edit profile + avatar pick
  screens/select_videos_screen.dart device grid -> copy+assign with progress
  screens/assign_sheet.dart add/remove a copy to/from profiles
  screens/comments_sheet.dart auto+user comments + input
  widgets/video_page.dart   player page (contain/letterbox, rail, lifecycle-aware)
  widgets/thumb.dart        VideoThumb (local jpg or asset thumb, duration, checkbox)
  widgets/avatar.dart       avatar + initials fallback + gradient ring
```

State flow: single `AppState` ChangeNotifier exposed via `AppStateScope`.
Screens read via `AppStateScope.of(context)` (rebuild) or `.read` (no rebuild).

## 3. Data model & keys (SharedPreferences)

| key | value |
|---|---|
| `profiles` | JSON list of Profile |
| `active_profile` | profile id |
| `local_videos` | JSON list of LocalVideo |
| `liked_ids` | string list |
| `user_comments` | JSON map videoId -> [text] |

Files (app-internal, invisible to other apps / MediaStore):
```
<appDocs>/videos/<id>.mtv      private video copy (custom ext => not indexed)
<appDocs>/thumbs/<id>.jpg      thumbnail saved at copy time
<appDocs>/avatars/av_*.jpg     profile avatars
```

Membership: a video belongs to profiles via `Profile.videoIds` (ordered).
One video may be in many profiles. For You = ALL localVideos (shuffled order kept
in `AppState._forYouOrder`).

## 4. Deterministic engagement (offline "fake" data)

`Engagement.hashId` = FNV-1a over code units (stable across runs).
- likes  = 420 + hash % 96000 (+1 if user liked)
- views  = (v3) derive similarly, e.g. 1000 + hash % 2_000_000
- autoComments = 4..11 stable picks from the 150 pool (stride 7)
- followers/following (v3 profile stats) = hash-derived per profile id
User's own comments/likes persist and are appended/toggled on top.

## 5. Playback

- `VideoPage` owns one `VideoPlayerController`; created only when page active.
- Source resolution: local `.mtv` first, else `asset.originFile ?? asset.file`.
- Layout: `Center(AspectRatio(VideoPlayer))` => **contain/letterbox, never crop**.
- `WidgetsBindingObserver` pauses on background; `didUpdateWidget` play/pause on
  active flip; dispose on page dispose. Tap=pause, double-tap=±10s.

## 6. Copy pipeline

`SelectVideosScreen` -> `AppState.importToProfile(profileId, assets)` ->
`VideoStore.copyAll` (sequential, progress via ChangeNotifier) -> new LocalVideo
entries persisted -> profile.videoIds replaced with selection -> For You updated.
Skips assets already copied (matched by srcAssetId).

## 7. Android / CI specifics

- Manifest perms (injected by CI python step): READ_MEDIA_VIDEO,
  READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE(maxSdk 32), USE_BIOMETRIC,
  USE_FINGERPRINT. `android:label` -> "Videos".
- `compileSdk = 36` patched in CI (photo_manager requirement).
- Workflow: backup lib+pubspec -> `flutter create . --platforms=android` ->
  restore -> patch gradle+manifest -> pub get -> analyze(non-blocking) ->
  build apk -> upload artifact `mini-tiktok-apk`.

## 8. Performance rules

- <=3 live players (PageView builds neighbours only).
- Thumbnails: saved jpg for copies; asset thumbs sized to grid cell; quality 70-80.
- Copy runs off UI thread sequentially; UI shows progress, stays responsive.
- Avoid rebuilding whole feed on engagement change: rail reads state but page
  rebuild is cheap (single page).

## 9. Risks / known issues

- Storage growth: 100s of copies = many GB. Mitigation: long-press delete exists;
  Storage-manager screen planned.
- `photo_manager` titles/thumbs need permission; All Videos empty without it.
- Horizontal pager currently hosts ProfileScreen at index 0 — v3 replaces this
  with a pushed ProfilePage + bottom nav (see PLAN).
- shared_preferences JSON fine for ~10^3 videos; move to sqflite only if needed.

## 10. v3 technical additions (summary)

- New `AppShell` with `BottomNavigationBar` (5 tabs) replacing/augmenting pager.
- New screens: `ProfilesListScreen` (Me), redesigned `ProfilePage` (pushed),
  `InboxScreen` (activity), `SearchOverlay`.
- `Follow` state: new prefs key `followed_profiles`; `Following` top tab = union
  of followed profiles' videos.
- Rail additions: bookmark (`saved_ids`), share (temporary export via share sheet
  or copy to Downloads—decide), music-disc animation (pure UI).
