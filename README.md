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
- 🎧 **Comprehensive Audio Format Support** - 19 audio formats with multiple sample rates

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

### Development
- macOS 15.0 or later
- Xcode 16.0 or later
- XcodeGen (`brew install xcodegen`)
- Ruby (for project structure sync scripts)
- FFmpeg (for test fixture generation): `brew install ffmpeg`

### Runtime
- macOS 15.0 or later
- **FFmpeg**: Bundled with the application (no user installation required)
  - Version: FFmpeg 6.0+ (recommended: 8.0+)
  - Required codecs: FLAC, OGG, Opus, ALAC, APE, WebM, FLV, AC3, DTS, WavPack
  - Integration: Dynamically linked library bundled in app bundle
  - License: LGPL-2.1 (compliance via dynamic linking)

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

## Supported Audio Formats

Audientia supports a comprehensive range of audio formats across lossy, lossless, and uncompressed categories:

### Lossy Formats
- **MP3** (`.mp3`) - 44.1kHz
- **AAC** (`.aac`, `.m4a`, `.mp4`) - 44.1kHz, 48kHz
- **OGG Vorbis** (`.ogg`) - 44.1kHz, 48kHz
- **Opus** (`.opus`) - 8kHz, 16kHz, 24kHz, 32kHz, 44.1kHz, 48kHz
- **WMA** (`.wma`) - 44.1kHz
- **WebM** (`.webm`) - 48kHz
- **FLV** (`.flv`) - 44.1kHz
- **AC3** (`.ac3`) - 48kHz
- **DTS** (`.dts`) - 48kHz, 96kHz

### Lossless Formats
- **FLAC** (`.flac`) - 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz
- **ALAC** (`.alac`) - 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
- **APE** (`.ape`) - 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
- **WavPack** (`.wv`) - 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
- **DSD** (`.dsf`, `.dff`) - 2.8224MHz (DSD64), 5.6448MHz (DSD128)

### Uncompressed Formats
- **WAV** (`.wav`) - 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz
- **AIFF** (`.aiff`) - 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz
- **CAF** (`.caf`) - Any sample rate

**Total: 19 formats** with support for high-resolution audio up to 192kHz PCM and DSD128 (5.6448MHz).

### Format Decoders

Format detection and decoding are handled by a two-tier decoder system:

1. **AVFoundation** (Primary)
   - Native macOS framework
   - Formats: MP3, AAC, M4A, MP4, WAV, AIFF, CAF, WMA
   - Zero external dependencies
   - Optimized for Apple Silicon

2. **FFmpeg** (Extended Support)
   - Bundled library (included in app distribution)
   - Formats: FLAC, OGG, Opus, ALAC, APE, WebM, FLV, AC3, DTS, WavPack
   - Version: FFmpeg 6.0+ (8.0+ recommended)
   - Integration: Dynamic linking (LGPL-2.1 compliant)
   - Fallback decoder when AVFoundation doesn't support a format

**FFmpeg Deployment**: FFmpeg libraries are automatically bundled with the application. Users do not need to install FFmpeg separately. The libraries are included in the app bundle at:
- `Audientia.app/Contents/Frameworks/libavcodec.dylib`
- `Audientia.app/Contents/Frameworks/libavformat.dylib`
- `Audientia.app/Contents/Frameworks/libavutil.dylib`
- `Audientia.app/Contents/Frameworks/libswresample.dylib`

See [`Documentation/10-integration-open-source-reuse.md`](Documentation/10-integration-open-source-reuse.md) for detailed FFmpeg integration and licensing information.

See [`Documentation/13-ffmpeg-integration.md`](Documentation/13-ffmpeg-integration.md) for comprehensive FFmpeg integration and deployment guide.

See [`Tests/AudioCoreTests/Fixtures/README.md`](Tests/AudioCoreTests/Fixtures/README.md) for detailed format specifications and test fixture information.

## Architecture

See [`Documentation/04-architecture.md`](Documentation/04-architecture.md) for detailed architecture documentation.

### Technology Stack

- **UI**: SwiftUI + AppKit bridge
- **Audio**: C++ engine with AVFoundation/CoreAudio + FFmpeg (bundled)
- **Metadata**: Rust or Swift parsers (ID3v2, Vorbis, MP4)
- **Data**: CoreData + SQLite
- **Plugins**: JavaScriptCore runtime
- **ML/AI**: Core ML, Chromaprint/AcoustID

### External Dependencies

- **FFmpeg 6.0+** (bundled): Audio format decoder library
  - Included in app distribution (no user installation required)
  - Dynamically linked (LGPL-2.1 compliant)
  - See [`Documentation/10-integration-open-source-reuse.md`](Documentation/10-integration-open-source-reuse.md) for integration details
  - See [`Documentation/13-ffmpeg-integration.md`](Documentation/13-ffmpeg-integration.md) for detailed integration guide

## Documentation

### Planning & Vision
- [`Documentation/01-vision-and-name.md`](Documentation/01-vision-and-name.md) - Project vision
- [`Documentation/02-language-evaluation-and-recommendation.md`](Documentation/02-language-evaluation-and-recommendation.md) - Technology choices
- [`Documentation/03-feature-comparison.md`](Documentation/03-feature-comparison.md) - Feature comparison with MediaMonkey

### Architecture & Design
- [`Documentation/04-architecture.md`](Documentation/04-architecture.md) - System architecture
- [`Documentation/05-roadmap-and-testing-strategy.md`](Documentation/05-roadmap-and-testing-strategy.md) - Development roadmap

### Development Guidelines
- [`Documentation/06-best-practices-and-clean-code.md`](Documentation/06-best-practices-and-clean-code.md) - Coding standards
- [`Documentation/07-logging-observability.md`](Documentation/07-logging-observability.md) - Logging patterns
- [`Documentation/12-git-hooks.md`](Documentation/12-git-hooks.md) - Git hooks and pre-commit checks

### Features & Integration
- [`Documentation/08-ml-ai-features.md`](Documentation/08-ml-ai-features.md) - ML/AI features
- [`Documentation/10-integration-open-source-reuse.md`](Documentation/10-integration-open-source-reuse.md) - Open source integration
- [`Documentation/13-ffmpeg-integration.md`](Documentation/13-ffmpeg-integration.md) - FFmpeg integration and deployment guide
- [`Documentation/11-versioning-system.md`](Documentation/11-versioning-system.md) - Version management

See [`Documentation/README.md`](Documentation/README.md) for complete documentation index.

## Contributing

This project follows TDD/BDD principles with comprehensive test coverage. See [`Documentation/05-roadmap-and-testing-strategy.md`](Documentation/05-roadmap-and-testing-strategy.md) for testing guidelines.

## License

MIT License (proposed for desktop UI)
AGPL-3.0 (proposed for server components)

## Roadmap

See [`Documentation/05-roadmap-and-testing-strategy.md`](Documentation/05-roadmap-and-testing-strategy.md) for the complete development roadmap.

**Current Phase**: Phase 0 - Foundation & Infrastructure
- ✅ Project setup and structure
- ✅ Shared Models with TDD/BDD tests
- ✅ Logging infrastructure
- 🔄 DataLayer Foundation (in progress)
- ⏳ AudioCore Foundation

## Support

For issues, questions, or contributions, please contact: support@cycleruncode.club
