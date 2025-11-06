# Audientia Project Setup

## Prerequisites

- macOS 15.0 or later
- Xcode 16.0 or later
- XcodeGen (install via `brew install xcodegen`)

## Project Structure

The project is organized into the following modules:

- **Audientia** (Main App) - SwiftUI application
- **Shared** - Shared models, utilities, and version management
- **AppKitBridge** - SwiftUI ↔ AppKit bridge components
- **AudioCore** - C++/Swift audio playback engine
- **MetadataEngine** - Tag and artwork parsing
- **DataLayer** - CoreData + SQLite backend
- **PluginSystem** - JavaScriptCore plugin runtime
- **UI** - SwiftUI views and components

## Generating the Xcode Project

The Xcode project is generated from `project.yml` using XcodeGen:

```bash
xcodegen generate
```

This creates `Audientia.xcodeproj` with all targets, dependencies, and build scripts configured.

## Opening the Project

```bash
open Audientia.xcodeproj
```

Or from Xcode:
- File → Open → Select `Audientia.xcodeproj`

## Build Scripts

The project includes automatic version management:

### App Target
- **Pre-build**: Updates app version (`Scripts/update_version.sh`)
- **Post-build**: Loads versions into app (`Scripts/load_versions.swift`)

### Module Targets
- **Pre-build**: Updates module version (`Scripts/update_version.sh [ModuleName]`)
- **Post-build**: Renames framework output with version (e.g., `AudioCore-2025.01.0001.framework`)

## Version Management

Versions are automatically managed:
- **App**: `yyyy.mm.bbbb` format (e.g., `2025.01.0001`)
- **Modules**: `ModuleName-yyyy.mm.bbbb` format (e.g., `AudioCore-2025.01.0001`)

On app launch, `ModuleVersionManager` automatically:
- Scans for all module versions
- Selects the latest version
- Deletes older versions
- Warns about conflicts

## Building

### Build All Targets
```bash
xcodebuild -project Audientia.xcodeproj -scheme Audientia -configuration Debug build
```

### Build Specific Target
```bash
xcodebuild -project Audientia.xcodeproj -target AudioCore -configuration Debug build
```

### Clean Build
```bash
xcodebuild -project Audientia.xcodeproj -scheme Audientia clean
```

## Running

```bash
xcodebuild -project Audientia.xcodeproj -scheme Audientia -configuration Debug run
```

Or use Xcode: Product → Run (⌘R)

## Dependencies

All module frameworks depend on `Shared` framework. The main app depends on all modules.

## Configuration

Edit `project.yml` to modify:
- Bundle identifiers
- Deployment targets
- Build settings
- Dependencies
- Build scripts

After changes, regenerate:
```bash
xcodegen generate
```

## Troubleshooting

### XcodeGen Not Found
```bash
brew install xcodegen
```

### Build Script Errors
- Ensure scripts are executable: `chmod +x Scripts/*.sh Scripts/*.swift`
- Check script paths are correct
- Verify version files are generated

### Sandbox Errors
If you see sandbox errors like `deny(1) file-read-data`:
- **Fixed**: Build scripts are now embedded directly in `project.yml` instead of calling external files
- This eliminates the file-read-data permission issue entirely
- Script logic is inline in each build phase, avoiding external file access
- The app has `ENABLE_APP_SANDBOX: false` but embedded scripts avoid sandbox restrictions

### Module Not Found
- Ensure all modules have at least one Swift file
- Check dependencies in `project.yml`
- Regenerate project: `xcodegen generate`

## Next Steps

1. Open the project in Xcode
2. Build and run to verify setup
3. Start implementing features per the roadmap
4. Add tests as you develop

