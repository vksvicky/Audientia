# User Guide: UI Layout Features

## Overview

This guide explains how to use Audientia's modern tabbed interface. The new layout provides a cleaner, more efficient way to navigate your music library, manage playlists, sync devices, and enjoy audio visualisation.

**Last Updated**: December 2025

---

## Getting Started

### Main Window Layout

The main window consists of four main areas:

1. **Toolbar** (top) - Navigation tabs that can be collapsed
2. **Sidebar** (left) - Contextual navigation that changes per tab
3. **Content Area** (center) - Tab-specific content
4. **Player Controls** (bottom) - Always-visible playback controls that can be collapsed

### Quick Navigation

- **⌘1** - Home tab
- **⌘2** - Library tab
- **⌘3** - Playlists tab
- **⌘4** - Devices tab
- **⌘5** - Visualiser tab
- **⌘T** - Toggle toolbar (collapse/expand)
- **⌘P** - Toggle player (collapse/expand)

---

## 🏠 Home Tab

The Home tab is your starting point, showing quick access to your most important content.

### Features

#### Recently Played
- Displays the last 10 tracks you've played
- Automatically updates as you listen
- Click any track to play it again

#### Recently Added
- Shows the most recently added tracks to your library
- Great for discovering new music you've just imported

#### Most Played
- Lists your most frequently played tracks
- Sorted by play count (highest first)
- Excludes tracks you've skipped

#### Favourites
- Shows tracks you've rated 4 stars or higher
- Sorted by rating (highest first)
- Quick access to your best-loved music

### Sidebar Actions

- **Import Files** - Add new music files to your library
- **Settings** - Open application settings

### Quick Access Links

The sidebar provides quick links to:
- Recently Played
- Recently Added
- Most Played
- Favourites

---

## 📚 Library Tab

Browse and search your entire music library with powerful filtering options.

### Features

#### Browse By
Navigate your library by different views:
- **All Tracks** - See every track in your library
- **Artists** - Browse by artist
- **Albums** - Browse by album
- **Genres** - Browse by genre
- **Years** - Browse by release year
- **Folders** - Browse by folder structure

#### Genre Filtering
- Select one or multiple genres to filter
- Checkboxes allow multi-select
- Filter updates in real-time as you select/deselect genres

#### Search
- Search field in the sidebar
- Searches across track title, artist, album, and genre
- Case-insensitive partial matching
- Results update as you type

#### Track List
- Displays tracks in a table format
- Shows: Track number, Title, Artist, Album, Duration
- Select multiple tracks for batch operations
- Right-click for context menu actions

### Tips

- **Quick Search**: Type in the sidebar search field to instantly filter tracks
- **Multi-Genre Filter**: Select multiple genres to see tracks that match any of them
- **Browse Mode**: Switch between different browse modes to explore your library differently

---

## 📋 Playlists Tab

Create and manage playlists, including smart playlists that update automatically.

### Features

#### Regular Playlists
- Create custom playlists with any tracks you want
- Organize your music by mood, activity, or any theme
- Edit playlists to add or remove tracks
- Delete playlists you no longer need

#### Smart Playlists
Three built-in smart playlists:
- **Recently Added** - Tracks added to your library recently
- **Top Rated** - All rated tracks sorted by rating
- **5-Star Tracks** - Only your 5-star rated tracks

Smart playlists update automatically as your library changes.

#### Creating Playlists

**Regular Playlist:**
1. Click "+ New Playlist" in the sidebar
2. Enter a playlist name
3. Click "Create" or press Enter
4. Add tracks by selecting them and using "Add to Playlist"

**Smart Playlist:**
1. Click "+ New Smart Playlist" in the sidebar
2. Enter a playlist name
3. Add rules using the rule builder:
   - Select a field (Title, Artist, Album, Genre, Year, Rating, etc.)
   - Choose an operator (equals, contains, greater than, etc.)
   - Enter a value
   - Add multiple rules with AND/OR logic
4. Click "Create" or press Enter

#### Playlist Management
- **Search**: Use the sidebar search to find playlists by name
- **Select**: Click a playlist in the sidebar to view its tracks
- **Play**: Click "Play All" to start playback
- **Shuffle**: Click the shuffle button to randomize playback
- **Edit**: Modify playlist name or tracks
- **Delete**: Remove playlists you no longer need

### Tips

- **Smart Playlist Rules**: Use multiple rules with AND/OR logic to create complex playlists
- **Quick Access**: Use sidebar search to quickly find playlists in large collections
- **Playlist Organization**: Create playlists for different moods, activities, or time periods

---

## 📱 Devices Tab

Sync your music library to external devices like iPhones, iPads, or USB drives.

### Features

#### Device List
- Shows all connected devices
- Displays device name, type, and connection status
- Click a device to select it for syncing

