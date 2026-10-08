# Implementation Plan — v3 (TikTok parity)

Read `docs/PRD.md`, `docs/TRD.md`, `docs/UIUX.md`, `docs/CODEBASE.md` first.
Work phase-by-phase; commit + push after each (CI builds APK on push to main).

## Phase 1 — Navigation restructure (bottom nav + pushed profile)

Goal: TikTok shell. Home feed no longer lives in a 3-page horizontal pager with
ProfileScreen embedded; profile becomes a **pushed full screen**.

1. New `screens/app_shell.dart`: `Scaffold` + `BottomNavigationBar` 5 items
   (Home, Explore, +, Inbox, Me). Keeps a `PageView`/`IndexedStack` for tabs.
   - Home -> `FeedPage` (For You) with top tab bar (Phase 4).
   - Explore -> `AllVideosPage`.
   - `+` -> opens `SelectVideosScreen(activeProfile)` (not a tab).
   - Inbox -> `InboxScreen` (Phase 5).
   - Me -> `ProfilesListScreen` (Phase 3).
2. `home.dart`: remove 3-page pager; keep `HomeSwitcher`/`HomeController` API but
   re-point: `goProfile()` now **pushes** `ProfilePage(ownerOf(currentVideo))`.
3. Feed gesture: wrap feed in horizontal `GestureDetector`:
   - drag right (dx>threshold, |dx|>|dy|) -> push owner profile of current video.
   - drag left -> switch to Explore tab (All Videos).
   Keep vertical PageView for videos.
4. Delete/retire old embedded `ProfileScreen` pager usage; convert
   `profile_screen.dart` into pushed `ProfilePage(profile)` (Phase 2 redesign).

Accept: bottom nav visible; swipe right opens owner profile; swipe left = All.

## Phase 2 — Profile page redesign (match screenshot 2)

Rewrite `profile_screen.dart` as pushed `ProfilePage`:
- `SafeArea`; centered `Avatar(size~110)`; name (bold, ~22); `@handle` grey.
- Stats row centered: Following / Followers / Likes (hash-derived; Following =
  real count of profiles this profile follows? offline => fake ok).
- Buttons: pink `Follow` (toggles `followed_profiles`), grey `Say hi 👋`
  (opens comments sheet of latest video or a toast), square `▾` (menu: Edit,
  Add videos, Delete).
- Sort/tab control row, then 3-col grid; tiles show `▶ views` bottom-left
  (hash-derived) instead of duration (keep duration small top-right optional).
- Keep long-press delete; keep Edit/Add via menu + buttons.

Accept: page visually matches screenshot structure; swipe-right from feed lands here.

## Phase 3 — Me tab (profiles list)

New `screens/profiles_list_screen.dart`:
- ListView of all profiles: avatar(48) + name + `${n} videos` + chevron.
- Header "+ New profile" row -> EditProfileScreen.
- Tap -> push ProfilePage.
Accept: FB-friend-list feel; opens correct profile.

## Phase 4 — Top tab bar + search

- On Home feed top: row `[Following] [For You]` (+ right search icon).
  - For You = shuffled copies (existing).
  - Following = union of videos of followed profiles (ordered by profile order).
  - Tap switches feed source; horizontal swipe within feed still reserved for
    profile/all (so tabs switch by TAP only, underline animates).
- Search icon -> overlay: TextField; results = local videos by title + profiles
  by name; tap video -> open in a single-video player push; tap profile -> ProfilePage.

Accept: tabs switch feed; search finds local items.

## Phase 5 — Rail parity + Inbox

- Rail order: owner-avatar(+badge), Like, Comment, **Bookmark**, **Share**, music disc.
  - Bookmark -> `saved_ids` prefs; new "Saved" access via Me menu or Explore long-press (decide).
  - Share -> copy file to cache with .mp4 name + `share_plus`? (adds dep) OR show
    "export to Downloads" via SAF. Decide in session; default: skip real share,
    show toast "offline copy only" to avoid deps.
  - Music disc: rotating `AnimatedRotation`/`RotationTransition` circle icon (pure UI).
- Inbox: list of your own comments + liked videos (from prefs), tap -> open video.

Accept: rail matches screenshot; inbox lists activity.

## Phase 6 — Polish / perf / QA

- Verify no-crop on 9:16, 16:9, 1:1, 4:3.
- Verify copy survives original delete; verify files invisible to file manager.
- Fingerprint lock regression; app name "Videos".
- Storage manager screen (optional): list copies with sizes, bulk delete.
- Run CI, install APK, test on device; fix analyzer warnings.

## Ordering & effort

1→2→3 are the visible "same-to-same TikTok" core (do first). 4→5 parity extras.
6 anytime. Each phase = 1 commit + push.

## Definition of done (v3)

All PRD §7 acceptance criteria pass on a release APK from CI.
