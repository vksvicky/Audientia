# UI Layout Redesign

## Overview

This document outlines the planned UI layout redesign for Audientia, moving from the current 3-column MediaMonkey-style layout to a cleaner tabbed interface inspired by Apple Music and Aural Player.

**Status**: Planning Complete, Implementation Pending  
**Branch**: `21_ui-layout-redesign`  
**Date**: December 2025

---

## Problem Analysis

### Current Layout Issues

The current layout has several duplication and space efficiency problems:

1. **Content Duplication**:
   - "Playing" view in content area duplicates queue info shown elsewhere
   - Playlist panel duplicates playlist content available in navigation sidebar → "Playlists" item
   - Library stats in sidebar could overlap with Library Browser info

2. **Redundant Panels**:
   - Right playlist panel (300px) is ALWAYS visible even when not needed
   - Takes significant horizontal space (300px of minimum 1000px = 30%)

3. **Fixed Widths Cause Issues**:
   - Sidebar: 200px fixed
   - Playlist Panel: 300px fixed
   - Leaves only ~500px for main content (50%)

---

## Current Layout (Before)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              TITLE BAR (with minimize button)                        │
├──────────────┬──────────────────────────────────────────────────┬───────────────────┤
│              │                    TOOLBAR                        │                   │
│              │  [🏠 Home] [🔍 Search]              [...Options]  │                   │
│              ├──────────────────────────────────────────────────┤                   │
│  NAVIGATION  │                                                   │   PLAYLIST       │
│   SIDEBAR    │               MAIN CONTENT AREA                   │     PANEL        │
│   (200px)    │                                                   │    (300px)       │
│              │  - Home View                                      │                   │
│  🏠 Home     │  - Playing View                                   │  'Playing' List  │
│  🎵 Playing  │  - Library Browser                                │  ┌─────────────┐ │
│  📚 Library  │  - Playlist Browser                               │  │ Playlists   │ │
│  🎧 Music    │  - Device Sync View                               │  │ ├── Jazz    │ │
│  📋 Playlists│  - Visualiser                                     │  │ └── Rock    │ │
│  📱 Devices  │                                                   │  ├─────────────┤ │
│  📁 Folders  │                                                   │  │ Tracks in   │ │
│              │                                                   │  │ Playlist    │ │
│  ┄┄┄┄┄┄┄┄┄┄  │                                                   │  │ - Track 1   │ │
│  LIBRARY     │                                                   │  │ - Track 2   │ │
│  STATS       │                                                   │  └─────────────┘ │
│  🎵 X tracks │                                                   │                   │
│  👥 Y artists│                                                   │                   │
│  💿 Z albums │                                                   │                   │
│  🕐 Duration │                                                   │                   │
│  💾 Size     │                                                   │                   │
├──────────────┴──────────────────────────────────────────────────┴───────────────────┤
│                           PLAYER CONTROLS (80px height)                              │
│  ┌────────────────┐     ───────●─────────────────     ┌─────────────────────────┐   │
│  │ 🎵 Album Art   │     0:00             3:45         │ [⏮][⏯][⏹][⏭]          │   │
│  │    Track Title │     ◀◀  ▶  ■  ▶▶                  │ [🔀][🔁][📊] [🔊━━━━]   │   │
│  │    Artist      │                                   │ Shuffle/Loop/Vis/Volume │   │
│  └────────────────┘                                   └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## New Layout (Option D: Tabbed Interface with Visualisation)

### Design Principles

1. **No Content Duplication** - Each piece of information appears in ONE place
2. **Collapsible Toolbar** - Navigation tabs in toolbar, can be collapsed to maximise content
3. **Contextual Sidebar** - Shows relevant content based on selected tab
4. **Search in Sidebar** - Moved from toolbar to sidebar for consistent placement
5. **Collapsible Player Bar** - Can collapse to compact single-line mode
6. **Dedicated Visualiser Tab** - Full-screen visualisation experience

### Collapsible Elements

| Element | Position | Collapsed State | Expanded State |
|---------|----------|-----------------|----------------|
| **Toolbar** | Top | Hidden (0px) | Navigation tabs visible (44px) |
| **Player Controls** | Bottom | Single line: title-artist, seek, controls (32px) | Full: artwork, info, seek, controls (70px) |

