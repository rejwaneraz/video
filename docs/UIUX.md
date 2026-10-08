# UI/UX Spec — "Videos" (TikTok parity, offline)

Theme: dark. Background `#111114`, surfaces `#1B1B21`, accent pink `#FF2D78`,
text white / white70 / white54. Radius 10-18. Keep consistent with v2.

## Screen 1 — Home feed (TikTok screenshot 1)

```
┌──────────────────────────────┐
│  [Following]  [For You]   🔍  │  top tab bar, ~44h, active underlined pink/white
│                              │
│        (vertical video)      │  full-bleed, letterbox (never crop)
│                              │
│                        (◉+)  │  owner avatar + pink '+' badge
│                        ♡ 64.4K│  like (filled pink when liked)
│                        💬 225 │  comment
│                        🔖 3.8K│  bookmark
│                        ➦ 596  │  share
│                        (🎵)   │  spinning music disc
│  @owner                      │  bottom-left caption + title (2 lines)
│  ──────────── progress ───── │  2px pink progress at very bottom
├──────────────────────────────┤
│  Home  Explore  [+]  Inbox Me│  bottom nav 5 tabs, ~56h, black bg
└──────────────────────────────┘
```
- Counts formatted K/M (`_fmt` in video_page).
- Gestures: vertical swipe = next video; tap = pause; double-tap L/R = ∓10s;
  horizontal swipe right = push owner profile; horizontal swipe left = Explore.
- Pull-to-refresh = reshuffle For You.

## Screen 2 — Profile page (TikTok screenshot 2), pushed

```
┌──────────────────────────────┐
│ ←                          ⋮ │  app bar (back, menu)
│           (avatar 110)       │  centered, ring optional
│          profile name        │  bold ~22, centered
│          @handle             │  grey ~14, centered
│   0        50.5K     322.9K  │  stats: Following | Followers | Likes
│  Following   Followers Likes │  (labels grey, values bold)
│ [  Follow  ] [ Say hi 👋 ][▾] │  pink solid / grey / grey square
│           ⋮⋮⋮ ▾              │  sort/tab control centered
│ ┌────┬────┬────┐             │
│ │▶13K│▶28K│▶3.9K│            │  3-col grid, 3:4 tiles, ▶views bottom-left
└──────┴────┴────┘             │
```
- Grid tiles: local jpg thumb, `▶ <views>` chip bottom-left, no checkbox.
- Long-press tile = delete copy (confirm dialog).
- `▾` menu: Edit profile, Add videos, Delete profile.

## Screen 3 — Me tab (profiles list)

- App bar title "Me" / "Profiles".
- Rows: avatar 48 + name (bold) + `${n} videos` grey + right chevron.
- First row pinned: `+ New profile` (pink icon).
- Tap row -> push ProfilePage. FB-friend-list density (row ~64h).

## Screen 4 — Explore (All Videos)

Same as feed but top label "All Videos", no top tabs, rail without assign;
plays device originals.

## Screen 5 — Inbox

- List rows: icon (♡ or 💬) + text ("You liked X" / "Your comment: …") + time.
- Tap -> open that video (push single player or jump in For You).

## Components

- `Avatar`: circle, initials fallback, gradient ring when active/owner.
- `VideoThumb`: 3:4, cover, duration or ▶views chip, optional selection ring.
- Rail button: 44 circle black38 + icon 24 + 10px label.
- Bottom nav: icons 24, label 10, active pink, inactive white54; center `+`
  rendered as rounded rect pink-bordered tile.
- Top tab bar: text 16, inactive white54, active white bold + 2px underline.

## Motion

- Tab underline slide 150ms; like heart scale pop 120ms; disc rotate 3s loop;
- page transitions default material; profile push = slide.

## Accessibility / edge

- All icons have text labels under (rail) for clarity.
- Empty states: icon + 1-2 line Banglish text + action button (v2 style).
- Respect SafeArea everywhere (notch/camera) — header must not sit under status bar.
