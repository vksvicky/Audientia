# Audientia Build Guide

This guide explains how to build Audientia for distribution with different configurations.

## Quick Start

Choose the build script that matches your needs:

```bash
# Universal app without libraries (users install FFmpeg/chromaprint)
./Scripts/build_universal_without_libs.sh --dmg

# Universal app with libraries bundled
./Scripts/build_universal_with_libs.sh --dmg

# Apple Silicon app without libraries
./Scripts/build_silicon_without_libs.sh --dmg

# Apple Silicon app with libraries bundled
./Scripts/build_silicon_with_libs.sh --dmg
```

## Build Options Explained

### Universal vs Apple Silicon

- **Universal**: Supports both Intel (x86_64) and Apple Silicon (arm64) Macs
  - Larger binary size
  - Works on all supported Macs
  - Recommended for general distribution

- **Apple Silicon Only**: Only supports Apple Silicon Macs (M1/M2/M3+)
  - Smaller binary size
  - Faster on Apple Silicon
  - Recommended for App Store distribution (if targeting Apple Silicon only)

### With Libraries vs Without Libraries

- **With Libraries**: FFmpeg libraries are bundled in the app
  - Users don't need to install FFmpeg
  - Larger app bundle (~50-100MB additional)
  - Better user experience (no setup required)
  - Requires FFmpeg libraries at build time

- **Without Libraries**: Users must install FFmpeg and chromaprint
  - Smaller app bundle
  - Users need to run: `brew install ffmpeg chromaprint`
  - Better for users who already have these installed
  - Recommended for development/testing

## Prerequisites

### For All Builds
- macOS 15.0 or later
- Xcode 16.0 or later
- XcodeGen: `brew install xcodegen`

### For Builds With Libraries
- FFmpeg libraries built for the target architecture(s)
  - Universal: `ThirdParty/FFmpeg/universal/`
  - Apple Silicon: `ThirdParty/FFmpeg/arm64/`
  - Required libraries:
    - `libavcodec.dylib`
    - `libavformat.dylib`
    - `libavutil.dylib`
    - `libswresample.dylib`

## Building FFmpeg Libraries

If you need to build FFmpeg libraries for bundling:

### For Apple Silicon (arm64)
```bash
# Build FFmpeg with required codecs
./configure \
  --enable-shared \
  --disable-static \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libwavpack \
  --enable-libflac \
  --prefix=/usr/local/ffmpeg \
  --arch=arm64

make
make install

# Copy libraries to project
mkdir -p ThirdParty/FFmpeg/arm64
cp /usr/local/ffmpeg/lib/libavcodec.dylib ThirdParty/FFmpeg/arm64/
cp /usr/local/ffmpeg/lib/libavformat.dylib ThirdParty/FFmpeg/arm64/
cp /usr/local/ffmpeg/lib/libavutil.dylib ThirdParty/FFmpeg/arm64/
cp /usr/local/ffmpeg/lib/libswresample.dylib ThirdParty/FFmpeg/arm64/
```

### For Universal (x86_64 + arm64)
```bash
# Build for arm64
./configure --arch=arm64 --enable-shared [other flags]
make
# Save arm64 libraries

# Build for x86_64
./configure --arch=x86_64 --enable-shared [other flags]
make
# Save x86_64 libraries

# Create universal binaries with lipo
mkdir -p ThirdParty/FFmpeg/universal
lipo -create arm64/libavcodec.dylib x86_64/libavcodec.dylib -output ThirdParty/FFmpeg/universal/libavcodec.dylib
# Repeat for other libraries
```

## Build Output

All builds output to:
- App: `build/[BuildType]/Audientia.app`
- DMG (if `--dmg` specified): `build/[BuildType]/Audientia-[BuildType].dmg`

Where `[BuildType]` is one of:
- `Universal-WithoutLibs`
- `Universal-WithLibs`
- `Silicon-WithoutLibs`
- `Silicon-WithLibs`

## DMG Creation

All build scripts support optional DMG creation with the `--dmg` flag:

```bash
./Scripts/build_universal_without_libs.sh --dmg
```

The DMG will be created in the same directory as the app and can be distributed to users.

## User Installation Instructions

### For Builds Without Libraries

Users must install dependencies before running the app:

```bash
# Install FFmpeg
brew install ffmpeg

# Install chromaprint (for fingerprinting)
brew install chromaprint
```

### For Builds With Libraries

Users only need to:
1. Open the DMG
2. Drag `Audientia.app` to Applications
3. (Optional) Install chromaprint for fingerprinting: `brew install chromaprint`

## Troubleshooting

### Build Fails: XcodeGen Not Found
```bash
brew install xcodegen
```

### Build Fails: FFmpeg Libraries Not Found
- For builds with libraries, ensure FFmpeg libraries are in the correct location:
  - Universal: `ThirdParty/FFmpeg/universal/`
  - Apple Silicon: `ThirdParty/FFmpeg/arm64/`
- Or use a build script without libraries

### DMG Creation Fails
- Ensure you have sufficient disk space
- Check that the app was built successfully
- Try creating DMG manually: `hdiutil create -volname "Audientia" -srcfolder build/... -ov -format UDZO Audientia.dmg`

### App Doesn't Find FFmpeg
- For builds without libraries, ensure FFmpeg is installed and in PATH
- Check with: `which ffmpeg`
- The app looks for FFmpeg in:
  - `/usr/local/bin/ffmpeg`
  - `/opt/homebrew/bin/ffmpeg`
  - `/usr/bin/ffmpeg`
  - PATH

## Recommended Build Configuration

For general distribution:
- **Universal app with libraries**: Best user experience, works on all Macs
- Use: `./Scripts/build_universal_with_libs.sh --dmg`

For App Store distribution:
- **Apple Silicon app with libraries**: Smaller size, faster on Apple Silicon
- Use: `./Scripts/build_silicon_with_libs.sh --dmg`

For development/testing:
- **Universal app without libraries**: Faster builds, smaller bundle
- Use: `./Scripts/build_universal_without_libs.sh`