#### Sync Options
Choose what to sync:
- **Entire Library** - Sync all tracks in your library
- **Selected Playlists** - Sync only specific playlists
- **Checked Tracks Only** - Sync only tracks you've manually selected

#### Sync Content Selection
When "Selected Playlists" is chosen:
- Checkboxes for each playlist
- Shows track count per playlist
- Select multiple playlists to sync

#### Device Information
- Storage capacity and usage
- Last sync time
- Connection status

### Tips

- **Selective Sync**: Use "Selected Playlists" to sync only what you need, saving device storage
- **Search Devices**: Use sidebar search to find specific devices by name
- **Sync Settings**: Configure sync options before starting to ensure you sync the right content

---

## 🎨 Visualiser Tab

Enjoy immersive audio visualisation with multiple visual styles and customizable settings.

### Features

#### Visualisation Styles
Choose from multiple visualisation modes:
- **LED Bars** - Classic frequency bars
- **Lumi Bars** - Luminous frequency bars
- **Radial Spectrum** - Circular frequency display
- **Dual Channel** - Separate left/right channel visualization
- **Discrete Frequencies** - Individual frequency bands
- **Round Bars Reflex** - Rounded bars with reflection effects

#### Settings
Customize your visualisation:
- **Sensitivity** - Adjust how responsive the visualisation is to audio
- **Smoothing** - Control how smooth the transitions are
- **Colour Theme** - Choose accent colours for the visualisation

#### Maximum Content Mode
For the best visualisation experience:
1. Press **⌘T** to collapse the toolbar
2. Press **⌘P** to collapse the player
3. Enjoy maximum screen space for visualisation

### Tips

- **Full Screen Experience**: Collapse both toolbar and player for immersive viewing
- **Experiment with Styles**: Try different visualisation styles to find your favorite
- **Adjust Settings**: Fine-tune sensitivity and smoothing to match your audio content

---

## Collapsible Elements

### Toolbar (⌘T)

The toolbar contains navigation tabs and can be collapsed to maximize content space.

**Expanded State:**
- Shows all 5 navigation tabs (Home, Library, Playlists, Devices, Visualiser)
- 44px height
- Click the up arrow (▲) or press ⌘T to collapse

**Collapsed State:**
- Hides tabs, shows only expand button
- 20px height
- Saves 24px vertical space
- Click the down arrow (▼) or press ⌘T to expand
- Tab navigation still works via ⌘1-5 keyboard shortcuts

**When to Use:**
- Collapse when you want maximum content space
- Keep expanded for easy tab switching with mouse
- Collapse for immersive experiences (like Visualiser)

### Player Controls (⌘P)

The player controls are always visible at the bottom and can be collapsed to a compact single-line view.

**Expanded State:**
- Full player with album art (60x60px)
- Track title and artist on two lines
- Full-width seek bar with time display
- Spacious transport controls
- 70px height
- Click the down arrow (▼) or press ⌘P to collapse

**Collapsed State:**
- Compact single-line view
- Scrolling track title and artist (marquee text)
- Inline seek bar with time
- Icon-only controls
- 32px height
- Saves 38px vertical space
- Click the up arrow (▲) or press ⌘P to expand

**Scrolling Text:**
- When track title + artist is too long, text scrolls smoothly
- Shows "◀◀" and "▶▶" indicators when scrolling
- Scrolls at 25 pixels/second for readability

**When to Use:**
- Collapse to see more tracks in Library or Playlists
- Keep expanded for full control and album art
- Collapse for maximum content mode (with toolbar)

### Maximum Content Mode

Collapse both toolbar and player for maximum content viewing:
- **Total Space Saved**: 82px vertical (24px toolbar + 38px player)
- **Ideal For**: Visualiser tab, browsing large track lists
- **How To**: Press ⌘T then ⌘P (or vice versa)

---

## Search Functionality

Search is available in the sidebar and works differently per tab:

### Library Tab
- Searches across: Track title, Artist, Album, Genre
- Case-insensitive partial matching
- Updates results as you type
- Works with genre filters and browse modes

### Playlists Tab
- Searches playlist names only
- Case-insensitive partial matching
- Filters the playlist list in the sidebar
- Click a playlist to view its tracks

### Devices Tab
- Searches device names only
- Case-insensitive partial matching
- Filters the device list in the sidebar
- Helps find specific devices quickly

### Home & Visualiser Tabs
- Search field is present but not actively used
- These tabs show curated content that doesn't need search

### Search Tips
- **Partial Matching**: You don't need to type the full name
- **Case Insensitive**: Search works regardless of capitalization
- **Whitespace**: Extra spaces are automatically trimmed
- **Real-time**: Results update as you type

---

## Creating Playlists

### Regular Playlist

