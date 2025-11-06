# Shared Framework

Shared models, utilities, logging, and common code used across all Audientia modules.

## Overview

The Shared framework provides foundational components that all other modules depend on. It contains data models, utilities, logging infrastructure, and version management.

## Structure

```
Shared/
├── Models/          # Core data models
│   ├── Track.swift      # Track model
│   ├── Album.swift      # Album model
│   ├── Artist.swift     # Artist model
│   ├── Playlist.swift   # Playlist model
│   └── AppSettings.swift # Application settings
├── Utilities/       # Helper utilities
│   ├── VersionManager.swift        # App version management
│   ├── ModuleVersionManager.swift # Module version management
│   └── AutoVersionUpdate.swift   # Runtime version updates
├── Logging/         # Logging infrastructure
│   └── Logger.swift # OSLog-based logging system
├── Extensions/      # Swift extensions
└── ViewModels/      # Shared ViewModels (MVVM)
```

## Models

### Track
Represents a single audio track with metadata including title, artist, album, duration, file information, and optional fields like year, genre, and rating.

### Album
Represents an album with title, artist, track count, and total duration.

### Artist
Represents an artist with name, album count, and track count.

### Playlist
Represents a playlist (regular or smart playlist) with name, track count, and duration.

All models are:
- `Codable` for JSON serialization
- `Equatable` and `Hashable` for collections
- `Identifiable` for SwiftUI

## Logging

The Shared framework provides a unified logging system using Apple's OSLog:

```swift
import Shared

Logger.shared.debug("Track created: \(track.title)")
Logger.audio.info("Playback started")
Logger.metadata.debug("Tag parsed")
```

Available loggers:
- `Logger.shared` - Shared framework logging
- `Logger.audio` - Audio engine logging
- `Logger.metadata` - Metadata parsing logging
- `Logger.dataLayer` - Data layer logging
- `Logger.ui` - UI logging
- `Logger.plugin` - Plugin system logging
- `Logger.testing` - Test infrastructure logging

## Version Management

### App Version
Managed by `VersionManager`:
- Format: `yyyy.mm.bbbb` (e.g., `2025.11.0001`)
- Automatically updated during build
- Stored in app settings

### Module Versions
Managed by `ModuleVersionManager`:
- Format: `ModuleName-yyyy.mm.bbbb`
- Automatically detects multiple versions
- Selects latest version
- Cleans up older versions
- Warns about conflicts

## Testing

Comprehensive TDD/BDD tests in `Tests/SharedTests/`:
- Model tests with Right-BICEP coverage
- Mock factories for test data
- Test fixtures with sample JSON
- Performance tests
- Edge case coverage

## Dependencies

None - Shared is the base framework that all other modules depend on.

## Usage

```swift
import Shared

// Create a track
let track = Track(
    title: "Bohemian Rhapsody",
    artist: "Queen",
    album: "A Night at the Opera",
    duration: 355.0,
    filePath: "/path/to/track.mp3",
    fileSize: 8_500_000,
    bitrate: 320,
    sampleRate: 44100
)

// Log with context
Logger.shared.info("Track loaded: \(track.title)")
```
