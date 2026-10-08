# Codebase Map (as of v2, commit "v2: private video copy…")

Use this to orient without re-reading everything. Paths relative to repo root.

## Entry & shell
- `lib/main.dart` — bootstrap Db+AppState, `MiniTiktokApp` (title "Videos",
  dark theme), `LockGate` (local_auth fingerprint; auto-pass if unsupported).
- `lib/screens/home.dart` — `Home` = horizontal `PageView` **[Profile, ForYou,
  AllVideos]** (initialPage 1). Implements `HomeController` (goProfile/goFeed/goAll).
  On entering page 0 sets activeProfile = owner of current For You video.
  ⚠️ v3 replaces this pager with bottom-nav shell (see PLAN Phase 1).
- `lib/screens/feed_page.dart` — `FeedPage` (For You vertical PageView,
  RefreshIndicator reshuffle, reports `currentVideoId`), defines `HomeSwitcher`
  + `HomeController` abstract, `_EmptyFeed`.

## State & services
- `lib/state/app_state.dart` — the brain. Fields: profiles, localVideos,
  deviceVideos, activeProfileId, `_forYouOrder`. Getters: `forYou` (shuffled
  VideoSources), `allVideos`, `sourcesOf(profile)`, `ownerOfLocal`,
  `ownerOfSource`, `activeProfile`, `localById`, `assetById`.
  Mutations: createProfile/updateProfile/deleteProfile, setActiveProfile,
  `importToProfile` (copy+set order), `addToProfile`, `addLocalToProfile`,
  `removeFromProfile`, `setProfileVideos`, `deleteLocalVideo`,
  `toggleLike`, `addComment`, `shuffleForYou`, `refreshDeviceVideos`, `bootstrap`.
  Holds `store` (VideoStore) and `engage` (Engagement).
- `lib/state/app_state_scope.dart` — `AppStateScope.of` (subscribe) / `.read`.
- `lib/services/db.dart` — prefs keys: profiles, active_profile, local_videos,
  liked_ids, user_comments.
- `lib/services/video_store.dart` — dirs `<appDocs>/videos`,`/thumbs`;
  `copyAll(assets, existing)` sequential w/ progress (total/done/copying/current);
  `copyAsset` writes `<id>.mtv` + `<id>.jpg`; `deleteFiles`.
- `lib/services/engagement.dart` — FNV hash; baseLikes, likeCount, toggleLike,
  autoComments (4-11 from pool), userComments/allComments/commentCount, addComment.
- `lib/services/media_service.dart` — permission + paged device video load.
- `lib/data/comment_pool.dart` — 150 Banglish comments.

## Models
- `Profile` (models/profile.dart): id,name,bio,avatarPath,videoIds[](ordered),createdAt.
- `LocalVideo` (models/local_video.dart): id,srcAssetId,path,thumbPath,title,w,h,durationSec,addedAt.
- `VideoSource` (models/video_source.dart): id + local?/asset?; `resolveFile()`
  (local .mtv first), `localThumb`, `title`, `duration`.

## Screens
- `profile_screen.dart` — `ProfileScreen` (switcher + `_ProfileBody` header/grid),
  `ProfileFeed` (pushed vertical player over a profile's videos). ⚠️ v3 redesign.
- `edit_profile_screen.dart` — create/edit; avatar via image_picker -> avatars dir.
- `select_videos_screen.dart` — device grid, preselect from profile, Done ->
  `importToProfile`; shows copy progress bar (AnimatedBuilder on store).
- `assign_sheet.dart` — add/remove a copy to/from profiles (multi).
- `comments_sheet.dart` — auto+user comments + input.
- `all_videos_page.dart` — device videos feed; `importCurrentToActiveProfile` helper.

## Widgets
- `video_page.dart` — `VideoPage(source, isActive, ownerName, onAssign,
  onOpenProfile, onOpenComments, showAssign)`. Contain/letterbox playback,
  lifecycle pause, rail: like/comment/profile/mute/assign, `_fmt` K/M.
- `thumb.dart` — `VideoThumb(source,...)` local jpg or asset thumb + duration + selection.
- `avatar.dart` — `Avatar(path,name,size,ring)`.

## CI / native
- `.github/workflows/build.yml` — self-contained: flutter create android,
  restore lib, patch compileSdk 36 + manifest perms + label "Videos", build, artifact.
- No `android/` in repo (generated in CI). `.gitignore` standard Flutter.

## Known-good invariants (do not break)
- Playback is contain (no crop). Copies are `.mtv` in internal dir.
- One video may be in many profiles; For You = all copies shuffled.
- Fingerprint gate wraps Home. App label patched in CI only.
