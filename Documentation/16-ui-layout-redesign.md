# UI Layout Redesign

## Overview

This document outlines the planned UI layout redesign for Audientia, moving from the current 3-column MediaMonkey-style layout to a cleaner tabbed interface inspired by Apple Music and Aural Player.

**Status**: ✅ Implementation Complete  
**Branch**: `21_ui-layout-redesign`  
**Date**: December 2025  
**Last Updated**: December 2025 (Visualisation Mode Persistence Fix)

> **📸 Screenshot Annotations**: This document includes detailed annotations and "📸 Screenshot Note" callouts throughout the ASCII diagrams. These annotations describe what screenshots would show, component measurements, visual details, spacing, colors, and interaction states. While actual screenshots are not included, these annotations provide comprehensive visual documentation for future contributors.

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

> **📸 Screenshot Note**: A screenshot here would show the window with toolbar collapsed (only expand button visible in top-right), giving maximum vertical space. The player is also collapsed to a single line. This is ideal for immersive viewing like the Visualiser tab.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    [▼]  │ ← Toolbar collapsed (20px height, click to expand)
│  └─ Only expand button visible in top-right corner                                    │
│  └─ Press ⌘T or click [▼] to expand toolbar                                           │
├──────────────────────────────┬──────────────────────────────────────────────────────────┤
│       SIDEBAR (180px)        │                    MAIN CONTENT AREA                      │
│   Still visible, unchanged   │                       (FLEXIBLE)                          │
│                              │   +44px more vertical space (toolbar collapsed)          │
│  ┌────────────────────────┐  │                                                          │
│  │ 🔍 Search...           │  │        ┌────────────────────────────────────────┐        │
│  └────────────────────────┘  │        │                                        │        │
│                              │        │      MAXIMUM CONTENT SPACE             │        │
│  CONTEXTUAL NAVIGATION       │        │                                        │        │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │        │      Toolbar hidden for immersive      │        │
│  (Changes per tab)           │        │      viewing (e.g., Visualiser)        │        │
│                              │        │                                        │        │
│                              │        │      Tab navigation still works via:   │        │
│                              │        │      - Keyboard shortcuts (⌘1-5)      │        │
│                              │        │      - Sidebar contextual navigation  │        │
│                              │        └────────────────────────────────────────┘        │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
├──────────────────────────────┴──────────────────────────────────────────────────────────┤
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
│  └─ Scrolling marquee text   └─ Compact seek bar  └─ Icon controls  └─ [▲] Expand      │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                         ↑ Player collapsed to single line (32px)
                                         ↑ +38px more vertical space (player collapsed)
                                         
