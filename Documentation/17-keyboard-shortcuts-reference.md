# Keyboard Shortcuts Reference

## Overview

This document provides a comprehensive reference for all keyboard shortcuts available in Audientia's UI layout.

**Last Updated**: December 2025

---

## Navigation Shortcuts

### Tab Navigation

| Shortcut | Action | Description |
|----------|--------|-------------|
| **⌘1** | Switch to Home tab | Opens the Home tab showing recently played, recently added, most played, and favourites |
| **⌘2** | Switch to Library tab | Opens the Library tab for browsing all tracks, artists, albums, genres, and folders |
| **⌘3** | Switch to Playlists tab | Opens the Playlists tab for managing playlists and smart playlists |
| **⌘4** | Switch to Devices tab | Opens the Devices tab for syncing music to external devices |
| **⌘5** | Switch to Visualiser tab | Opens the Visualiser tab for audio visualisation |

**Note**: Tab navigation shortcuts work globally from anywhere in the application, even when the toolbar is collapsed.

---

## Layout Control Shortcuts

### Toolbar Toggle

| Shortcut | Action | Description |
|----------|--------|-------------|
| **⌘T** | Toggle toolbar | Collapses or expands the navigation toolbar |
| | | - **Expanded**: Shows all navigation tabs (44px height) |
| | | - **Collapsed**: Hides tabs, shows only expand button (20px height) |
| | | - Saves 24px vertical space when collapsed |
| | | - Tab navigation still works via ⌘1-5 when collapsed |

### Player Toggle

| Shortcut | Action | Description |
|----------|--------|-------------|
| **⌘P** | Toggle player | Collapses or expands the player controls bar |
| | | - **Expanded**: Full player with album art, track info, seek bar (70px height) |
| | | - **Collapsed**: Compact single-line player with scrolling text (32px height) |
| | | - Saves 38px vertical space when collapsed |
| | | - All controls remain accessible in collapsed mode |

**Maximum Content Mode**: Collapse both toolbar (⌘T) and player (⌘P) to save **82px total vertical space** for maximum content viewing, ideal for the Visualiser tab.

---

## Dialog Shortcuts

### Playlist Creation Dialog

| Shortcut | Action | Description |
|----------|--------|-------------|
| **Enter** | Create playlist | Submits the playlist creation form |
| **Esc** | Cancel | Closes the playlist creation dialog without saving |

### Smart Playlist Creation Dialog

| Shortcut | Action | Description |
|----------|--------|-------------|
| **Enter** | Create smart playlist | Submits the smart playlist creation form (only if name and rules are valid) |
| **Esc** | Cancel | Closes the smart playlist creation dialog without saving |

---

## Standard macOS Shortcuts

The following standard macOS shortcuts are also available:

| Shortcut | Action | Description |
|----------|--------|-------------|
| **⌘,** | Open Settings | Opens the macOS Settings window |
| **⌘Q** | Quit Application | Quits Audientia |
| **⌘W** | Close Window | Closes the current window |
| **⌘M** | Minimize Window | Minimizes the current window |
| **⌘H** | Hide Application | Hides Audientia |
| **Tab** | Next Focus | Moves keyboard focus to the next interactive element |
| **Shift+Tab** | Previous Focus | Moves keyboard focus to the previous interactive element |
| **Space** | Play/Pause | Toggles playback (when player controls are focused) |

---

## Keyboard Navigation

### Focus Order

When navigating with the keyboard (Tab key), focus moves through interactive elements in the following order:

1. **Toolbar** (if expanded)
   - Home tab
   - Library tab
   - Playlists tab
   - Devices tab
   - Visualiser tab
   - Collapse/Expand button

2. **Sidebar**
   - Search field
   - Quick Access items (Home tab)
   - Browse By items (Library tab)
   - Playlist list (Playlists tab)
   - Device list (Devices tab)
   - Visualisation style options (Visualiser tab)
   - Action buttons

3. **Main Content Area**
   - Tab-specific content (tracks, playlists, devices, visualisation)

4. **Player Controls**
   - Previous track button
   - Play/Pause button
   - Stop button
   - Next track button
   - Shuffle button
   - Loop button
   - Volume control
   - Collapse/Expand button

### Arrow Key Navigation

- **Arrow Keys**: Navigate within lists and grids (Library, Playlists, Devices)
- **Up/Down**: Move selection up or down in vertical lists
- **Left/Right**: Move selection left or right in horizontal lists or grids

---

## Accessibility

All keyboard shortcuts are fully accessible via VoiceOver and other assistive technologies:

- **VoiceOver**: All shortcuts are announced when used
- **Keyboard Navigation**: All interactive elements are keyboard-accessible
- **Focus Indicators**: Clear visual focus indicators for keyboard navigation
- **Accessibility Labels**: All controls have descriptive labels for screen readers

### VoiceOver Shortcuts

When using VoiceOver, the following additional shortcuts are available:

- **VO+Right Arrow**: Move to next element
- **VO+Left Arrow**: Move to previous element
- **VO+Space**: Activate focused element
- **VO+Command+H**: Open VoiceOver Help

---

## Tips and Best Practices

### Maximizing Content Space

1. **For Visualiser**: Collapse both toolbar (⌘T) and player (⌘P) for maximum visualisation area
2. **For Library Browsing**: Collapse player (⌘P) to see more tracks in the list
3. **For Focused Work**: Collapse toolbar (⌘T) to reduce UI chrome

### Quick Tab Switching

- Use ⌘1-5 to quickly switch between tabs without using the mouse
- Shortcuts work even when toolbar is collapsed
- Sidebar contextual navigation also provides quick access to tab-specific content

### Efficient Workflow

1. **Start Playback**: Use Space or click Play button
2. **Switch Tabs**: Use ⌘1-5 for quick navigation
3. **Maximize Content**: Use ⌘T and ⌘P to collapse UI elements
4. **Create Playlist**: Use sidebar "+ New Playlist" button, then Enter to submit

---

## Shortcut Conflicts

If any of these shortcuts conflict with system shortcuts or other applications:

1. **System Preferences**: Some shortcuts can be customized in System Preferences → Keyboard → Shortcuts
2. **Application Settings**: Future versions may allow customization of application shortcuts
3. **Workarounds**: All actions are also accessible via mouse/trackpad and menu items

---

## Reference Summary

### Quick Reference Card

```
Navigation:
  ⌘1  - Home
  ⌘2  - Library
  ⌘3  - Playlists
  ⌘4  - Devices
  ⌘5  - Visualiser

Layout:
  ⌘T  - Toggle Toolbar
  ⌘P  - Toggle Player

Dialogs:
  Enter - Submit
  Esc   - Cancel

Standard:
  ⌘,  - Settings
  ⌘Q  - Quit
  Tab  - Next Focus
  Shift+Tab - Previous Focus
```

---

## Related Documentation

- **UI Layout Redesign**: See `Documentation/16-ui-layout-redesign.md` for detailed layout information
- **Roadmap**: See `Documentation/05-roadmap-and-testing-strategy.md` for implementation details
- **Accessibility**: See `Tests/UITests/Layout/AccessibilityTests.swift` for accessibility test coverage

---

## Version History

- **December 2025**: Initial keyboard shortcuts reference created
  - Documented all navigation shortcuts (⌘1-5)
  - Documented layout control shortcuts (⌘T, ⌘P)
  - Documented dialog shortcuts (Enter, Esc)
  - Added keyboard navigation guide
  - Added accessibility information

