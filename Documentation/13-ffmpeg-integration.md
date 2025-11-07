# FFmpeg Integration and Deployment

## Overview

Audientia uses FFmpeg as a bundled library to provide extended audio format support beyond what AVFoundation natively supports. FFmpeg is dynamically linked and included in the application bundle, ensuring users don't need to install it separately.

This document provides comprehensive guidance on FFmpeg integration, bundling, deployment, and compliance requirements.

**Related Documentation**:
- [`04-architecture.md`](04-architecture.md) - System architecture and audio engine design
- [`10-integration-open-source-reuse.md`](10-integration-open-source-reuse.md) - General OSS integration strategy
- [`Sources/AudioCore/README.md`](../Sources/AudioCore/README.md) - AudioCore framework details
- [`Tests/AudioCoreTests/Fixtures/README.md`](../Tests/AudioCoreTests/Fixtures/README.md) - Format specifications and test fixtures

## FFmpeg Requirements

### Version
- **Minimum**: FFmpeg 6.0
- **Recommended**: FFmpeg 8.0+
- **Latest Stable**: Check [FFmpeg Downloads](https://ffmpeg.org/download.html)

### Required Codecs and Features

The following codecs must be enabled in the FFmpeg build:

#### Audio Codecs (Required)
- **FLAC** (`--enable-libflac`) - Free Lossless Audio Codec
- **OGG Vorbis** (`--enable-libvorbis`) - OGG container with Vorbis codec
- **Opus** (`--enable-libopus`) - Opus audio codec
- **ALAC** (built-in) - Apple Lossless Audio Codec
- **APE** (`--enable-libape` or built-in) - Monkey's Audio
- **WavPack** (`--enable-libwavpack`) - WavPack lossless codec
- **AC3** (built-in) - Dolby Digital AC-3
- **DTS** (built-in) - DTS Coherent Acoustics

#### Container Formats (Required)
- **WebM** (`--enable-libvpx` or built-in) - WebM container
- **FLV** (built-in) - Flash Video container

#### Optional Codecs
- **MP3 Encoding** (`--enable-libmp3lame`) - For MP3 encoding (if needed)
- **AAC Encoding** (`--enable-libfdk-aac`) - For AAC encoding (if needed)

### Build Configuration

Recommended FFmpeg build configuration:

```bash
./configure \
  --enable-shared \
  --disable-static \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libwavpack \
  --enable-libflac \
  --prefix=/usr/local/ffmpeg \
  --arch=arm64 \
  --enable-cross-compile
```

For Universal Binary (x86_64 + arm64):
```bash
# Build for arm64
./configure --arch=arm64 --enable-shared [other flags]
make
# Build for x86_64
./configure --arch=x86_64 --enable-shared [other flags]
make
# Create universal binary with lipo
```

## Integration Approach

### 1. Build Phase

FFmpeg libraries are built as dynamic libraries (`.dylib` files) and included in the Xcode project:

```
Audientia.xcodeproj/
└── Frameworks/
    ├── libavcodec.dylib
    ├── libavformat.dylib
    ├── libavutil.dylib
    └── libswresample.dylib
```

### 2. Bundling

During the Xcode build process, FFmpeg libraries are copied to the app bundle:

```
Audientia.app/
└── Contents/
    └── Frameworks/
        ├── libavcodec.dylib
        ├── libavformat.dylib
        ├── libavutil.dylib
        └── libswresample.dylib
```

**Xcode Build Phase**:
1. Add "Copy Files" build phase
2. Destination: "Frameworks"
3. Copy: FFmpeg `.dylib` files
4. Code Sign: Sign all libraries with app's code signature

### 3. Runtime Loading

FFmpeg libraries are loaded dynamically at runtime:

```swift
// Example: Loading FFmpeg library
import Foundation

class FFmpegLoader {
    static func loadFFmpeg() -> Bool {
        guard let frameworksPath = Bundle.main.privateFrameworksPath else {
            return false
        }
        
        let libavcodec = frameworksPath + "/libavcodec.dylib"
        return dlopen(libavcodec, RTLD_LAZY) != nil
    }
}
```

### 4. Fallback Strategy

If FFmpeg is unavailable, the app gracefully falls back to AVFoundation-only formats:

```swift
// FormatDecoderCoordinator.swift
func decodeFormat(for filePath: String) async throws -> DecodedAudioFormat {
    // Try AVFoundation first (native, faster)
    if let format = try? await avFoundationDecoder.decode(filePath: filePath) {
        return format
    }
    
    // Fallback to FFmpeg for extended formats
    if let format = try? await ffmpegDecoder.decode(filePath: filePath) {
        return format
    }
    
    throw FormatDecoderError.unsupportedFormat(...)
}
```

## Distribution

### App Store Distribution

For App Store distribution:
1. **Code Signing**: All FFmpeg libraries must be signed
2. **Entitlements**: No special entitlements required
3. **Size**: FFmpeg libraries add ~10-15MB to app size
4. **License**: Include FFmpeg license in app bundle

### Direct Distribution (.dmg)

For direct distribution:
1. **Code Signing**: Sign all libraries with Developer ID
2. **Notarization**: Include FFmpeg libraries in notarization
3. **License**: Include FFmpeg license file

### License Compliance

**LGPL-2.1 Requirements**:
1. ✅ **Dynamic Linking**: FFmpeg is dynamically linked (compliant)
2. ✅ **License Notice**: Include `LICENSES/FFmpeg-LICENSE.txt`
3. ✅ **Source Code**: Provide link to FFmpeg source
4. ✅ **Attribution**: Credit FFmpeg in About dialog

**License File Location**:
```
Audientia.app/
└── Contents/
    └── Resources/
        └── LICENSES/
            └── FFmpeg-LICENSE.txt
```

## Testing

### Verify FFmpeg Integration

```bash
# Check if FFmpeg libraries are bundled
otool -L Audientia.app/Contents/Frameworks/libavcodec.dylib

# Verify code signing
codesign -dvvv Audientia.app/Contents/Frameworks/libavcodec.dylib

# Test format support
ffmpeg -codecs | grep -E "flac|opus|alac|ape"
```

### Test Format Detection

Run the test suite to verify all formats are detected:

```bash
xcodebuild test -scheme Audientia -only-testing:AudioCoreTests/FormatDecoderCoordinatorTests
```

## Troubleshooting

### FFmpeg Not Found

**Symptom**: Formats requiring FFmpeg fail to decode

**Solutions**:
1. Verify libraries are in `Contents/Frameworks/`
2. Check library paths: `otool -L <library>`
3. Verify code signing: `codesign -dvvv <library>`
4. Check runtime loading: Add logging to `FFmpegLoader`

### Code Signing Issues

**Symptom**: App fails to launch or libraries rejected

**Solutions**:
1. Sign all libraries: `codesign --sign "Developer ID" libavcodec.dylib`
2. Verify entitlements match app
3. Re-sign entire app bundle: `codesign --deep --sign "Developer ID" Audientia.app`

### Version Compatibility

**Symptom**: Crashes or format detection failures

**Solutions**:
1. Verify FFmpeg version: `ffmpeg -version`
2. Check required codecs: `ffmpeg -codecs`
3. Test with known-good FFmpeg build
4. Update to recommended version (8.0+)

## References

- **FFmpeg Official**: https://ffmpeg.org/
- **FFmpeg Documentation**: https://ffmpeg.org/documentation.html
- **LGPL-2.1 License**: https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
- **macOS Code Signing**: https://developer.apple.com/documentation/security/code_signing_services

## Related Documentation

- [`10-integration-open-source-reuse.md`](10-integration-open-source-reuse.md) - General OSS integration and licensing
- [`04-architecture.md`](04-architecture.md) - System architecture and audio engine design
- [`05-roadmap-and-testing-strategy.md`](05-roadmap-and-testing-strategy.md) - Development roadmap and testing approach
- [`../Sources/AudioCore/README.md`](../Sources/AudioCore/README.md) - AudioCore framework implementation details
- [`../Tests/AudioCoreTests/Fixtures/README.md`](../Tests/AudioCoreTests/Fixtures/README.md) - Audio format specifications and test fixtures
- [`../README.md`](../README.md) - Project overview and supported formats

