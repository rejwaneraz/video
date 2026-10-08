# Paste-ready prompt for the next session

Copy everything between the lines into a new session (with this repo open).

---

You are continuing work on "Videos", an offline personal mini-TikTok Flutter app
(repo already contains working v2 + CI that builds a release APK on push).

First read these docs in order: docs/PRD.md, docs/TRD.md, docs/UIUX.md,
docs/CODEBASE.md, docs/PLAN.md. They describe the shipped v2 and the v3 goal:
full TikTok UI parity but 100% offline (no backend).

v3 requirements (user-confirmed):
1. Bottom nav with 5 TikTok-style tabs: Home, Explore, [+], Inbox, Me.
2. Home feed gets a top tab bar (Following / For You) + search icon.
3. Swipe RIGHT on a For You video opens THAT video's owner profile as a pushed
   full screen styled like TikTok's profile page (centered avatar, name, @handle,
   Following/Followers/Likes stats, Follow + Say hi buttons, 3-col grid with
   ▶ view counts). Swipe LEFT goes to All Videos (Explore).
4. Me tab = list of all profiles (avatar+name+count), tap opens profile.
5. Feed rail gains bookmark + share + spinning music disc, counts in K/M.
6. Keep ALL v2 behaviour: private .mtv copies that survive deletion, fingerprint
   lock, shuffled For You, multi-profile membership, letterbox no-crop playback,
   likes/comments (150-comment pool), CI APK build.

Open decisions (answer or apply defaults listed in PRD §9): top-tab mapping,
Explore/Inbox meaning, Follow/Say-hi behaviour, grid view counts, theme,
storage-manager.

Work strictly phase-by-phase per docs/PLAN.md (Phase 1 navigation restructure
first). After each phase: keep code compiling, commit, and push to origin main
so GitHub Actions produces a test APK. Do not add network/backend. Do not regress
v2 invariants listed in docs/CODEBASE.md.

---
