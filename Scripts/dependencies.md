# Audientia Build Dependencies

## Mandatory External Libraries

### 1. FFmpeg
- **Purpose**: Audio transcoding, format decoding, and chromaprint fingerprint generation (fallback)
- **Minimum Version**: 6.0
- **Recommended Version**: 8.0+
- **Installation**: 
  - Homebrew: `brew install ffmpeg`
  - Or use bundled version (included in app when building with libraries)
- **Required Codecs**:
  - FLAC (`--enable-libflac`)
  - OGG Vorbis (`--enable-libvorbis`)
  - Opus (`--enable-libopus`)
  - ALAC (built-in)
  - APE (`--enable-libape` or built-in)
  - WavPack (`--enable-libwavpack`)
  - AC3 (built-in)
  - DTS (built-in)
  - WebM (`--enable-libvpx` or built-in)
  - FLV (built-in)
- **Usage**: 
  - Audio transcoding for device sync
  - Extended format support (FLAC, OGG, Opus, etc.)
  - Chromaprint fingerprint generation (fallback method)

### 2. chromaprint/fpcalc
- **Purpose**: Acoustic fingerprinting for track identification
- **Minimum Version**: Latest stable (check Homebrew)
- **Installation**: 
  - Homebrew: `brew install chromaprint`
- **Usage**: 
  - Primary method for generating Chromaprint fingerprints
  - Required for AcoustID track identification

### 3. XcodeGen (Development Only)
- **Purpose**: Generate Xcode project from `project.yml`
- **Minimum Version**: Latest stable
- **Installation**: `brew install xcodegen`
- **Usage**: Required for building the project

## System Frameworks (Bundled with macOS)
- SQLite (via system)
- CoreData (via system)
- AVFoundation (via system)
- CoreAudio (via system)
- SwiftUI (via system)
- AppKit (via system)

## Build Options

### With Libraries Included
- FFmpeg libraries are bundled in the app bundle
- Users don't need to install FFmpeg separately
- Larger app bundle size
- Libraries included at: `Audientia.app/Contents/Frameworks/`

### Without Libraries
- Users must install FFmpeg and chromaprint separately
- Smaller app bundle size
- Requires: `brew install ffmpeg chromaprint`
- App will check for executables in PATH or common locations

## Architecture Support

### Universal (x86_64 + arm64)
- Supports both Intel and Apple Silicon Macs
- Requires universal builds of FFmpeg libraries (if bundled)

### Apple Silicon Only (arm64)
- Only supports Apple Silicon Macs
- Smaller binary size
- Faster on Apple Silicon
- Requires arm64 builds of FFmpeg libraries (if bundled)

