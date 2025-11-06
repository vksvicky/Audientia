# PluginSystem Framework

JavaScriptCore-based plugin runtime for extensibility.

## Overview

PluginSystem provides a secure, sandboxed JavaScript runtime for plugins that can extend Audientia's functionality. Plugins can fetch metadata, enhance the library, and extend the UI.

## Structure

```
PluginSystem/
├── Runtime/    # JavaScriptCore runtime setup
├── API/        # Plugin API (Swift → JS bridge)
├── Sandbox/    # Plugin sandboxing
└── Examples/   # Example plugins
```

## Features

### Plugin Runtime
- JavaScriptCore integration
- Plugin sandboxing for security
- Plugin lifecycle management
- Async plugin execution

### Plugin API
- Access to library data
- Metadata fetching
- UI extension callbacks
- File system access (restricted)

### Example Plugins
- Last.fm scrobbler
- Discogs metadata fetcher
- Lyrics fetcher
- Custom visualizers

## Dependencies

- `Shared` - Models and utilities
- JavaScriptCore framework

## Plugin API

Plugins can:
- Read library data (tracks, albums, artists)
- Fetch external metadata
- Extend UI with custom views
- Access playback state (read-only)

Plugins cannot:
- Modify files directly
- Access network without permission
- Block the main thread
- Access sensitive system resources

## Usage

```swift
import PluginSystem

let pluginSystem = PluginSystem()
try await pluginSystem.loadPlugin(at: pluginURL)
try await pluginSystem.executePlugin(pluginId: "lyrics-fetcher", input: track)
```

## Implementation Status

🚧 **In Development** - Framework structure created, implementation pending.

See `Documentation/05-roadmap-and-testing-strategy.md` for roadmap.

## Testing

PluginSystem tests should cover:
- Plugin execution
- Sandbox isolation
- API bridge functionality
- Error handling
- Security boundaries

See `Documentation/05-roadmap-and-testing-strategy.md` for Right-BICEP testing guidelines.