1. Navigate to the **Playlists** tab (⌘3)
2. Click **"+ New Playlist"** in the sidebar
3. Enter a playlist name in the dialog
4. Click **"Create"** or press **Enter**
5. Select tracks from Library and add them to your playlist

**Validation:**
- Playlist name cannot be empty
- Playlist name cannot duplicate an existing playlist (case-insensitive)
- Error messages appear if validation fails

### Smart Playlist

1. Navigate to the **Playlists** tab (⌘3)
2. Click **"+ New Smart Playlist"** in the sidebar
3. Enter a playlist name
4. Build rules using the rule builder:
   - **Field**: Choose what to filter (Title, Artist, Album, Genre, Year, Rating, etc.)
   - **Operator**: Choose how to match (equals, contains, starts with, greater than, etc.)
   - **Value**: Enter the value to match
   - **Add Rule**: Click to add another rule
   - **Logical Operator**: Choose AND or OR to combine rules
5. Click **"Create"** or press **Enter**

**Validation:**
- Playlist name cannot be empty
- Playlist name cannot duplicate an existing playlist
- At least one valid rule must be added
- Error messages appear if validation fails

**Smart Playlist Tips:**
- Use **AND** to match tracks that meet ALL rules
- Use **OR** to match tracks that meet ANY rule
- Combine multiple fields for complex filtering
- Smart playlists update automatically as your library changes

---

## Player Controls

The player controls are always visible at the bottom of the window, regardless of which tab you're on.

### Expanded Player Features

- **Album Art**: 60x60px artwork thumbnail
- **Track Info**: Title (line 1), Artist - Album (line 2)
- **Seek Bar**: Full-width slider with current/total time
- **Transport Controls**: Previous, Play/Pause, Stop, Next
- **Playback Controls**: Shuffle, Loop, Volume, Mute

### Collapsed Player Features

- **Scrolling Text**: Track title and artist scroll when too long
- **Compact Seek Bar**: Inline slider with time display
- **Icon Controls**: All controls as compact icons
- **Expand Button**: Click to return to expanded view

### Keyboard Shortcuts

- **Space**: Play/Pause (when player is focused)
- **⌘P**: Toggle player expanded/collapsed
- **Arrow Keys**: Navigate queue (when available)

---

## Tips and Best Practices

### Maximizing Content Space

1. **For Visualiser**: Collapse both toolbar (⌘T) and player (⌘P) for maximum visualisation area
2. **For Library Browsing**: Collapse player (⌘P) to see more tracks in the list
3. **For Focused Work**: Collapse toolbar (⌘T) to reduce UI chrome

### Efficient Navigation

1. **Quick Tab Switching**: Use ⌘1-5 to switch tabs instantly
2. **Keyboard Shortcuts**: Learn ⌘T and ⌘P for layout control
3. **Sidebar Navigation**: Use sidebar quick links for tab-specific content

### Playlist Management

1. **Smart Playlists**: Use smart playlists for automatically updating collections
2. **Regular Playlists**: Use regular playlists for manually curated collections
3. **Search**: Use sidebar search to quickly find playlists in large collections

### Library Organization

1. **Browse Modes**: Switch between different browse modes to explore your library
2. **Genre Filters**: Use multi-select genre filters to find specific music
3. **Search**: Combine search with filters for precise results

### Visualisation

1. **Try Different Styles**: Experiment with visualisation styles to find your favorite
2. **Adjust Settings**: Fine-tune sensitivity and smoothing for best results
3. **Maximum Mode**: Use collapsed toolbar and player for immersive experience

---

## Troubleshooting

### Toolbar/Player Won't Collapse

- Check if keyboard shortcuts are working (⌘T, ⌘P)
- Try clicking the collapse/expand buttons directly
- Restart the application if issues persist

### Search Not Working

- Make sure you're on a tab that supports search (Library, Playlists, Devices)
- Check that you've typed something in the search field
- Clear the search field and try again

### Playlist Creation Fails

- Ensure playlist name is not empty
- Check that playlist name doesn't already exist
- For smart playlists, ensure at least one valid rule is added

### Tabs Not Switching

- Try using keyboard shortcuts (⌘1-5) instead of mouse clicks
- Check if the toolbar is collapsed (expand it if needed)
- Restart the application if issues persist

---

## Related Documentation

- **Keyboard Shortcuts**: See `Documentation/17-keyboard-shortcuts-reference.md` for complete shortcut reference
- **UI Layout Design**: See `Documentation/16-ui-layout-redesign.md` for design details
- **Roadmap**: See `Documentation/05-roadmap-and-testing-strategy.md` for implementation details

---

## Version History

- **December 2025**: Initial user guide created
  - Documented all 5 tabs (Home, Library, Playlists, Devices, Visualiser)
  - Documented collapsible toolbar and player features
  - Documented search functionality
  - Documented playlist creation (regular and smart)
  - Added tips and best practices
  - Added troubleshooting section

