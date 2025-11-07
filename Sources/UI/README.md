# UI Module

SwiftUI-based user interface for Audientia.

## Overview

The UI module contains all SwiftUI views and components that make up the Audientia user interface. It follows MVVM architecture patterns and integrates with all backend modules.

## Structure

```
UI/
├── AudientiaApp.swift    # Main app entry point
├── ContentView.swift      # Root content view
├── NowPlaying/           # Now Playing view and controls
├── Library/              # Library browser (tracks, albums, artists)
├── Playlists/            # Playlist management UI
├── Settings/             # Preferences and configuration
└── Visualizer/           # Metal-powered audio visualizer
```

## Architecture

### MVVM Pattern
- **Views**: SwiftUI views in this module
- **ViewModels**: Located in `UI/` module (UI-specific ViewModels that depend on AudioCore)
- **Models**: Located in `Shared/Models/`

### Dependencies
- `Shared` - Models, ViewModels, utilities
- `AppKitBridge` - AppKit integration
- `AudioCore` - Playback control
- `DataLayer` - Library data
- `MetadataEngine` - Metadata display
- `PluginSystem` - Plugin UI extensions

## Key Components

### AudientiaApp
Main application entry point that:
- Initializes app settings
- Sets up version management
- Configures app lifecycle

### ContentView
Root view that manages the main UI layout and navigation.

### NowPlaying
Displays currently playing track with:
- Playback controls (play, pause, seek, volume)
- Track information and artwork
- Progress indicator
- Queue management

### Library
Library browser with:
- Track list/grid views
- Album browser
- Artist browser
- Search interface
- Filtering and sorting

### Playlists
Playlist management:
- Playlist browser
- Playlist editor
- Smart playlist rule builder
- Drag-and-drop reordering

### Settings
Application preferences:
- Library settings
- Playback settings
- Audio settings (EQ, ReplayGain)
- Plugin management
- Module version information

### Visualizer
Metal-powered audio visualizer:
- Real-time waveform display
- Spectrum analyzer
- Customizable visualizations

## Usage

```swift
import SwiftUI
import Shared

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        VStack {
            Text("Hello, Audientia!")
        }
    }
}
```

## Testing

UI components should be tested with:
- SwiftUI previews
- ViewModel unit tests
- Integration tests for user flows

See [`../../Documentation/05-roadmap-and-testing-strategy.md`](../../Documentation/05-roadmap-and-testing-strategy.md) for testing guidelines.
