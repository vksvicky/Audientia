#!/bin/bash

# update_version.sh
# Script to automatically update version numbers during build
#
# Usage:
#   ./update_version.sh [module_name] [version]
#   If no arguments provided, updates app version
#   If module_name provided, updates that module's version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get current date components
YEAR=$(date +%Y)
MONTH=$(date +%m)

# Build number storage
BUILD_NUM_FILE="$PROJECT_ROOT/.build_number"
MODULE_BUILD_NUM_FILE="$PROJECT_ROOT/.build_number_$1"

# Function to get next build number
get_next_build_number() {
    local build_file=$1
    local current_build=0

    if [ -f "$build_file" ]; then
        # Read current build and check if it's for current month
        local stored_date=$(head -n 1 "$build_file" 2>/dev/null || echo "")
        local stored_build=$(tail -n 1 "$build_file" 2>/dev/null || echo "0")

        if [ "$stored_date" = "$YEAR.$MONTH" ]; then
            current_build=$stored_build
        fi
    fi

    # Increment build number
    local next_build=$((current_build + 1))

    # Save new build number
    echo "$YEAR.$MONTH" > "$build_file"
    echo "$next_build" >> "$build_file"

    echo "$next_build"
}

# Generate version string
generate_version() {
    local build_num=$(get_next_build_number "$1")
    printf "%04d.%02d.%04d" "$YEAR" "$MONTH" "$build_num"
}

# Update app version
update_app_version() {
    local version=$(generate_version "$BUILD_NUM_FILE")
    echo "Updating app version to: $version"

    # Update in UserDefaults (via a Swift script or plist)
    # For now, we'll create a version file that the app can read
    echo "$version" > "$PROJECT_ROOT/.app_version"

    # Also update Info.plist if it exists
    if [ -f "$PROJECT_ROOT/Info.plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$PROJECT_ROOT/Info.plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $version" "$PROJECT_ROOT/Info.plist" 2>/dev/null || true
    fi
}

# Update module version
update_module_version() {
    local module_name=$1
    local version=$(generate_version "$MODULE_BUILD_NUM_FILE")
    local full_version="${module_name}-${version}"

    echo "Updating $module_name version to: $full_version"

    # Create version file for module (will be used to name the built module)
    echo "$version" > "$PROJECT_ROOT/.${module_name}_version"
    echo "$full_version" > "$PROJECT_ROOT/.${module_name}_full_version"

    # Note: The actual module file should be named with version, e.g.:
    # AudioCore-2025.01.0001.framework
    # This allows ModuleVersionManager to detect and manage multiple versions
}

# Main execution
if [ $# -eq 0 ]; then
    # No arguments: update app version
    update_app_version
elif [ $# -eq 1 ]; then
    # One argument: module name
    update_module_version "$1"
else
    # Two arguments: module name and version (manual override)
    local module_name=$1
    local version=$2
    echo "$version" > "$PROJECT_ROOT/.${module_name}_version"
    echo "${module_name}-${version}" > "$PROJECT_ROOT/.${module_name}_full_version"
    echo "Set $module_name version to: ${module_name}-${version}"
fi

echo "Version update complete"