### Main Layout Structure (Expanded)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              TOOLBAR (44px, collapsible)                          [▲]   │
│  [🏠 Home]  [📚 Library]  [📋 Playlists]  [📱 Devices]  [🎨 Visualiser]                  │
├──────────────────────────────┬──────────────────────────────────────────────────────────┤
│       SIDEBAR (180px)        │                    MAIN CONTENT AREA                      │
│                              │                       (FLEXIBLE)                          │
│  ┌────────────────────────┐  │                                                          │
│  │ 🔍 Search...           │  │   ┌──────────────────────────────────────────────────┐   │
│  └────────────────────────┘  │   │                                                  │   │
│                              │   │                                                  │   │
│  CONTEXTUAL NAVIGATION       │   │      Content based on selected tab               │   │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │                                                  │   │
│                              │   │      - Home: Welcome + Quick Access              │   │
│  (Changes per tab)           │   │      - Library: Track Browser                    │   │
│                              │   │      - Playlists: Playlist Manager               │   │
│                              │   │      - Devices: Sync Settings                    │   │
│                              │   │      - Visualiser: Full Visualisation            │   │
│                              │   │                                                  │   │
│                              │   │                                                  │   │
│                              │   └──────────────────────────────────────────────────┘   │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
│  👥 156 artists              │                                                          │
│  💿 89 albums                │                                                          │
│  🕐 48h 32m                  │                                                          │
├──────────────────────────────┴──────────────────────────────────────────────────────────┤
│                           PLAYER CONTROLS - EXPANDED (70px)                        [▼]  │
│  ┌─────┐                                                                                 │
│  │ 🎵  │  Track Title                 ────────●───────────      [⏮][▶][⏭]              │
│  │     │  Artist - Album               1:45 / 4:12              [🔀][🔁] [🔊━━━━━]      │
│  └─────┘                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Main Layout Structure (Toolbar Collapsed)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    [▼]  │ ← Toolbar collapsed (click to expand)
├──────────────────────────────┬──────────────────────────────────────────────────────────┤
│       SIDEBAR (180px)        │                    MAIN CONTENT AREA                      │
│                              │                       (FLEXIBLE)                          │
│  ┌────────────────────────┐  │                                                          │
│  │ 🔍 Search...           │  │                                                          │
│  └────────────────────────┘  │        ┌────────────────────────────────────────┐        │
│                              │        │                                        │        │
│  CONTEXTUAL NAVIGATION       │        │      MAXIMUM CONTENT SPACE             │        │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │        │                                        │        │
│  (Changes per tab)           │        │      Toolbar hidden for immersive      │        │
│                              │        │      viewing (e.g., Visualiser)        │        │
│                              │        │                                        │        │
│                              │        └────────────────────────────────────────┘        │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
├──────────────────────────────┴──────────────────────────────────────────────────────────┤
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                         ↑ Player collapsed to single line (32px)
```

### Player Controls - Collapsed State (32px)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
   │                                    │              │                              │
   └─ Scrolling text (marquee)          └─ Seek bar    └─ Transport + Volume         └─ Expand

Details:
- Track Title - Artist: Scrolls left-to-right when text is too long (marquee style)
- Seek bar: Compact slider with current/total time
- Controls: Previous, Play/Pause, Next, Shuffle, Loop, Volume (all icons only)
- [▲] button: Click to expand to full player view
```

### Player Controls - Expanded State (70px)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           PLAYER CONTROLS - EXPANDED (70px)                        [▼]  │
│                                                                                         │
│  ┌───────┐   Track Title                    ───────●─────────────   ┌─────────────────┐ │
│  │  🎵   │   Artist - Album                  2:30 / 4:15            │ [⏮] [▶] [⏭]    │ │
│  │ Album │                                                          │ [🔀] [🔁] [🔊━] │ │
│  │  Art  │                                                          └─────────────────┘ │
│  └───────┘                                                                              │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
   │            │                              │                              │
   └─ Album art └─ Track info (2 lines)        └─ Seek bar + time             └─ [▼] Collapse

