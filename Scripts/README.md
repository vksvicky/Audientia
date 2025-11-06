# Build Scripts

Scripts for automating build and version management tasks.

## Scripts

### `update_version.sh`

Automatically updates version numbers during build.

**Usage:**
```bash
# Update app version
./update_version.sh

# Update module version
./update_version.sh AudioCore

# Manually set module version
./update_version.sh AudioCore 2025.01.0042
```

**What it does:**
- Generates version from current date (yyyy.mm.bbbb format)
- Increments build number for current month
- Creates version files (`.app_version`, `.ModuleName_version`)
- Updates `Info.plist` if present

### `load_versions.swift`

Loads version information from build files and generates Swift code to update app settings.

**Usage:**
```bash
./load_versions.swift
```

**What it does:**
- Reads version files created by `update_version.sh`
- Generates `Shared/Utilities/AutoVersionUpdate.swift`
- This file is auto-generated and should not be edited manually

## Integration

### Xcode Build Phases

Add these as "Run Script" phases in Xcode:

1. **App Target - Before Compile**:
   ```bash
   "${SRCROOT}/Scripts/update_version.sh"
   ```

2. **Module Targets - Before Compile**:
   ```bash
   "${SRCROOT}/Scripts/update_version.sh ${PRODUCT_MODULE_NAME}"
   ```

3. **App Target - After Compile** (optional):
   ```bash
   "${SRCROOT}/Scripts/load_versions.swift
   ```

## Version Files

These files are generated during build and should be in `.gitignore`:
- `.app_version`
- `.ModuleName_version`
- `.build_number`
- `.build_number_ModuleName`

