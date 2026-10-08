# PRD — "Videos" (offline personal mini-TikTok)

Status: v2 shipped (APK builds via GitHub Actions). v3 = TikTok UI parity. Owner: rejwaneraz.

## 1. Vision

A 100% **offline** Android app that reproduces the TikTok experience over the
user's **own local videos**: vertical feed, profiles with grids, likes/comments,
private video copies that survive deleting the original. No backend, no network,
no real accounts.

## 2. Hard constraints

- Offline only. No server, no login, no sync.
- Videos are the user's own device videos; selected ones are **copied into app
  private storage** (`<id>.mtv`) so they survive original deletion and are
  invisible to gallery / file manager / other apps.
- App must not lag: background copy queue, limited live players, cached thumbs.
- App display name: **Videos**. Fingerprint lock on open.

## 3. Personas / usage

Single personal user ("creator + viewer"). Creates multiple profiles (e.g.
muskan, akash), assigns copies of videos to each, browses For You (shuffled
copies) and All Videos (device), opens a video's profile, edits profiles.

## 4. Shipped (v2) — do not regress

- Fingerprint lock (auto-pass if no biometrics).
- For You = all copied videos, shuffled; pull-to-refresh reshuffles.
- All Videos = device videos (vertical feed).
- Horizontal swipe: right → owner profile, left → All Videos.
- Profiles: avatar/name/bio, create/edit/delete, multi switcher, 3-col 3:4 grid,
  one video may belong to many profiles, grid keeps manual order.
- Copy pipeline: select → background copy (.mtv + .jpg thumb) with progress.
- Likes (toggle) + comments (deterministic auto from 150-pool + user's own).
- Player: tap pause, double-tap ±10s, mute, letterbox (NO crop, any aspect).
- Long-press grid tile → delete copy (frees storage).
- CI: GitHub Actions builds release APK artifact.

## 5. Target (v3) — TikTok parity (from user's screenshots)

### 5.1 Feed screen (screenshot 1)
- **Top tab bar** over the feed: e.g. `Following | For You | …` + search icon at
  right. Active tab underlined. (Offline mapping TBD — see Open Questions.)
- **Right action rail** per video, top→bottom: owner avatar (with + badge),
  Like (heart + count), Comment (bubble + count), **Bookmark**, **Share**,
  spinning music disc. Counts formatted K/M.
- **Bottom nav (5 tabs)**, TikTok style: `Home | Explore | [+] | Inbox | Me`.
  Offline mapping (default): Home=For You feed, Explore=All Videos, `+`=add
  videos to active profile, Inbox=activity (your comments/likes), Me=profiles list.

### 5.2 Profile page (screenshot 2) — pushed full screen
- Centered large avatar, then **name**, then `@handle`.
- Stats row: `Following | Followers | Likes` (fake deterministic counts offline).
- Buttons row: **Follow** (pink), **Say hi 👋**, small dropdown (⋯ / ▾).
- Tab/sort control, then 3-col grid; each tile shows **▶ view count** bottom-left.
- Opening it: swipe **right** on a For You video → THAT video's owner profile.

### 5.3 "Me" tab
- FB-friend-list style vertical list of **all profiles** (avatar + name + video
  count). Tap → opens that profile page. Includes "+ New profile".

### 5.4 Gestures (confirmed by user)
- Swipe right (left→right) on feed = open owner profile.
- Swipe left (right→left) on feed = All Videos.
- Vertical swipe = next/prev video.

## 6. User stories (v3)

- As user, on Home I see top tabs and a bottom nav identical in spirit to TikTok.
- As user, tapping Me shows every profile as a list; tapping one opens it.
- As user, a profile page looks like TikTok's (avatar/name/@/stats/buttons/grid+views).
- As user, rail shows like/comment/bookmark/share with K/M counts.
- As user, search (top-right) finds videos/profiles by title/name (local only).

## 7. Acceptance criteria (v3)

1. Bottom nav present on all main tabs with 5 items; `+` opens add-videos.
2. Top tab bar visible on Home feed; switching works by tap AND horizontal swipe
   where it doesn't conflict with profile/all-videos gestures.
3. Swipe right on any For You video opens exactly that video's owner profile page.
4. Profile page shows avatar/name/@handle/stats/2 buttons/grid-with-views.
5. Me lists all profiles with pictures; tap opens profile.
6. All v2 features still work (copy, lock, shuffle, comments, no-crop playback).
7. APK builds in CI; no new native permission beyond existing set.

## 8. Non-goals

No network, no real followers/messaging, no monetization, no iOS-parity polish
(iOS builds allowed but Android-first), no video editing/trim (future).

## 9. Open questions (answer in next session)

1. **Top tabs offline mapping?** Default: `Following` (videos of profiles you
   Follow) + `For You` + search. Alternative: `For You | All Videos`.
2. **Bottom nav Explore/Inbox meaning?** Default above (Explore=All Videos,
   Inbox=your activity). Alternative: only Home/+/Me.
3. **Follow / Say hi offline behaviour?** Default: Follow toggles local follow
   (affects Following tab + follower count); Say hi opens comment sheet.
   Alternative: remove both, keep Edit/Add.
4. **Grid view counts:** fake deterministic ▶ views (default) vs hide.
5. **Theme:** keep dark everywhere (default) vs light profile page like screenshot.
6. **Storage cap / cleanup UI:** add a Storage manager screen? (recommended yes, later)
