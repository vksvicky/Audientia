# DataLayer Framework

CoreData + SQLite backend for library management and persistence.

## Overview

DataLayer provides the data persistence layer for Audientia, managing the music library, playlists, user preferences, and metadata cache.

## Structure

```
DataLayer/
├── CoreData/    # CoreData model and stack
├── SQLite/      # SQLite metadata cache
└── Migrations/  # Database migration system
```

## Features

### Library Management
- Track indexing and storage
- Album and artist aggregation
- Library statistics
- Search and filtering

### Playlist Management
- Regular playlists
- Smart playlists with rule engine
- Playlist CRUD operations
- Playlist statistics

### Metadata Cache
- SQLite-based metadata cache
- Fast metadata lookups
- Cache invalidation and updates

### Data Persistence
- CoreData for structured data
- SQLite for performance-critical queries
- Migration system for schema updates

## Dependencies

- `Shared` - Models and utilities
- CoreData framework
- SQLite3

## CoreData Model

### Entities
- `Track` - Audio track information
- `Album` - Album information
- `Artist` - Artist information
- `Playlist` - Playlist information
- `PlaylistItem` - Playlist track associations

## Usage

```swift
import DataLayer

let dataLayer = DataLayer()
try await dataLayer.addTrack(track)
let tracks = try await dataLayer.searchTracks(query: "jazz")
```

## Implementation Status

🚧 **In Development** - Framework structure created, implementation pending.

See `Documentation/05-roadmap-and-testing-strategy.md` for roadmap.

## Testing

DataLayer tests should cover:
- CoreData stack initialization
- Migration tests
- Data integrity
- Performance with large datasets

See `Documentation/05-roadmap-and-testing-strategy.md` for Right-BICEP testing guidelines.