**Total Space Saved**: 82px vertical (44px toolbar + 38px player) when both collapsed
```

**Visual Annotations:**
- **Collapsed Toolbar**: Minimal height (20px), semi-transparent background, only expand button visible
- **Content Area**: Maximum vertical space for immersive viewing
- **Collapsed Player**: Single line with scrolling text, compact controls, expand button

### Player Controls - Collapsed State (32px)

> **📸 Screenshot Note**: A screenshot here would show the compact single-line player bar with scrolling track text, inline seek bar, and icon-only controls. The text would be mid-scroll if it's longer than the available width.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
   │                                    │              │                              │
   └─ Scrolling text (marquee)          └─ Seek bar    └─ Transport + Volume         └─ Expand
   │   "◀◀" and "▶▶" indicate scrolling │   Compact slider │   Icon-only buttons    │   Click to expand
   │   Text scrolls smoothly left-to-right when longer than ~200px width              │   Press ⌘P to expand
   
**Component Breakdown:**
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  [Scrolling Text Area]     [Compact Seek Bar]    [Transport Controls]    [Expand]     │
│  ┌──────────────────┐     ┌──────────────┐     ┌──────────────────┐    ┌──────┐      │
│  │ ◀◀ Very Long...  │     │ ────●─────── │     │ [⏮][▶][⏭]      │    │  [▲] │      │
│  │    Track Title   │     │ 1:45 / 4:12  │     │ [🔀][🔁][🔊]    │    │      │      │
│  │    - Artist      │     └──────────────┘     └──────────────────┘    └──────┘      │
│  └──────────────────┘     ~100-200px width     Icon buttons (20x20px)  20x20px      │
│  ~150-250px width          Mini slider control  Spacing: 4px between     Chevron up   │
│  Marquee animation         Time display         Hover states active      icon          │
└─────────────────────────────────────────────────────────────────────────────────────────┘

**Details:**
- **Track Title - Artist**: Scrolls left-to-right (marquee style) when text exceeds ~200px width
  - Scroll speed: 25 pixels/second (tuned for readability)
  - Smooth animation with easing
  - "◀◀" prefix and "▶▶" suffix indicate scrolling state
- **Seek bar**: Compact inline slider with current/total time display
  - Mini control size for space efficiency
  - Time format: "M:SS / M:SS"
- **Controls**: Previous, Play/Pause, Next, Shuffle, Loop, Volume (all icons only, 20x20px)
  - Hover states: Subtle background highlight (accent color, 10% opacity)
  - Pressed states: Darker highlight (accent color, 20% opacity)
  - Active states: Accent color for enabled features (shuffle, loop)
- **[▲] Expand button**: Click to expand to full player view (70px height)
  - Keyboard shortcut: ⌘P to toggle
  - Accessibility: "Expand player" label with hint
```

### Player Controls - Expanded State (70px)

> **📸 Screenshot Note**: A screenshot here would show the full player bar with album artwork on the left, track information in the center, full-width seek bar, and transport controls on the right. The layout is spacious and easy to interact with.

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
   │  60x60px   │  Line 1: Track Title         │  Full-width slider          │  Click or ⌘P
   │  Rounded   │  Line 2: Artist - Album      │  Current / Total time       │  to collapse
   │  corners   │  Font: System 13pt/11pt      │  Format: "M:SS / M:SS"      │  (20x20px)
   │  (4px)     │  Medium weight               │  Slider: Standard size      │  Chevron down
   │            │                              │  Interactive seek control    │  icon

**Component Layout:**
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  [Album Art]  [Track Info]              [Seek Bar]              [Controls]   [Collapse] │
│  ┌────────┐   ┌──────────────────┐      ┌──────────────────┐   ┌──────────┐  ┌──────┐   │
│  │        │   │ Track Title      │      │ ────────●──────── │   │ [⏮][▶][⏭]│  │ [▼] │   │
│  │  60x60 │   │ Artist - Album   │      │ 2:30 / 4:15      │   │ [🔀][🔁] │  │      │   │
│  │  Image │   │                  │      │                  │   │ [🔊━]   │  │      │   │
│  └────────┘   └──────────────────┘      └──────────────────┘   └──────────┘  └──────┘   │
│  Spacing: 12px  Spacing: 12px           Full width minus      Spacing: 8px   20x20px   │
│  Left padding   Left-aligned           art + info + controls  Icon size: 14px           │
│  16px           Two-line layout          Seek bar spans        Hover states              │
│                Truncated if long        available space       Active states             │
└─────────────────────────────────────────────────────────────────────────────────────────┘

**Details:**
- **Album art**: 60x60px artwork thumbnail with 4px rounded corners
  - Extracted from track metadata
  - Placeholder icon if no artwork available
  - Left-aligned with 16px padding
- **Track info**: Two-line layout
  - Line 1: Track title (System font, 13pt, medium weight)
  - Line 2: Artist - Album (System font, 11pt, regular weight)
  - Truncated with ellipsis if too long
  - Left-aligned with 12px spacing from album art
- **Seek bar**: Full-width slider with time labels
  - Standard macOS slider control
  - Current time / Total time display (monospaced digits)
  - Interactive seek control with smooth dragging
  - Time format: "M:SS / M:SS"
- **Controls**: Transport and playback controls
  - Previous, Play/Pause, Next (14px icons)
  - Shuffle, Loop, Volume (14px icons)
  - Spacing: 8px between button groups
  - Hover states: Subtle background highlight
  - Active states: Accent color for enabled features
