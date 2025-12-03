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
2. **Tabbed Navigation** - Clean top-level organization using horizontal tabs
3. **Contextual Sidebar** - Shows relevant content based on selected tab
4. **Search in Sidebar** - Moved from toolbar to sidebar for consistent placement
5. **Persistent Player Bar** - Always visible at bottom, the ONLY source of "Now Playing" information
6. **Dedicated Visualiser Tab** - Full-screen visualisation experience

### Persistent Elements (Always Visible)

The following elements remain **constant across all tabs**:

| Element | Position | Purpose |
|---------|----------|---------|
| **Title Bar** | Top | Window controls, app title |
| **Navigation Tabs** | Below title bar | Tab switching (Home, Library, Playlists, Devices, Visualiser) |
| **Library Stats** | Bottom of sidebar | Track/artist/album counts, duration |
| **Player Controls** | Bottom of window | Album art, track info, seek bar, transport controls, volume |

The **Player Controls bar never changes or disappears** - it provides continuous playback control and "Now Playing" information regardless of which tab is active.

### Main Layout Structure

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                        TITLE BAR                                         │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                     NAVIGATION TABS                                      │
│     [🏠 Home]  [📚 Library]  [📋 Playlists]  [📱 Devices]  [🎨 Visualiser]               │
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
│                                  PLAYER CONTROLS (70px)                                  │
│  ┌─────┐                                                                                 │
│  │ 🎵  │  Track Title                 ────────●───────────      [⏮][▶][⏭]              │
│  │     │  Artist - Album               1:45 / 4:12              [🔀][🔁] [🔊━━━━━]      │
│  └─────┘                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Tab-Specific Views

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

## Player Controls Bar (Persistent)

The player controls bar is **always visible at the bottom of the window** on every tab and is the **single source of truth** for "Now Playing" information. It never changes position, never hides, and provides continuous playback control.

**Visibility**: ✅ Home | ✅ Library | ✅ Playlists | ✅ Devices | ✅ Visualiser

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  PLAYER CONTROLS (70px)                                  │
│                                                                                         │
│  ┌───────┐   Track Title                    ───────●─────────────   ┌─────────────────┐ │
│  │  🎵   │   Artist - Album                  2:30 / 4:15            │ [⏮] [▶] [⏭]    │ │
│  │ Album │                                                          │ [🔀] [🔁] [🔊━] │ │
│  │  Art  │                                                          └─────────────────┘ │
│  └───────┘                                                                              │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Album art (60x60) on the left
- Track info (title, artist-album) next to art
- Seek bar with time in center
- Transport controls on right
- **No "Now Playing" duplication** - this IS the now playing info

---

## Component Architecture

```
MainWindowLayoutView
│
├── NavigationTabBar              ← PERSISTENT: Horizontal tabs (always visible)
│   ├── Tab: Home
│   ├── Tab: Library  
│   ├── Tab: Playlists
│   ├── Tab: Devices
│   └── Tab: Visualiser
│
├── HStack (Main Content Area)
│   │
│   ├── ContextualSidebar         ← SEMI-PERSISTENT: Always visible, content changes per tab
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
└── PlayerControlsBar             ← PERSISTENT: Always visible, never changes
    ├── AlbumArtView              (60x60 artwork)
    ├── TrackInfoView             (title, artist - album)
    ├── SeekBarView               (progress slider + time labels)
    └── TransportControlsView     (prev/play/next, shuffle, loop, volume)
```

### Element Persistence Summary

| Component | Persistence | Notes |
|-----------|-------------|-------|
| `NavigationTabBar` | **Always visible** | Tab selection changes active tab indicator |
| `ContextualSidebar` | **Always visible** | Content changes based on selected tab |
| `LibraryStats` | **Always visible** | Bottom of sidebar, shows library totals |
| `MainContentView` | **Dynamic** | Swaps content based on selected tab |
| `PlayerControlsBar` | **Always visible** | Never changes, single "Now Playing" source |

---

## Implementation Plan

### Files to Modify

| File | Action | Notes |
|------|--------|-------|
| `MainWindowLayoutView.swift` | **Refactor** | New tab-based structure |
| `MainWindowNavigationSidebar.swift` | **Refactor** → `ContextualSidebar.swift` | Add search, contextual nav |
| `MainWindowToolbar.swift` | **Delete** | Merged into tabs + sidebar |
| `MainWindowPlaylistPanel.swift` | **Delete** | No right panel needed |
| `NavigationItem.swift` | **Refactor** → `TabItem.swift` | Home, Library, Playlists, Devices, Visualiser |
| `MainWindowPlayerControls.swift` | **Keep** | Minor updates |
| **NEW** `NavigationTabBar.swift` | **Create** | Horizontal tab component |

### Implementation Steps

1. **Step 1**: Create `TabItem.swift` enum with new tab definitions
2. **Step 2**: Create `NavigationTabBar.swift` horizontal tab component
3. **Step 3**: Refactor `MainWindowNavigationSidebar.swift` → `ContextualSidebar.swift`
4. **Step 4**: Update `MainWindowLayoutView.swift` with new architecture
5. **Step 5**: Delete unused files (`MainWindowToolbar.swift`, `MainWindowPlaylistPanel.swift`)
6. **Step 6**: Update all tests to reflect new structure

---

## Comparison Summary

| Aspect | Before (Current) | After (Option D) |
|--------|------------------|------------------|
| Navigation | Sidebar nav items | Horizontal tabs |
| Search | Toolbar | Sidebar |
| Right panel | Always visible playlist panel | Removed (no duplication) |
| Visualiser | Toggle button | Dedicated tab |
| "Now Playing" | Multiple places | Player bar only |
| Radio | Present | Removed |
| Layout | 3-column | 2-column (sidebar + content) |
| Content width | ~500px (50%) | ~820px (82%) |

---

## Benefits

1. **No Duplication** - Each piece of info appears in ONE place
2. **More Content Space** - 2-column layout gives more room for content
3. **Cleaner Navigation** - Tabs are familiar and intuitive
4. **Contextual Sidebar** - Shows relevant options per tab
5. **Dedicated Visualiser** - Full tab for immersive visualisation
6. **Persistent Player Bar** - Always visible at bottom, clear and consistent "Now Playing" location on every screen
7. **Modern macOS Feel** - Follows Apple's design patterns
8. **Continuous Playback Control** - Never lose access to play/pause/seek regardless of current view

---

## References

- [Aural Player](https://github.com/kartik-venugopal/aural-player) - Winamp-inspired macOS audio player
- Apple Music - Tabbed interface pattern
- MediaMonkey - Multi-pane layout (current inspiration, being replaced)

