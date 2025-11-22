#!/bin/bash

# Build Apple Silicon App Without Libraries
# Users must install FFmpeg and chromaprint separately
#
# Usage:
#   ./build_silicon_without_libs.sh [--dmg]
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
ARCHITECTURE="arm64"

# Parse arguments
CREATE_DMG=false
if [[ "$1" == "--dmg" ]]; then
    CREATE_DMG=true
fi

cd "$PROJECT_ROOT"

echo "🔨 Building Apple Silicon App (Without Libraries)"
echo "=================================================="
echo ""
echo "⚠️  IMPORTANT: Users must install the following libraries:"
echo "   - FFmpeg 6.0+ (brew install ffmpeg)"
echo "   - chromaprint (brew install chromaprint)"
echo ""

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "❌ Error: XcodeGen not found"
    echo "   Install with: brew install xcodegen"
    exit 1
fi

# Generate Xcode project
echo "📦 Generating Xcode project..."
xcodegen generate

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build Apple Silicon app
echo "🔨 Building Apple Silicon app (arm64)..."
xcodebuild clean build \
    -project "$PROJECT_ROOT/Audientia.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -arch arm64 \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -destination "generic/platform=macOS,variant=Mac Catalyst" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS=arm64

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "${APP_NAME}.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

# Copy app to build directory
OUTPUT_DIR="$BUILD_DIR/Silicon-WithoutLibs"
mkdir -p "$OUTPUT_DIR"
cp -R "$APP_PATH" "$OUTPUT_DIR/"

# Copy installation instructions to app bundle Resources
RESOURCES_DIR="$OUTPUT_DIR/${APP_NAME}.app/Contents/Resources"
mkdir -p "$RESOURCES_DIR"
cp "$SCRIPT_DIR/INSTALL_INSTRUCTIONS.md" "$RESOURCES_DIR/" 2>/dev/null || true

echo ""
echo "✅ Build complete!"
echo "   App location: $OUTPUT_DIR/${APP_NAME}.app"
echo ""

# Create DMG if requested
if [ "$CREATE_DMG" = true ]; then
    echo "📦 Creating DMG..."
    
    DMG_NAME="${APP_NAME}-Silicon-WithoutLibs"
    DMG_PATH="$OUTPUT_DIR/${DMG_NAME}.dmg"
    TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"
    
    # Clean up temp directory
    rm -rf "$TEMP_DMG_DIR"
    mkdir -p "$TEMP_DMG_DIR"
    
    # Copy app to temp directory
    cp -R "$OUTPUT_DIR/${APP_NAME}.app" "$TEMP_DMG_DIR/"
    
    # Copy dependency checker and instructions
    cp "$SCRIPT_DIR/check_dependencies.sh" "$TEMP_DMG_DIR/"
    cp "$SCRIPT_DIR/INSTALL_INSTRUCTIONS.md" "$TEMP_DMG_DIR/"
    chmod +x "$TEMP_DMG_DIR/check_dependencies.sh"
    
    # Create DMG
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$TEMP_DMG_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    # Clean up temp directory
    rm -rf "$TEMP_DMG_DIR"
    
    echo "✅ DMG created: $DMG_PATH"
    echo ""
    echo "📋 Installation Instructions for Users:"
    echo "   1. Open the DMG"
    echo "   2. Run check_dependencies.sh to verify dependencies"
    echo "   3. Install missing dependencies: brew install ffmpeg chromaprint"
    echo "   4. Drag ${APP_NAME}.app to Applications"
fi

echo ""
echo "📋 User Requirements:"
echo "   - macOS 15.0 or later"
echo "   - Apple Silicon Mac (M1/M2/M3 or later)"
echo "   - FFmpeg 6.0+ (install with: brew install ffmpeg)"
echo "   - chromaprint (install with: brew install chromaprint)"
echo ""