- **[▼] Collapse button**: Click to collapse to single-line view (32px height)
  - Keyboard shortcut: ⌘P to toggle
  - Accessibility: "Collapse player" label with hint
  - Position: Bottom-right corner
```

### Maximum Content Mode (Both Collapsed)

> **📸 Screenshot Note**: A screenshot here would show the maximum content mode with both toolbar and player collapsed. This is ideal for the Visualiser tab, showing the full visualisation area with minimal UI chrome. The sidebar remains visible for style and settings controls.

For immersive experiences like the Visualiser, both toolbar and player can be collapsed:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    [▼]  │ ← Toolbar collapsed (20px)
│  └─ Only expand button visible                                                         │
│  └─ +44px vertical space saved                                                         │
├──────────────────────────────┬──────────────────────────────────────────────────────────┤
│       SIDEBAR (180px)        │                                                          │
│   Still accessible for       │                                                          │
│   visualisation controls     │                                                          │
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
│  ○ Dual Channel              │        +82px total vertical space                         │
│  ○ Discrete Frequencies      │        (44px toolbar + 38px player)                     │
│  ○ Round Bars Reflex         │                                                          │
│                              │        Ideal for immersive audio                         │
│  SETTINGS                    │        visualisation experience                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  Sensitivity  [━━━●━━]       │                                                          │
│  Smoothing    [━━●━━━]       │                                                          │
│                              │                                                          │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │                                                          │
│  LIBRARY STATS               │                                                          │
│  🎵 1,234 tracks             │                                                          │
├──────────────────────────────┴──────────────────────────────────────────────────────────┤
│  ◀◀ Track Title - Artist ▶▶          ────●────────  1:45/4:12   [⏮][▶][⏭][🔀][🔁][🔊] [▲]│
│  └─ Player collapsed (32px)                                                             │
│  └─ +38px vertical space saved                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘

**Space Savings Breakdown:**
- Toolbar collapsed: 44px → 20px = **+24px saved**
- Player collapsed: 70px → 32px = **+38px saved**
- **Total: +82px vertical space** for maximum content viewing

**Use Cases:**
- Visualiser tab: Maximum screen real estate for audio visualisation
- Library tab: More tracks visible in list view
- Any tab: Focus on content without UI chrome distractions
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

### Collapsed State (20px)

> **📸 Screenshot Note**: A screenshot here would show the collapsed toolbar with only the expand button visible in the top-right corner. The background would be semi-transparent, and the button would be clearly visible for expanding.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    [▼]  │
└─────────────────────────────────────────────────────────────────────────────────────────┘
│  Height: 20px (minimal)                                                               │
│  Background: Semi-transparent (50% opacity)                                           │
│  Only expand button visible in top-right corner                                        │
│                                                                                        │
│  [▼] Expand button:                                                                    │
│  └─ Chevron down icon (10pt, semibold)                                                │
│  └─ Secondary color                                                                   │
│  └─ 20x20px frame                                                                     │
│  └─ Click or press ⌘T to expand                                                      │
│                                                                                        │
│  Tab navigation alternatives:                                                          │
│  └─ Keyboard shortcuts: ⌘1 (Home), ⌘2 (Library), ⌘3 (Playlists), ⌘4 (Devices), ⌘5 (Visualiser)
│  └─ Sidebar contextual navigation (tab-specific quick links)                          │
│  └─ Expand toolbar to access visual tab buttons                                       │

**Space Savings:**
- Expanded: 44px height
- Collapsed: 20px height
- **Saved: 24px vertical space** for content area
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

| File | Action | Status |
|------|--------|--------|
| `MainWindowLayoutView.swift` | **Refactor** | ✅ Complete - New collapsible toolbar + player structure |
| `MainWindowNavigationSidebar.swift` | **Refactor** → `ContextualSidebar.swift` | ✅ Complete - Refactored to `Sources/UI/Layout/Navigation/ContextualSidebar.swift` |
| `MainWindowToolbar.swift` | **Delete** | ✅ Complete - Deleted, replaced by `CollapsibleToolbar.swift` |
| `MainWindowPlaylistPanel.swift` | **Delete** | ✅ Complete - Deleted, no right panel needed |
| `NavigationItem.swift` | **Refactor** → `TabItem.swift` | ✅ Complete - Refactored to `Sources/UI/Layout/Navigation/TabItem.swift` |
| `MainWindowPlayerControls.swift` | **Refactor** → `CollapsiblePlayerBar.swift` | ✅ Complete - Refactored to `Sources/UI/Layout/Player/CollapsiblePlayerBar.swift` |
| `CollapsibleToolbar.swift` | **Create** | ✅ Complete - Created at `Sources/UI/Layout/Navigation/CollapsibleToolbar.swift` |
| `NavigationTabBar.swift` | **Create** | ✅ Complete - Created at `Sources/UI/Layout/Navigation/NavigationTabBar.swift` |
| `ScrollingTextView.swift` | **Create** | ✅ Complete - Created at `Sources/UI/Components/ScrollingTextView.swift` |
| `CompactPlayerControls.swift` | **Create** | ✅ Complete - Created at `Sources/UI/Layout/Player/CompactPlayerControls.swift` |
| `MinimisedPlayerArtworkHelper.swift` | **Create** | ✅ Complete - Created at `Sources/UI/Layout/Player/MinimisedPlayerArtworkHelper.swift` (extracted from MinimisedPlayerView for code organization) |
| `FileNotFoundNotificationHelper.swift` | **Create** | ✅ Complete - Created at `Sources/UI/Notifications/FileNotFoundNotificationHelper.swift` (handles user notifications for missing audio files) |

### Implementation Steps

1. ✅ **Step 1**: Create `TabItem.swift` enum with new tab definitions - **Complete**: `Sources/UI/Layout/Navigation/TabItem.swift`
2. ✅ **Step 2**: Create `NavigationTabBar.swift` horizontal tab component - **Complete**: `Sources/UI/Layout/Navigation/NavigationTabBar.swift`
3. ✅ **Step 3**: Create `CollapsibleToolbar.swift` with expand/collapse toggle - **Complete**: `Sources/UI/Layout/Navigation/CollapsibleToolbar.swift`
4. ✅ **Step 4**: Create `ScrollingTextView.swift` for marquee text animation - **Complete**: `Sources/UI/Components/ScrollingTextView.swift`
5. ✅ **Step 5**: Create `CompactPlayerControls.swift` for collapsed player state - **Complete**: `Sources/UI/Layout/Player/CompactPlayerControls.swift`
6. ✅ **Step 6**: Refactor `MainWindowPlayerControls.swift` → `CollapsiblePlayerBar.swift` - **Complete**: `Sources/UI/Layout/Player/CollapsiblePlayerBar.swift`
7. ✅ **Step 7**: Refactor `MainWindowNavigationSidebar.swift` → `ContextualSidebar.swift` - **Complete**: `Sources/UI/Layout/Navigation/ContextualSidebar.swift`
8. ✅ **Step 8**: Update `MainWindowLayoutView.swift` with new architecture - **Complete**: Fully refactored with collapsible toolbar, contextual sidebar, and collapsible player
9. ✅ **Step 9**: Delete unused files (`MainWindowToolbar.swift`, `MainWindowPlaylistPanel.swift`) - **Complete**: Legacy files removed
10. ✅ **Step 10**: Add keyboard shortcuts (`⌘T` for toolbar, `⌘P` for player, `⌘1-5` for tabs) - **Complete**: All shortcuts implemented
11. ✅ **Step 11**: Update all tests to reflect new structure - **Complete**: Comprehensive TDD/BDD/E2E test suite created
12. ✅ **Step 12**: Code quality improvements and SwiftLint compliance - **Complete**: Fixed all SwiftLint violations including function/file/type body length, long lines, and code organization. Extracted `MinimisedPlayerArtworkHelper.swift` for artwork loading, reduced `MinimisedPlayerView.swift` from 664 to 306 lines, extracted helper methods in `AudioVisualiserTap.swift` and `WindowPositioningHelper.swift`
13. ✅ **Step 13**: Missing file handling with user notifications - **Complete**: Implemented `FileNotFoundNotificationHelper` for system notifications with alert fallback, added file existence checks in `NowPlayingViewModel.loadTrack()` and `play()` methods, created comprehensive TDD (`NowPlayingViewModelMissingFileTests.swift`) and BDD (`NowPlayingViewModelMissingFileBDDTests.swift`) tests for missing file scenarios

### Test Suites

The following test suites have been created to verify the new layout:

- **`TabSwitchingE2ETests.swift`** - End-to-end tests for tab switching workflows (mouse clicks, keyboard shortcuts, content updates, sidebar updates)
- **`CollapsibleComponentsE2ETests.swift`** - End-to-end tests for toolbar/player collapse/expand functionality and state persistence
- **`SearchFunctionalityE2ETests.swift`** - End-to-end tests for search functionality across Library, Playlists, and Devices tabs
- **`TabSpecificViewsUIUXTests.swift`** - UI/UX tests for all 5 tab-specific views (Home, Library, Playlists, Devices, Visualiser)
- **`LayoutPerformanceTests.swift`** - Performance tests for layout transitions (tab switching, collapse/expand, search routing)
- **Component Tests** - TDD/BDD tests for individual components (`NavigationTabBarTests`, `CollapsibleToolbarTests`, `ContextualSidebarTests`, `CollapsiblePlayerBarTests`, `CompactPlayerControlsTests`)

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

## Verification Checklist

This checklist verifies that the implementation matches the documentation and that all components are correctly implemented.

### ✅ Core Component Files

- [x] **TabItem.swift** - `Sources/UI/Layout/Navigation/TabItem.swift` exists
  - [x] Contains 5 tabs: home, library, playlists, devices, visualiser
  - [x] Keyboard shortcuts: ⌘1-5 implemented
  - [x] Icons and display names defined

- [x] **NavigationTabBar.swift** - `Sources/UI/Layout/Navigation/NavigationTabBar.swift` exists
  - [x] Horizontal tab bar component
  - [x] Tab selection binding works
  - [x] Keyboard shortcuts wired up

- [x] **CollapsibleToolbar.swift** - `Sources/UI/Layout/Navigation/CollapsibleToolbar.swift` exists
  - [x] Expanded height: 44px (matches documentation)
  - [x] Collapsed height: 20px (matches documentation)
  - [x] Keyboard shortcut ⌘T implemented
  - [x] Expand/collapse toggle button present

- [x] **ContextualSidebar.swift** - `Sources/UI/Layout/Navigation/ContextualSidebar.swift` exists
  - [x] Search field moved from toolbar
  - [x] Tab-specific content switching
  - [x] Library stats persistent at bottom

- [x] **CollapsiblePlayerBar.swift** - `Sources/UI/Layout/Player/CollapsiblePlayerBar.swift` exists
  - [x] Expanded height: 70px (matches documentation)
  - [x] Collapsed height: 32px (matches documentation)
  - [x] Keyboard shortcut ⌘P implemented
  - [x] Album art, track info, seek bar, controls in expanded state

- [x] **CompactPlayerControls.swift** - `Sources/UI/Layout/Player/CompactPlayerControls.swift` exists
  - [x] Single-line compact player (32px)
  - [x] Scrolling text (marquee) for long track titles
  - [x] Compact seek bar and icon controls

- [x] **ScrollingTextView.swift** - `Sources/UI/Components/ScrollingTextView.swift` exists
  - [x] Marquee text animation
  - [x] Scroll speed: 25 pixels/second (matches documentation, used in CompactPlayerControls)
  - [x] Default speed: 30 pixels/second (configurable via AppSettings)

- [x] **MinimisedPlayerView.swift** - `Sources/UI/Layout/Player/MinimisedPlayerView.swift` exists
  - [x] Floating minimized player window

- [x] **MainWindowLayoutView.swift** - `Sources/UI/Layout/MainWindowLayoutView.swift` exists
  - [x] Refactored with new architecture
  - [x] Collapsible toolbar integrated
  - [x] Contextual sidebar integrated
  - [x] Collapsible player integrated
  - [x] Tab-specific content switching

### ✅ Legacy Files Deleted

- [x] **MainWindowToolbar.swift** - Deleted (replaced by CollapsibleToolbar)
- [x] **MainWindowPlaylistPanel.swift** - Deleted (no right panel needed)
- [x] **MainWindowNavigationSidebar.swift** - Deleted (replaced by ContextualSidebar)
- [x] **MainWindowPlayerControls.swift** - Deleted (replaced by CollapsiblePlayerBar)
- [x] **NavigationItem.swift** - Deleted (replaced by TabItem)

### ✅ Keyboard Shortcuts

- [x] **⌘T** - Toggle toolbar collapse/expand (implemented in CollapsibleToolbar)
- [x] **⌘P** - Toggle player collapse/expand (implemented in CollapsiblePlayerBar)
- [x] **⌘1** - Switch to Home tab (implemented in TabItem + NavigationTabBar)
- [x] **⌘2** - Switch to Library tab (implemented in TabItem + NavigationTabBar)
- [x] **⌘3** - Switch to Playlists tab (implemented in TabItem + NavigationTabBar)
- [x] **⌘4** - Switch to Devices tab (implemented in TabItem + NavigationTabBar)
- [x] **⌘5** - Switch to Visualiser tab (implemented in TabItem + NavigationTabBar)

### ✅ Dimensions & Layout

- [x] **Toolbar heights** - Expanded: 44px, Collapsed: 20px (matches documentation)
- [x] **Player heights** - Expanded: 70px, Collapsed: 32px (matches documentation)
- [x] **Space savings** - Total: 82px when both collapsed (44px + 38px, matches documentation)
- [x] **Sidebar width** - 180px (as documented, defined in ContextualSidebar.width)

### ✅ Tab-Specific Content

- [x] **Home Tab** - HomeContentView with Recently Played, Recently Added, Most Played, Favourites
- [x] **Library Tab** - LibraryBrowserView with browse modes and genre filtering
- [x] **Playlists Tab** - PlaylistBrowserView with playlist list and smart playlists
- [x] **Devices Tab** - DeviceSyncView with connected devices and sync options
- [x] **Visualiser Tab** - AudioVisualiserView with visualisation styles and settings

### ✅ Test Suites

- [x] **TabSwitchingE2ETests.swift** - `Tests/UITests/Layout/TabSwitchingE2ETests.swift` exists
- [x] **CollapsibleComponentsE2ETests.swift** - `Tests/UITests/Layout/CollapsibleComponentsE2ETests.swift` exists
- [x] **SearchFunctionalityE2ETests.swift** - `Tests/UITests/Layout/SearchFunctionalityE2ETests.swift` exists
- [x] **TabSpecificViewsUIUXTests.swift** - `Tests/UITests/Layout/TabSpecificViewsUIUXTests.swift` exists
- [x] **LayoutPerformanceTests.swift** - `Tests/UITests/Layout/LayoutPerformanceTests.swift` exists
- [x] **Component Tests** - All component test files exist:
  - [x] TabItemTests.swift
  - [x] NavigationTabBarTests.swift
  - [x] CollapsibleToolbarTests.swift
  - [x] ContextualSidebarTests.swift
  - [x] CollapsiblePlayerBarTests.swift
  - [x] CompactPlayerControlsTests.swift

### ✅ Features & Functionality

- [x] **Collapsible Toolbar** - Expand/collapse works, state persists
- [x] **Collapsible Player** - Expand/collapse works, state persists
- [x] **Contextual Sidebar** - Content changes per tab correctly
- [x] **Search Integration** - Search works in Library, Playlists, Devices tabs
- [x] **Tab Switching** - Mouse clicks and keyboard shortcuts work
- [x] **State Persistence** - Toolbar/player collapse states persist across app restarts
  - [x] LayoutState model exists (`Sources/Shared/Models/LayoutState.swift`)
  - [x] LayoutStateManager implemented (actor-based, protocol-based)
  - [x] State saved on change via `onChange` handlers
  - [x] State loaded on app launch via `.task` modifier
- [x] **Accessibility** - VoiceOver labels, hints, keyboard navigation implemented
- [x] **Animations** - Smooth transitions with .move(edge:) and .opacity effects
  - [x] Animation duration: 0.25s (matches documentation)
  - [x] .clipped() modifier prevents content overflow during transitions
- [x] **Code Quality & SwiftLint Compliance** - All SwiftLint violations fixed
  - [x] Function body length: Extracted helper methods in `AudioVisualiserTap.swift` and `WindowPositioningHelper.swift`
  - [x] File/type body length: Reduced `MinimisedPlayerView.swift` from 664 to 306 lines by extracting artwork helper and removing duplicate components
  - [x] Long lines: Fixed all long line warnings by splitting log messages across multiple files
  - [x] Code organization: Created `MinimisedPlayerArtworkHelper.swift` for artwork extraction logic
- [x] **Missing File Handling** - User notifications for missing audio files
  - [x] `FileNotFoundNotificationHelper.swift` - Created notification helper for missing files
  - [x] System notifications with fallback to alert dialogs
  - [x] Test environment detection to prevent crashes in tests
  - [x] File existence checks in `NowPlayingViewModel.loadTrack()` and `play()` methods
  - [x] Automatic cleanup of invalid track references when files are missing
  - [x] Comprehensive TDD tests (`NowPlayingViewModelMissingFileTests.swift`)
  - [x] Comprehensive BDD tests (`NowPlayingViewModelMissingFileBDDTests.swift`)
- [x] **AudioEngine Instance Management & Logging** - Fixed duplicate instance creation and redundant logging
  - [x] Fixed duplicate `AudioEngine` creation in `ContentView.swift` (removed initializer from `@State` property)
  - [x] Removed duplicate "Mute toggled" log from `NowPlayingViewModel.toggleMute()` (AudioEngine already logs mute state)
  - [x] Fixed M4A playback tests to check `lastFormatDetectionError` instead of engine state for corrupted file handling
- [x] **Visualisation Mode Persistence Fix** - Fixed race condition in visualisation mode saving
  - [x] Changed `AudioVisualiserViewModel.visualisationMode` save from async `Task` to synchronous save
  - [x] Eliminated race condition where async saves from previous tests could overwrite cleared state in `setUp()`
  - [x] Simplified test code by removing unnecessary `Task.sleep()` calls since save is now synchronous
  - [x] Fixed `testUserChangesModeGetsSaved` test failure caused by stale state from previous test runs
  - [x] Tests now properly isolated with synchronous saves ensuring immediate persistence

### ✅ Documentation

- [x] **Design Document** - This file (`16-ui-layout-redesign.md`) exists and is up to date
- [x] **User Guide** - `Documentation/18-user-guide-ui-layout.md` exists
- [x] **Developer Guide** - `Documentation/19-developer-guide-extending-tabs.md` exists
- [x] **Keyboard Shortcuts Reference** - `Documentation/17-keyboard-shortcuts-reference.md` exists
- [x] **Roadmap Updated** - `Documentation/05-roadmap-and-testing-strategy.md` reflects completion

### ⚠️ Optional Items (Not Required)

- [ ] **Screenshots** - Actual screenshots could be added (currently have annotations only)
- [ ] **Video Demo** - Video walkthrough of the new layout (optional enhancement)

---

## References

- [Aural Player](https://github.com/kartik-venugopal/aural-player) - Winamp-inspired macOS audio player
- Apple Music - Tabbed interface pattern
- MediaMonkey - Multi-pane layout (current inspiration, being replaced)