Details:
- Album art: 60x60 artwork thumbnail
- Track info: Title on first line, Artist - Album on second line
- Seek bar: Full-width slider with time labels
- Controls: Larger icons with spacing
- [▼] button: Click to collapse to single-line view
```

### Maximum Content Mode (Both Collapsed)

For immersive experiences like the Visualiser, both toolbar and player can be collapsed:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    [▼]  │
├──────────────────────────────┬──────────────────────────────────────────────────────────┤
│       SIDEBAR (180px)        │                                                          │
│                              │                                                          │
│  ┌────────────────────────┐  │                                                          │
│  │ 🔍 Search...           │  │          ▄▄    ▄▄                                        │
│  └────────────────────────┘  │      ▄▄ ████ ████ ▄▄                                     │
│                              │    ▄▄████████████████▄▄                                   │
│  VISUALISATION STYLE         │  ▄▄██████████████████████▄▄                               │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │ ████████████████████████████                              │
│  ◉ LED Bars                  │                                                          │
│  ○ Lumi Bars                 │        MAXIMUM VISUALISATION AREA                        │
│  ○ Radial Spectrum           │                                                          │
│                              │                                                          │
│  SETTINGS                    │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  Sensitivity  [━━━●━━]       │                                                          │
│  Smoothing    [━━●━━━]       │                                                          │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
├──────────────────────────────┴──────────────────────────────────────────────────────────┤
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Collapsible Toolbar

The toolbar contains the navigation tabs and can be collapsed to maximise content space.

### Expanded State (44px)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  [🏠 Home]  [📚 Library]  [📋 Playlists]  [📱 Devices]  [🎨 Visualiser]            [▲]  │
└─────────────────────────────────────────────────────────────────────────────────────────┘
    │            │              │               │              │                      │
    └─ Tab buttons (icons + text)                                                     └─ Collapse button

- Active tab: Highlighted with accent colour, bold text
- Inactive tabs: Standard colour, normal weight
- [▲] button: Click to collapse toolbar
- Keyboard: ⌘T to toggle
```

### Collapsed State (0px)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    [▼]  │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                      │
                                                                          [▼] Expand button

