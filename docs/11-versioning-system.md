# Versioning System

## Overview

Audientia uses a consistent versioning scheme for both the application and all modules. Versions are automatically updated during the build process. The system automatically detects multiple versions of modules, selects the latest, and cleans up older versions.

## Version Format

### App Version
Format: `yyyy.mm.bbbb` (year.month.build)

Examples:
- `2025.01.0001` - First build in January 2025
- `2025.01.0023` - 23rd build in January 2025
- `2025.02.0001` - First build in February 2025 (build resets each month)

### Module Version
Format: `ModuleName-yyyy.mm.bbbb`

Module files should be named with version: `ModuleName-Version.framework`

Examples:
- `AudioCore-2025.01.0001.framework`
- `MetadataEngine-2025.01.0015.framework`
- `UI-2025.02.0003.framework`

## Version Components

- **Year (yyyy)**: 4-digit year (e.g., 2025)
- **Month (mm)**: 2-digit month (01-12)
- **Build (bbbb)**: 4-digit build number, increments for each build in that month

## Multiple Module Versions

The system automatically handles multiple versions of the same module:

1. **Detection**: When scanning module directories, all versions are detected
2. **Selection**: The latest version (highest version number) is automatically selected
3. **Warning**: User is notified about conflicts via `ModuleConflictWarning`
4. **Cleanup**: Older version files are automatically deleted
5. **Registration**: Only the latest version is kept in the registry

### Conflict Resolution

When multiple versions are detected:

```
⚠️ WARNING: Multiple versions of AudioCore detected:
   Latest: 2025.01.0023 at /path/to/AudioCore-2025.01.0023.framework
   Older: 2025.01.0015 at /path/to/AudioCore-2025.01.0015.framework
   Removing older versions and keeping: 2025.01.0023
   ✓ Deleted: /path/to/AudioCore-2025.01.0015.framework
```

## Automatic Version Updates

### During Build

1. **App Build**: When building the app, `Scripts/update_version.sh` is called
   - Generates version from current date
   - Increments build number for current month
   - Updates `.app_version` file
   - Updates `Info.plist` if present

2. **Module Build**: When building a module, `Scripts/update_version.sh [ModuleName]` is called
   - Generates version for that specific module
   - Increments module-specific build number
   - Updates `.ModuleName_version` file
   - **Important**: Module output should be named `ModuleName-Version.framework`

### At Runtime

On app launch:

1. `AutoVersionUpdate.swift` updates app version from build files
2. `scanAndRegisterModules()` scans module directories
3. `ModuleVersionManager` detects all module versions
4. Automatically resolves conflicts and cleans up old versions
5. Stores active (latest) versions in `AppSettings`

## Version Storage

### Build Artifacts
- `.app_version` - Current app version
- `.ModuleName_version` - Version for each module (used during build)
- `.build_number` - App build counter (year.month + build)
- `.build_number_ModuleName` - Module build counter

### App Settings
Versions are stored in `UserDefaults`:
- `AppVersion` - App version string
- `ModuleVersions` - JSON array of all module info (including file paths)

### Active Versions
Only the latest version of each module is considered "active" and used by the app.

## Usage

### Getting Versions in Code

```swift
// Get app version
let appVersion = VersionManager.shared.appVersion
print("App version: \(appVersion)") // "2025.01.0001"

// Get active (latest) module version
if let audioCoreVersion = ModuleVersionManager.shared.getActiveVersion(for: "AudioCore") {
    print("AudioCore version: \(audioCoreVersion)") // "2025.01.0001"
}

// Get all versions of a module (if multiple exist before cleanup)
let allVersions = ModuleVersionManager.shared.getAllVersions(for: "AudioCore")
// Returns array sorted by version (latest first)

// Get all active module versions
let activeVersions = ModuleVersionManager.shared.getAllActiveVersions()
// ["AudioCore": Version(2025, 1, 23), "MetadataEngine": Version(2025, 1, 15), ...]
```

### Using AppSettings

```swift
let settings = AppSettings.shared

// Get app version
print("App: \(settings.appVersion)")

// Get active module version string
let audioCoreVersion = settings.versionString(for: "AudioCore")

// Get full version string with module name
let fullVersion = settings.fullVersionString(for: "AudioCore")
// "AudioCore-2025.01.0001"

// Get all versions as display string
print(settings.allVersionsDisplayString)

// Check for conflict warnings
for (moduleName, warning) in settings.moduleConflictWarnings {
    print("⚠️ \(warning.message)")
}
```

### Registering Modules

```swift
// Manually register a module
let moduleInfo = ModuleInfo(
    moduleName: "AudioCore",
    version: Version(year: 2025, month: 1, build: 23),
    filePath: "/path/to/AudioCore-2025.01.0023.framework"
)
try ModuleVersionManager.shared.registerModule(moduleInfo)
// This will automatically detect conflicts and clean up old versions
```

### Scanning for Modules

```swift
// Automatically scan directory and register all modules
try ModuleVersionManager.shared.scanAndRegisterModules(in: "/path/to/modules")
// Automatically detects versions from filenames
// Resolves conflicts and cleans up old versions
```

## Build Integration

### Xcode Build Phases

Add to your Xcode project's build phases:

1. **App Target - Pre-build Script**:
```bash
"${SRCROOT}/Scripts/update_version.sh"
```

2. **Module Targets - Pre-build Script**:
```bash
"${SRCROOT}/Scripts/update_version.sh ${PRODUCT_MODULE_NAME}"
```

3. **Module Targets - Post-build Script** (rename output):
```bash
# Rename framework to include version
VERSION=$(cat "${SRCROOT}/.${PRODUCT_MODULE_NAME}_version")
mv "${BUILT_PRODUCTS_DIR}/${PRODUCT_MODULE_NAME}.framework" \
   "${BUILT_PRODUCTS_DIR}/${PRODUCT_MODULE_NAME}-${VERSION}.framework"
```

### Module Naming Convention

For the system to work correctly, built modules must be named with version:

- ✅ `AudioCore-2025.01.0001.framework`
- ✅ `MetadataEngine-2025.01.0015.bundle`
- ❌ `AudioCore.framework` (no version - will use current date)

## Conflict Resolution Details

### What Gets Deleted

When older versions are detected, the following are deleted:
- The main module file (`.framework`, `.bundle`, `.dylib`)
- Associated `.dSYM` files
- Framework headers (if applicable)

### What Gets Kept

- The latest version (highest version number)
- All associated files for the latest version

### User Notification

Conflicts are reported via:
- Console logs (during development)
- `ModuleConflictWarning` notifications
- `AppSettings.moduleConflictWarnings` dictionary (for UI display)

## Version Display

Versions can be displayed in:
- About dialog
- Settings/Preferences window
- Debug menu
- Crash reports
- Log files

## Module List

All tracked modules:
- `AppKitBridge`
- `AudioCore`
- `MetadataEngine`
- `DataLayer`
- `UI`
- `PluginSystem`
- `Shared`

## Testing

For testing purposes, you can manually set versions:

```swift
let testVersion = Version(year: 2025, month: 1, build: 9999)
VersionManager.shared.setAppVersion(testVersion)
```

To test conflict resolution, place multiple versions of a module in the scan directory.
