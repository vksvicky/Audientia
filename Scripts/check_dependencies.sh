#!/bin/bash

# Dependency Checker for Audientia
# Checks for required external libraries and shows notifications
#
# Usage:
#   ./check_dependencies.sh [--notify]
#
# Options:
#   --notify    Show macOS notifications for missing dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISSING_DEPS=()
WARNINGS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
SHOW_NOTIFICATIONS=false
if [[ "$1" == "--notify" ]]; then
    SHOW_NOTIFICATIONS=true
fi

# Function to show macOS notification
show_notification() {
    local title="$1"
    local message="$2"
    if [ "$SHOW_NOTIFICATIONS" = true ]; then
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    fi
}

# Function to check if a command exists
check_command() {
    local cmd="$1"
    local name="$2"
    local min_version="$3"
    
    if command -v "$cmd" &> /dev/null; then
        # Get version if possible
        local version=""
        if [ "$cmd" = "ffmpeg" ]; then
            version=$(ffmpeg -version 2>/dev/null | head -n 1 | grep -oE 'version [0-9]+\.[0-9]+' | cut -d' ' -f2 || echo "")
        elif [ "$cmd" = "fpcalc" ]; then
            version=$(fpcalc -version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || echo "")
        fi
        
        if [ -n "$version" ]; then
            echo -e "${GREEN}✅ $name found${NC} (version: $version)"
            
            # Check minimum version if specified
            if [ -n "$min_version" ] && [ -n "$version" ]; then
                # Simple version comparison (works for major.minor format)
                local min_major=$(echo "$min_version" | cut -d'.' -f1)
                local min_minor=$(echo "$min_version" | cut -d'.' -f2)
                local ver_major=$(echo "$version" | cut -d'.' -f1)
                local ver_minor=$(echo "$version" | cut -d'.' -f2)
                
                if [ "$ver_major" -lt "$min_major" ] || ([ "$ver_major" -eq "$min_major" ] && [ "$ver_minor" -lt "$min_minor" ]); then
                    echo -e "${YELLOW}⚠️  Warning: $name version $version is below minimum required version $min_version${NC}"
                    WARNINGS+=("$name version $version is below minimum required $min_version")
                fi
            fi
        else
            echo -e "${GREEN}✅ $name found${NC}"
        fi
        return 0
    else
        echo -e "${RED}❌ $name not found${NC}"
        MISSING_DEPS+=("$name")
        return 1
    fi
}

# Function to check for executable in common paths
check_executable_paths() {
    local name="$1"
    local display_name="$2"
    local paths=(
        "/usr/local/bin/$name"
        "/opt/homebrew/bin/$name"
        "/usr/bin/$name"
    )
    
    for path in "${paths[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then
            echo -e "${GREEN}✅ $display_name found at: $path${NC}"
            return 0
        fi
    done
    
    return 1
}

echo "🔍 Checking Audientia Dependencies"
echo "=================================="
echo ""

# Check FFmpeg
echo "Checking FFmpeg..."
if ! check_command "ffmpeg" "FFmpeg" "6.0"; then
    # Try checking common paths
    if check_executable_paths "ffmpeg" "FFmpeg"; then
        MISSING_DEPS=("${MISSING_DEPS[@]/FFmpeg/}")
    else
        show_notification "Audientia Dependency Missing" "FFmpeg is required but not found. Install with: brew install ffmpeg"
    fi
fi
echo ""

# Check chromaprint/fpcalc
echo "Checking chromaprint (fpcalc)..."
if ! check_command "fpcalc" "chromaprint" ""; then
    # Try checking common paths
    if check_executable_paths "fpcalc" "chromaprint"; then
        MISSING_DEPS=("${MISSING_DEPS[@]/chromaprint/}")
    else
        show_notification "Audientia Dependency Missing" "chromaprint is required for fingerprinting. Install with: brew install chromaprint"
        # Note: chromaprint is optional for basic functionality, so we'll warn but not fail
        WARNINGS+=("chromaprint not found (optional for fingerprinting)")
    fi
fi
echo ""

# Summary
echo "=================================="
if [ ${#MISSING_DEPS[@]} -eq 0 ] && [ ${#WARNINGS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All dependencies are installed!${NC}"
    show_notification "Audientia Dependencies" "All required dependencies are installed"
    exit 0
elif [ ${#MISSING_DEPS[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Dependencies installed with warnings:${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo -e "  ${YELLOW}- $warning${NC}"
    done
    show_notification "Audientia Dependencies" "Dependencies installed with warnings"
    exit 0
else
    echo -e "${RED}❌ Missing required dependencies:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo -e "  ${RED}- $dep${NC}"
    done
    echo ""
    echo "Installation instructions:"
    echo "  brew install ffmpeg"
    echo "  brew install chromaprint"
    echo ""
    show_notification "Audientia Dependencies Missing" "Please install missing dependencies before using Audientia"
    exit 1
fi