- Toolbar hidden, only expand button visible in corner
- Click [▼] or press ⌘T to show tabs again
- Tab navigation still works via sidebar contextual navigation
```

### Tab Switching While Collapsed

When toolbar is collapsed, tabs can still be switched via:
1. **Sidebar contextual navigation** - Each tab's sidebar has relevant quick links
2. **Keyboard shortcuts** - `⌘1` Home, `⌘2` Library, `⌘3` Playlists, `⌘4` Devices, `⌘5` Visualiser
3. **Expand toolbar** - Click [▼] or press `⌘T`

---

## Tab-Specific Views

> **Note**: The diagrams below show only the **sidebar + content area** for each tab.  
> The **toolbar** (top) and **player controls** (bottom) remain as shown in the main layout.

### 🏠 Home Tab

```
┌──────────────────────────────┬──────────────────────────────────────────────────────────┐
│       SIDEBAR                │                    HOME VIEW                              │
│                              │                                                          │
│  ┌────────────────────────┐  │   Welcome to Audientia                                   │
│  │ 🔍 Search...           │  │   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  └────────────────────────┘  │                                                          │
│                              │   RECENTLY PLAYED                                        │
│  QUICK ACCESS                │   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │  🎵    │ │  🎵    │ │  🎵    │ │  🎵    │       │
│  ▸ Recently Played           │   │ Album 1 │ │ Album 2 │ │ Album 3 │ │ Album 4 │       │
│  ▸ Recently Added            │   └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
│  ▸ Most Played               │                                                          │
│  ▸ Favourites                │   RECENTLY ADDED                                         │
│                              │   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  ACTIONS                     │   │  🎵    │ │  🎵    │ │  🎵    │ │  🎵    │       │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │ New 1   │ │ New 2   │ │ New 3   │ │ New 4   │       │
│  [+ Import Files]            │   └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
│  [⚙ Settings]                │                                                          │
│                              │   ┌────────────────────────────────────────────────┐     │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │ >> What's New?                                 │     │
│  LIBRARY STATS               │   │ >> Introduction                               │     │
│  🎵 1,234 tracks             │   │ >> Add files to the library                   │     │
│  👥 156 artists              │   │ >> Play files                                 │     │
│  💿 89 albums                │   └────────────────────────────────────────────────┘     │
└──────────────────────────────┴──────────────────────────────────────────────────────────┘
```

### 📚 Library Tab

```
┌──────────────────────────────┬──────────────────────────────────────────────────────────┐
│       SIDEBAR                │                    LIBRARY BROWSER                        │
│                              │                                                          │
│  ┌────────────────────────┐  │   ┌──────────────────────────────────────────────────┐   │
│  │ 🔍 Search library...   │  │   │ FILTER: [All ▼] [Genre ▼] [Year ▼]  [Clear]     │   │
│  └────────────────────────┘  │   └──────────────────────────────────────────────────┘   │
│                              │                                                          │
│  BROWSE BY                   │   ┌────┬────────────────┬────────────┬──────────┬─────┐  │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │ #  │ Title          │ Artist     │ Album    │ ⏱   │  │
│  ▸ All Tracks       (1234)   │   ├────┼────────────────┼────────────┼──────────┼─────┤  │
│  ▸ Artists           (156)   │   │  1 │ Song One       │ Artist A   │ Album 1  │3:45 │  │
│  ▸ Albums             (89)   │   │  2 │ Song Two       │ Artist B   │ Album 2  │4:12 │  │
│  ▸ Genres             (23)   │   │  3 │ Song Three     │ Artist A   │ Album 3  │2:58 │  │
│  ▸ Years              (15)   │   │  4 │ Song Four      │ Artist C   │ Album 1  │5:01 │  │
│  ▸ Folders             (8)   │   │  5 │ Song Five      │ Artist D   │ Album 4  │3:22 │  │
│                              │   │  6 │ Song Six       │ Artist A   │ Album 2  │4:45 │  │
│  FILTER BY GENRE             │   │  7 │ Song Seven     │ Artist E   │ Album 5  │3:18 │  │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   └────┴────────────────┴────────────┴──────────┴─────┘  │
│  □ Rock              (412)   │                                                          │
│  □ Jazz              (234)   │   Selected: 2 tracks                                     │
│  □ Classical         (156)   │   ┌──────────────────────────────────────────────────┐   │
│  □ Electronic        (198)   │   │ [▶ Play] [+ Add to Queue] [📋 Add to Playlist]  │   │
│                              │   └──────────────────────────────────────────────────┘   │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
└──────────────────────────────┴──────────────────────────────────────────────────────────┘
```

### 📋 Playlists Tab

```
┌──────────────────────────────┬──────────────────────────────────────────────────────────┐
│       SIDEBAR                │                    PLAYLIST VIEW                          │
│                              │                                                          │
│  ┌────────────────────────┐  │   My Favourites                                          │
│  │ 🔍 Search playlists... │  │   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  └────────────────────────┘  │   24 tracks • 1h 32m                                     │
│                              │                                                          │
│  PLAYLISTS                   │   ┌────┬────────────────┬────────────┬──────────┬─────┐  │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │ #  │ Title          │ Artist     │ Album    │ ⏱   │  │
│  📁 My Favourites  ◀   (24)  │   ├────┼────────────────┼────────────┼──────────┼─────┤  │
│  📁 Workout Mix        (18)  │   │  1 │ Fav Track 1    │ Artist A   │ Album 1  │3:45 │  │
│  📁 Chill Vibes        (32)  │   │  2 │ Fav Track 2    │ Artist B   │ Album 2  │4:12 │  │
│  📁 Road Trip          (45)  │   │  3 │ Fav Track 3    │ Artist C   │ Album 3  │2:58 │  │
│                              │   │  4 │ Fav Track 4    │ Artist D   │ Album 1  │5:01 │  │
│  [+ New Playlist]            │   └────┴────────────────┴────────────┴──────────┴─────┘  │
│                              │                                                          │
│  SMART PLAYLISTS             │   ┌──────────────────────────────────────────────────┐   │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │ [▶ Play All] [🔀 Shuffle] [✏ Edit] [🗑 Delete]   │   │
│  ⚡ Recently Added            │   └──────────────────────────────────────────────────┘   │
│  ⚡ Top Rated                 │                                                          │
│  ⚡ 5-Star Tracks             │                                                          │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
└──────────────────────────────┴──────────────────────────────────────────────────────────┘
```

### 📱 Devices Tab

```
┌──────────────────────────────┬──────────────────────────────────────────────────────────┐
│       SIDEBAR                │                    DEVICE SYNC                            │
│                              │                                                          │
│  ┌────────────────────────┐  │   iPhone 15 Pro                                          │
│  │ 🔍 Search...           │  │   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  └────────────────────────┘  │   Connected • Last synced: Today 3:45 PM                 │
│                              │                                                          │
│  CONNECTED                   │   Storage                                                │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   ┌──────────────────────────────────────────────────┐   │
│  📱 iPhone 15 Pro     ◀  ✓   │   │ ████████████░░░░░░░░░  64 GB / 128 GB           │   │
│  📱 iPad Air             ○   │   └──────────────────────────────────────────────────┘   │
│                              │                                                          │
│  SYNC OPTIONS                │   Sync Content                                           │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   ┌──────────────────────────────────────────────────┐   │
│  ◉ Entire Library            │   │ ☑ My Favourites (24 tracks)                     │   │
│  ○ Selected Playlists        │   │ ☑ Workout Mix (18 tracks)                       │   │
│  ○ Checked Tracks Only       │   │ ☐ Chill Vibes (32 tracks)                       │   │
│                              │   │ ☐ Road Trip (45 tracks)                         │   │
│                              │   └──────────────────────────────────────────────────┘   │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   ┌──────────────────────────────────────────────────┐   │
│  LIBRARY STATS               │   │        [🔄 Sync Now]    [⚙ Settings]            │   │
│  🎵 1,234 tracks             │   └──────────────────────────────────────────────────┘   │
└──────────────────────────────┴──────────────────────────────────────────────────────────┘
```

### 🎨 Visualiser Tab

```
┌──────────────────────────────┬──────────────────────────────────────────────────────────┐
│       SIDEBAR                │                    VISUALISER                             │
│                              │                                                          │
│  ┌────────────────────────┐  │   ┌──────────────────────────────────────────────────┐   │
│  │ 🔍 Search...           │  │   │                                                  │   │
│  └────────────────────────┘  │   │                                                  │   │
│                              │   │                                                  │   │
│  VISUALISATION STYLE         │   │          ▄▄    ▄▄                               │   │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │      ▄▄ ████ ████ ▄▄                            │   │
│  ◉ LED Bars                  │   │    ▄▄████████████████▄▄                          │   │
│  ○ Lumi Bars                 │   │  ▄▄██████████████████████▄▄                      │   │
│  ○ Radial Spectrum           │   │ ████████████████████████████                     │   │
│  ○ Dual Channel              │   │                                                  │   │
│  ○ Discrete Frequencies      │   │        AUDIO VISUALISATION                       │   │
│  ○ Round Bars Reflex         │   │                                                  │   │
│                              │   │                                                  │   │
│  SETTINGS                    │   │                                                  │   │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   │                                                  │   │
│  Sensitivity  [━━━●━━]       │   │                                                  │   │
│  Smoothing    [━━●━━━]       │   │                                                  │   │
│  Colour Theme [Accent ▼]     │   └──────────────────────────────────────────────────┘   │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │   Now Playing: Track Title - Artist                      │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
└──────────────────────────────┴──────────────────────────────────────────────────────────┘
```

---

## Player Controls Bar (Collapsible)

The player controls bar is **always visible at the bottom of the window** on every tab and is the **single source of truth** for "Now Playing" information. It can be **collapsed to a compact single-line view** to maximise content space.

**Visibility**: ✅ Home | ✅ Library | ✅ Playlists | ✅ Devices | ✅ Visualiser

### Expanded State (70px) - Default

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           PLAYER CONTROLS - EXPANDED (70px)                        [▼]  │
│                                                                                         │
│  ┌───────┐   Track Title                    ───────●─────────────   ┌─────────────────┐ │
│  │  🎵   │   Artist - Album                  2:30 / 4:15            │ [⏮] [▶] [⏭]    │ │
│  │ Album │                                                          │ [🔀] [🔁] [🔊━] │ │
│  │  Art  │                                                          └─────────────────┘ │
│  └───────┘                                                                              │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

**Expanded Features:**
- Album art (60x60) on the left
- Track info: Title (line 1), Artist - Album (line 2)
- Full-width seek bar with time labels
- Spacious transport controls
- [▼] button to collapse

### Collapsed State (32px) - Compact

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

**Collapsed Features:**
- **Scrolling text**: "Track Title - Artist" scrolls left-to-right (marquee) when text overflows
- **Compact seek bar**: Inline slider with time display
- **Icon-only controls**: All transport controls as compact icons
- **[▲] button**: Click to expand back to full view

### Scrolling Text Behaviour

When the track title and artist combined exceed available width:

```
Normal (fits):     "Short Song - Artist"
                   ─────────────────────

