# Codebase Map (as of v3, TikTok parity)

Use this to orient without re-reading everything. Paths relative to repo root.

## Entry & shell
- `lib/main.dart` — bootstrap Db+AppState, `MiniTiktokApp` (title "Videos",
  dark theme), `LockGate` (local_auth fingerprint; auto-pass if unsupported).
  `home:` = `LockGate(child: AppShell())`.
- `lib/screens/app_shell.dart` — `AppShell` = TikTok shell. Custom `_BottomBar`
  with 5 slots (Home, Explore, [+], Inbox, Me); `+` is an action that opens
  `SelectVideosScreen(activeProfile)` (or EditProfileScreen if none). Body is an
  `IndexedStack` [HomeFeed, AllVideosPage, InboxScreen, ProfilesListScreen].
  `_stackIndex` maps nav index -> stack child; each feed gets `tabActive` so a
  hidden tab never plays audio. (v2's `home.dart` 3-page pager is gone.)
- `lib/screens/home_feed.dart` — `HomeFeed` = floating top tab bar
  (`For You | All Videos` + search icon) over an `IndexedStack` [FeedPage,
  AllVideosPage(showTitle:false)]. Tabs switch by TAP; feed keeps its own
  horizontal gestures. `_TopTabs` renders the animated underline.
- `lib/screens/feed_page.dart` — `FeedPage` (For You vertical PageView,
  RefreshIndicator reshuffle). Horizontal swipe right -> push owner `ProfilePage`;
  swipe left -> `onOpenExplore` (All Videos top tab). `_EmptyFeed` calls
  `onRequestAddVideos`. (v2 `HomeSwitcher`/`HomeController` removed.)

## State & services
- `lib/state/app_state.dart` — the brain. Fields: profiles, localVideos,
  deviceVideos, activeProfileId, `followedProfiles` (Set), `_forYouOrder`.
  Getters: `forYou` (shuffled VideoSources), `allVideos`, `sourcesOf(profile)`,
  `ownerOfLocal`, `ownerOfSource`, `activeProfile`, `localById`, `assetById`.
  Mutations: createProfile/updateProfile/deleteProfile, setActiveProfile,
  `importToProfile`, `addToProfile`, `addLocalToProfile`, `removeFromProfile`,
  `setProfileVideos`, `deleteLocalVideo`, `toggleLike`, `toggleSave`,
  `toggleFollow`/`isFollowing`, `addComment`, `shuffleForYou`,
  `refreshDeviceVideos`, `bootstrap`. Holds `store` (VideoStore), `engage`.
- `lib/state/app_state_scope.dart` — `AppStateScope.of` (subscribe) / `.read`.
- `lib/services/db.dart` — prefs keys: profiles, active_profile, local_videos,
  liked_ids, user_comments, `followed_profiles`, `saved_ids`.
- `lib/services/video_store.dart` — dirs `<appDocs>/videos`,`/thumbs`;
  `copyAll(assets, existing)` sequential w/ progress; `copyAsset` writes
  `<id>.mtv` + `<id>.jpg`; `deleteFiles`.
- `lib/services/engagement.dart` — FNV hash; baseLikes/likeCount/toggleLike;
  `viewCount`, `bookmarkCount`, `shareCount`, and per-profile
  `followers`/`following`/`profileLikes` (all deterministic). `isSaved`/
  `toggleSave` (bookmarks). `autoComments` + `autoCommentsNamed` (returns
  `NamedComment(name,text)`); userComments/allComments/commentCount/addComment;
  `likedIds` + `allUserComments` getters (feed the Inbox).
- `lib/services/media_service.dart` — permission + paged device video load.
- `lib/data/comment_pool.dart` — 150 Banglish comments (`kCommentPool`) +
  Bangla author names (`kNamePool`).

## Models
- `Profile` (models/profile.dart): id,name,bio,avatarPath,videoIds[](ordered),createdAt.
- `LocalVideo` (models/local_video.dart): id,srcAssetId,path,thumbPath,title,w,h,durationSec,addedAt.
- `VideoSource` (models/video_source.dart): id + local?/asset?; `resolveFile()`
  (local .mtv first), `localThumb`, `title`, `duration`.

## Screens
- `profile_screen.dart` — `ProfilePage(profile)` pushed full screen: centered
  avatar/name/@handle, Following|Followers|Likes stats, pink Follow (toggles
  followedProfiles), grey "Say hi" (opens latest video's comments), ▾ + ⋮ menu
  (Edit/Add/Delete). `_ProfileBody` = Latest/Most-viewed sort + 3-col grid with
  ▶ view chips, long-press delete. `ProfileFeed` = pushed vertical player.
- `profiles_list_screen.dart` — `ProfilesListScreen` (Me tab): FB-friend-list of
  all profiles + pinned "+ New profile"; tap -> ProfilePage.
- `inbox_screen.dart` — `InboxScreen`: your comments + liked videos from prefs;
  tap -> SingleVideoScreen.
- `search_screen.dart` — `SearchScreen`: local videos by title + profiles by
  name; tap video -> SingleVideoScreen, tap profile -> ProfilePage.
- `single_video_screen.dart` — `SingleVideoScreen(source)`: pushed full-screen
  player for one video (search + inbox).
- `edit_profile_screen.dart` — create/edit; avatar via image_picker -> avatars dir.
- `select_videos_screen.dart` — device grid, preselect from profile, Done ->
  `importToProfile`; shows copy progress bar (AnimatedBuilder on store).
- `assign_sheet.dart` — add/remove a copy to/from profiles (multi).
- `comments_sheet.dart` — named auto + user comments + input.
- `all_videos_page.dart` — device videos feed (`tabActive`, `showTitle`);
  `importCurrentToActiveProfile` helper.

## Widgets
- `video_page.dart` — `VideoPage(source, isActive, ownerName, owner, onFollow,
  following, onAssign, onOpenProfile, onOpenComments, showAssign)`.
  Contain/letterbox playback, lifecycle pause. Rail (top->bottom): owner avatar
  +follow badge, Like, Comment, Bookmark (saved_ids), Share (offline toast),
  Mute, Assign, spinning music disc (`AnimationController`). `_fmt` K/M.
- `thumb.dart` — `VideoThumb(source,...,viewsLabel)` local jpg or asset thumb +
  duration + optional ▶ views chip + selection ring.
- `avatar.dart` — `Avatar(path,name,size,ring)`.

## CI / native
- `.github/workflows/build.yml` — self-contained: flutter create android,
  restore lib, patch compileSdk 36 + manifest perms + label "Videos", build,
  artifact. Triggers on push to `main` OR `master`.
- No `android/` in repo (generated in CI). `.gitignore` standard Flutter.

## Known-good invariants (do not break)
- Playback is contain (no crop). Copies are `.mtv` in internal dir.
- One video may be in many profiles; For You = all copies shuffled.
- Fingerprint gate wraps AppShell. App label patched in CI only.
- Only one feed plays at a time: `tabActive` gates every feed's VideoPage.
