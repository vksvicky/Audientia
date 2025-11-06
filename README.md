# Audientia

An open-source macOS music manager and player inspired by MediaMonkey, built with a modern, test-first stack. Audientia aims to combine powerful local library management, smart tagging, device sync, and streaming—while integrating ML-assisted organisation and recommendations.

**Company**: CycleRunCode Club
**Package**: club.cycleruncode
**Copyright**: © 2025 CycleRunCode Club. All rights reserved.
**Support**: support@cycleruncode.club

## Features

- 🎵 **Advanced Library Management** - Organize and manage large music collections
- 🏷️ **Smart Tagging** - Automatic metadata enhancement with MusicBrainz, Discogs, and AcoustID
- 🔄 **Device Sync** - Sync music to USB devices, network shares, and cloud storage
- 🎨 **Modern UI** - Native SwiftUI interface with Metal-powered visualizations
- 🤖 **ML/AI Features** - Genre classification, mood detection, and intelligent recommendations
- 🔌 **Plugin System** - Extensible architecture with JavaScriptCore-based plugins
- 🧪 **Test-Driven** - Comprehensive test coverage with TDD, BDD, and ATDD

## Project Structure

```
Audientia/
├── Sources/          # All source code modules
│   ├── UI/          # SwiftUI application
│   ├── Shared/       # Shared models, utilities, logging
│   ├── AppKitBridge/ # SwiftUI ↔ AppKit bridge
│   ├── AudioCore/    # C++/Swift audio engine
│   ├── DataLayer/    # CoreData + SQLite backend
│   ├── MetadataEngine/ # Tag parsing and artwork
│   └── PluginSystem/ # JavaScriptCore plugin runtime
├── Tests/           # Test code
│   └── SharedTests/ # Tests for Shared module
├── Resources/       # Assets and resources
│   └── Assets.xcassets/ # App icon
├── Documentation/   # Project documentation
├── Scripts/         # Build and utility scripts
└── Configuration/   # Project configuration files
```

## Prerequisites

- macOS 15.0 or later
- Xcode 16.0 or later
- XcodeGen (`brew install xcodegen`)
- Ruby (for project structure sync scripts)

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vksvicky/Audientia.git
   cd Audientia
   ```

2. **Generate Xcode project:**
   ```bash
   xcodegen generate
   Scripts/post_generate.sh  # Sync project structure
   ```

3. **Open in Xcode:**
   ```bash
   open Audientia.xcodeproj
   ```

4. **Build and run:**
   - Press ⌘B to build
   - Press ⌘R to run

## Development

### Pre-commit Checks

Run pre-commit checks manually before committing:

```bash
# Check all staged files
./Scripts/pre_commit_checks.sh

# Check specific files
./Scripts/pre_commit_checks.sh Sources/Shared/Models/Track.swift
```

See `Documentation/12-git-hooks.md` for details.

### Running Tests

```bash
# Run all tests
xcodebuild test -project Audientia.xcodeproj -scheme Audientia

# Run specific test target
xcodebuild test -project Audientia.xcodeproj -scheme Audientia -only-testing:SharedTests
```

### Project Generation

The Xcode project is generated from `Configuration/project.yml`. After modifying it:

```bash
xcodegen generate
Scripts/post_generate.sh  # Ensures all fileGroups are visible in Xcode
```

### Version Management

Versions are automatically managed:
- **App**: `yyyy.mm.bbbb` format (e.g., `2025.11.0001`)
- **Modules**: `ModuleName-yyyy.mm.bbbb` format

Version files are generated during build and tracked by `ModuleVersionManager`.

## Architecture

See `Documentation/04-architecture.md` for detailed architecture documentation.

### Technology Stack

- **UI**: SwiftUI + AppKit bridge
- **Audio**: C++ engine with AVFoundation/CoreAudio
- **Metadata**: Rust or Swift parsers (ID3v2, Vorbis, MP4)
- **Data**: CoreData + SQLite
- **Plugins**: JavaScriptCore runtime
- **ML/AI**: Core ML, Chromaprint/AcoustID

## Documentation

- `Documentation/01-vision-and-name.md` - Project vision
- `Documentation/02-language-evaluation-and-recommendation.md` - Technology choices
- `Documentation/03-feature-comparison.md` - Feature comparison with MediaMonkey
- `Documentation/04-architecture.md` - System architecture
- `Documentation/05-roadmap-and-testing-strategy.md` - Development roadmap
- `Documentation/06-best-practices-and-clean-code.md` - Coding standards
- `Documentation/07-logging-observability.md` - Logging patterns
- `Documentation/08-ml-ai-features.md` - ML/AI features
- `Documentation/10-integration-open-source-reuse.md` - Open source integration
- `Documentation/11-versioning-system.md` - Version management
- `Documentation/12-git-hooks.md` - Git hooks and pre-commit checks

## Contributing

This project follows TDD/BDD principles with comprehensive test coverage. See `Documentation/05-roadmap-and-testing-strategy.md` for testing guidelines.

## License

MIT License (proposed for desktop UI)
AGPL-3.0 (proposed for server components)

## Roadmap

See `Documentation/05-roadmap-and-testing-strategy.md` for the complete development roadmap.

**Current Phase**: Phase 0 - Foundation & Infrastructure
- ✅ Project setup and structure
- ✅ Shared Models with TDD/BDD tests
- ✅ Logging infrastructure
- 🔄 DataLayer Foundation (in progress)
- ⏳ AudioCore Foundation

## Support

For issues, questions, or contributions, please contact: support@cycleruncode.club