Scrolling (long):  "◀◀ Very Long Track Title That Keeps Going - Artist Name Here ▶▶"
                   ─────────────────────────────────────────────────────────────────→
                   Text scrolls smoothly from right to left, then resets
```

**Key Points:**
- **No "Now Playing" duplication** - this IS the now playing info
- Collapse/expand state persists per session
- Keyboard shortcut: `⌘P` to toggle player collapse
- Default: Expanded on first launch

---

## Component Architecture

```
MainWindowLayoutView
│
├── CollapsibleToolbar            ← COLLAPSIBLE: Can hide to maximise content (44px ↔ 0px)
│   ├── CollapseToggle            [▲/▼] button to toggle visibility
│   └── NavigationTabBar          Horizontal tabs
│       ├── Tab: Home
│       ├── Tab: Library  
│       ├── Tab: Playlists
│       ├── Tab: Devices
│       └── Tab: Visualiser
│
├── HStack (Main Content Area)
│   │
│   ├── ContextualSidebar         ← ALWAYS VISIBLE: Content changes per tab
│   │   ├── SearchField           ← MOVED from toolbar
│   │   ├── ContextualNavigation  ← DYNAMIC: Changes per selected tab
│   │   └── LibraryStats          ← PERSISTENT: Always at bottom of sidebar
│   │
│   └── MainContentView           ← DYNAMIC: Tab-specific content
│       ├── HomeView              (when Home tab selected)
│       ├── LibraryBrowserView    (when Library tab selected)
│       ├── PlaylistBrowserView   (when Playlists tab selected)
│       ├── DeviceSyncView        (when Devices tab selected)
│       └── AudioVisualiserView   (when Visualiser tab selected)
│
└── CollapsiblePlayerBar          ← COLLAPSIBLE: Expanded (70px) ↔ Collapsed (32px)
    ├── CollapseToggle            [▲/▼] button to toggle mode
    ├── ExpandedView (70px)
    │   ├── AlbumArtView          (60x60 artwork)
    │   ├── TrackInfoView         (title, artist - album on 2 lines)
    │   ├── SeekBarView           (full-width progress slider + time labels)
    │   └── TransportControlsView (prev/play/next, shuffle, loop, volume)
    └── CollapsedView (32px)
        ├── ScrollingTextView     (marquee: "Track Title - Artist")
        ├── CompactSeekBar        (inline slider + time)
        └── CompactControls       (icon-only: prev/play/next/shuffle/loop/volume)
