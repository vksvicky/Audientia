# Scripts Directory

This directory contains build and utility scripts for the Audientia project.

## Scripts

### `update_version.sh`
Updates version numbers for the app and modules during the build process.

### `load_versions.swift`
Swift script for loading version information (currently disabled in build phases).

### `add_resources.rb`
Ruby script to add Resources group and Assets.xcassets to the Xcode project.

### `sync_project_structure.rb`
Ruby script to sync Xcode project structure with the file system. This ensures that:
- All fileGroups (Resources, Documentation, Scripts, Configuration) are present in Xcode
- All files match the actual file system structure
- The project navigator structure matches the folder structure

**Usage:**
```bash
ruby Scripts/sync_project_structure.rb
```

### `post_generate.sh`
Post-generation script that runs after `xcodegen generate` to sync the project structure.

**Usage:**
```bash
xcodegen generate && Scripts/post_generate.sh
```

### `generate_audio_test_fixtures.sh`
Generates audio test fixture files for all supported formats (19 formats with multiple sample rates).

**What it generates:**
- Valid audio files: `valid_{sample_rate}.{ext}` (e.g., `valid_44.1k.mp3`, `valid_96k.flac`)
- Invalid files: `invalid_empty.{ext}`, `invalid_header.{ext}`, `invalid_truncated.{ext}`, etc.
- Corrupt files: `corrupt_payload.{ext}`, `corrupt_magic.{ext}`, `corrupt_middle.{ext}`

**Usage:**
```bash
Scripts/generate_audio_test_fixtures.sh
```

**Note**: Generated audio fixture files are ignored by git (see `.gitignore`). Run this script to regenerate fixtures when needed. Requires `ffmpeg` to be installed.

See [`../Tests/AudioCoreTests/Fixtures/README.md`](../Tests/AudioCoreTests/Fixtures/README.md) for detailed format specifications.

## Workflow

When regenerating the Xcode project:

1. **Generate project:**
   ```bash
   cd /Users/vivek/Development/audientia
   xcodegen generate
   ```

2. **Sync structure (ensures fileGroups appear in Xcode):**
   ```bash
   Scripts/post_generate.sh
   ```

   Or manually:
   ```bash
   ruby Scripts/sync_project_structure.rb
   ```

**Note:** The `sync_project_structure.rb` script ensures that the Xcode project navigator structure matches the actual file system structure, including all fileGroups (Resources, Documentation, Scripts, Configuration) and their files.

## Project Structure

The project follows a structured folder layout that matches the Xcode navigator:

```
Audientia/
├── Sources/          # All source code
├── Tests/            # All test code
├── Resources/        # Assets and resources
├── Documentation/    # Project documentation
├── Scripts/          # Build and utility scripts
└── Configuration/    # Project configuration
```

This structure ensures that the file system matches what you see in Xcode, making navigation and development more intuitive.
