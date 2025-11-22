#!/bin/bash

# Build Universal App With Libraries Included
# FFmpeg libraries are bundled in the app
#
# Usage:
#   ./build_universal_with_libs.sh [--dmg]
#
# Options:
#   --dmg    Create a DMG file after building

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_NAME="Audientia"
SCHEME="Audientia"
CONFIGURATION="Release"
ARCHITECTURES="x86_64 arm64"

# Parse arguments
CREATE_DMG=false
if [[ "$1" == "--dmg" ]]; then
    CREATE_DMG=true
fi

cd "$PROJECT_ROOT"

echo "🔨 Building Universal App (With Libraries Included)"
echo "==================================================="
echo ""
echo "📦 FFmpeg libraries will be bundled in the app"
echo ""

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "❌ Error: XcodeGen not found"
    echo "   Install with: brew install xcodegen"
    exit 1
fi

# Check for FFmpeg libraries
FFMPEG_LIBS_DIR="$PROJECT_ROOT/ThirdParty/FFmpeg/universal"
if [ ! -d "$FFMPEG_LIBS_DIR" ]; then
    echo "⚠️  Warning: FFmpeg libraries not found at $FFMPEG_LIBS_DIR"
    echo "   Building without bundling FFmpeg libraries"
    echo "   Users will need to install FFmpeg separately"
    BUNDLE_FFMPEG=false
else
    BUNDLE_FFMPEG=true
    echo "✅ Found FFmpeg libraries at $FFMPEG_LIBS_DIR"
fi

# Generate Xcode project
echo "📦 Generating Xcode project..."
xcodegen generate

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build universal app
echo "🔨 Building universal app (x86_64 + arm64)..."
xcodebuild clean build \
    -project "$PROJECT_ROOT/Audientia.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -arch x86_64 \
    -arch arm64 \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "${APP_NAME}.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

# Copy app to build directory
OUTPUT_DIR="$BUILD_DIR/Universal-WithLibs"
mkdir -p "$OUTPUT_DIR"
cp -R "$APP_PATH" "$OUTPUT_DIR/"

# Bundle FFmpeg libraries if available
if [ "$BUNDLE_FFMPEG" = true ]; then
    echo "📦 Bundling FFmpeg libraries..."
    
    FRAMEWORKS_DIR="$OUTPUT_DIR/${APP_NAME}.app/Contents/Frameworks"
    mkdir -p "$FRAMEWORKS_DIR"
    
    # Copy FFmpeg libraries
    for lib in libavcodec.dylib libavformat.dylib libavutil.dylib libswresample.dylib; do
        if [ -f "$FFMPEG_LIBS_DIR/$lib" ]; then
            cp "$FFMPEG_LIBS_DIR/$lib" "$FRAMEWORKS_DIR/"
            echo "   ✅ Copied $lib"
        else
            echo "   ⚠️  Warning: $lib not found"
        fi
    done
    
    # Update library paths using install_name_tool
    echo "🔧 Updating library paths..."
    for lib in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -f "$lib" ]; then
            install_name_tool -id "@rpath/$(basename "$lib")" "$lib" 2>/dev/null || true
        fi
    done
fi

echo ""
echo "✅ Build complete!"
echo "   App location: $OUTPUT_DIR/${APP_NAME}.app"
echo ""

# Create DMG if requested
if [ "$CREATE_DMG" = true ]; then
    echo "📦 Creating DMG..."
    
    DMG_NAME="${APP_NAME}-Universal-WithLibs"
    DMG_PATH="$OUTPUT_DIR/${DMG_NAME}.dmg"
    TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"
    
    # Clean up temp directory
    rm -rf "$TEMP_DMG_DIR"
    mkdir -p "$TEMP_DMG_DIR"
    
    # Copy app to temp directory
    cp -R "$OUTPUT_DIR/${APP_NAME}.app" "$TEMP_DMG_DIR/"
    
    # Create DMG
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$TEMP_DMG_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    # Clean up temp directory
    rm -rf "$TEMP_DMG_DIR"
    
    echo "✅ DMG created: $DMG_PATH"
fi

echo ""
echo "📋 User Requirements:"
echo "   - macOS 15.0 or later"
if [ "$BUNDLE_FFMPEG" = false ]; then
    echo "   - FFmpeg 6.0+ (install with: brew install ffmpeg)"
    echo "   - chromaprint (install with: brew install chromaprint)"
else
    echo "   - No additional libraries required (FFmpeg bundled)"
    echo "   - chromaprint (install with: brew install chromaprint) - optional, for fingerprinting"
fi
echo ""