```

### Element Behaviour Summary

| Component | Behaviour | Height | Keyboard Shortcut |
|-----------|-----------|--------|-------------------|
| `CollapsibleToolbar` | **Collapsible** | 44px ↔ 0px | `⌘T` toggle |
| `ContextualSidebar` | **Always visible** | 100% | — |
| `LibraryStats` | **Always visible** | Auto | — |
| `MainContentView` | **Dynamic content** | Fills available | — |
| `CollapsiblePlayerBar` | **Collapsible** | 70px ↔ 32px | `⌘P` toggle |

### State Combinations

| Toolbar | Player | Content Height | Use Case |
|---------|--------|----------------|----------|
| Expanded | Expanded | Normal | Default browsing |
| Expanded | Collapsed | +38px | More list items visible |
| Collapsed | Expanded | +44px | Focus on content |
| Collapsed | Collapsed | +82px | **Maximum content** (Visualiser) |

---

## Implementation Plan

### Files to Modify

| File | Action | Notes |
|------|--------|-------|
| `MainWindowLayoutView.swift` | **Refactor** | New collapsible toolbar + player structure |
| `MainWindowNavigationSidebar.swift` | **Refactor** → `ContextualSidebar.swift` | Add search, contextual nav |
| `MainWindowToolbar.swift` | **Delete** | Replaced by CollapsibleToolbar |
| `MainWindowPlaylistPanel.swift` | **Delete** | No right panel needed |
| `NavigationItem.swift` | **Refactor** → `TabItem.swift` | Home, Library, Playlists, Devices, Visualiser |
| `MainWindowPlayerControls.swift` | **Refactor** → `CollapsiblePlayerBar.swift` | Add collapsed/expanded states |
| **NEW** `CollapsibleToolbar.swift` | **Create** | Toolbar with collapse toggle |
| **NEW** `NavigationTabBar.swift` | **Create** | Horizontal tab component |
| **NEW** `ScrollingTextView.swift` | **Create** | Marquee text for collapsed player |
| **NEW** `CompactPlayerControls.swift` | **Create** | Single-line player controls |

### Implementation Steps

1. **Step 1**: Create `TabItem.swift` enum with new tab definitions
2. **Step 2**: Create `NavigationTabBar.swift` horizontal tab component
3. **Step 3**: Create `CollapsibleToolbar.swift` with expand/collapse toggle
4. **Step 4**: Create `ScrollingTextView.swift` for marquee text animation
5. **Step 5**: Create `CompactPlayerControls.swift` for collapsed player state
6. **Step 6**: Refactor `MainWindowPlayerControls.swift` → `CollapsiblePlayerBar.swift`
7. **Step 7**: Refactor `MainWindowNavigationSidebar.swift` → `ContextualSidebar.swift`
8. **Step 8**: Update `MainWindowLayoutView.swift` with new architecture
9. **Step 9**: Delete unused files (`MainWindowToolbar.swift`, `MainWindowPlaylistPanel.swift`)
10. **Step 10**: Add keyboard shortcuts (`⌘T` for toolbar, `⌘P` for player)
11. **Step 11**: Update all tests to reflect new structure

---

## Comparison Summary

| Aspect | Before (Current) | After (Option D) |
|--------|------------------|------------------|
| Navigation | Sidebar nav items | Horizontal tabs in collapsible toolbar |
| Search | Toolbar | Sidebar |
| Right panel | Always visible playlist panel | Removed (no duplication) |
| Visualiser | Toggle button | Dedicated tab |
| "Now Playing" | Multiple places | Collapsible player bar only |
| Radio | Present | Removed |
| Layout | 3-column fixed | 2-column with collapsible elements |
| Content width | ~500px (50%) | ~820px (82%) to ~820px+82px (max) |
| Player height | 80px fixed | 70px ↔ 32px collapsible |
| Toolbar | Fixed | 44px ↔ 0px collapsible |

---

## Benefits

1. **No Duplication** - Each piece of info appears in ONE place
2. **More Content Space** - 2-column layout gives more room for content
3. **Cleaner Navigation** - Tabs are familiar and intuitive
4. **Contextual Sidebar** - Shows relevant options per tab
5. **Dedicated Visualiser** - Full tab for immersive visualisation
6. **Collapsible Player Bar** - Compact mode for maximum content, expanded for full controls
7. **Collapsible Toolbar** - Hide navigation tabs when focused on content
8. **Modern macOS Feel** - Follows Apple's design patterns
9. **Keyboard Shortcuts** - `⌘T` toggle toolbar, `⌘P` toggle player
10. **Maximum Content Mode** - Collapse both for +82px vertical space (great for Visualiser)
11. **Scrolling Track Info** - Marquee text in collapsed player shows full track info

---

## References

- [Aural Player](https://github.com/kartik-venugopal/aural-player) - Winamp-inspired macOS audio player
- Apple Music - Tabbed interface pattern
- MediaMonkey - Multi-pane layout (current inspiration, being replaced)

