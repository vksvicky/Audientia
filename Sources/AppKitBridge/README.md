# AppKitBridge Framework

SwiftUI ↔ AppKit bridge components for integrating native macOS features.

## Overview

AppKitBridge provides seamless integration between SwiftUI and AppKit, enabling access to native macOS features that aren't directly available in SwiftUI.

## Structure

```
AppKitBridge/
├── DragAndDrop/      # Drag and drop support
├── FileDialogs/       # File open/save dialogs
├── MenuIntegration/  # Menu bar integration
└── SystemMediaControls/ # Media keys and Now Playing info
```

## Features

### Drag and Drop
- File drag and drop support
- Library item drag and drop
- Playlist reordering via drag and drop

### File Dialogs
- File open dialogs for importing music
- Folder selection for library scanning
- Save dialogs for exports

### Menu Integration
- Menu bar integration
- Context menus
- Keyboard shortcuts

### System Media Controls
- Media key support (play, pause, next, previous)
- Now Playing info for Control Center
- Lock screen media controls

## Dependencies

- `Shared` - Common utilities and models

## Usage

```swift
import AppKitBridge

// Use AppKit components in SwiftUI
let fileDialog = FileDialog()
fileDialog.showOpenPanel { urls in
    // Handle selected files
}
```

## Implementation Status

🚧 **In Development** - Framework structure created, implementation pending.

See `Documentation/05-roadmap-and-testing-strategy.md` for roadmap.
