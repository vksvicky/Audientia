# Configuration Directory

Project configuration files and setup documentation.

## Files

### `project.yml`
XcodeGen configuration file that defines:
- Project structure and targets
- Build settings and dependencies
- Build scripts and phases
- File groups and resources

**Usage:**
```bash
xcodegen generate
```

### `Info.plist`
Application information property list:
- Bundle identifier: `club.cycleruncode.audientia`
- Version and build number
- App capabilities and permissions
- Minimum macOS version: 15.0

### `SETUP.md`
Detailed setup instructions:
- Prerequisites
- Project generation
- Build configuration
- Development workflow

### `PROJECT_STATUS.md`
Current project status:
- Completed features
- In-progress work
- Pending tasks
- Known issues

## Project Configuration

### Bundle Identifier
`club.cycleruncode.audientia`

### Company Information
- **Company**: CycleRunCode Club
- **Package**: club.cycleruncode
- **Copyright**: © 2025 CycleRunCode Club. All rights reserved.
- **Support**: support@cycleruncode.club

### Versioning
- **App Version**: `yyyy.mm.bbbb` (e.g., `2025.11.0001`)
- **Module Versions**: `ModuleName-yyyy.mm.bbbb`
- Automatically managed during build

## Build Settings

Key build settings are configured in `project.yml`:
- Code signing disabled (non-App Store app)
- Dead code stripping enabled
- Module verifier enabled
- Asset catalog symbol extensions enabled
- String catalog code generation enabled

## Modifying Configuration

### Adding a New Target
Edit `project.yml` and add a new target definition:
```yaml
targets:
  NewTarget:
    type: framework
    platform: macOS
    # ... configuration
```

### Changing Build Settings
Edit the `settings` section in `project.yml` for the target.

### Regenerating Project
After any changes to `project.yml`:
```bash
xcodegen generate
Scripts/post_generate.sh
```

## See Also

- `../Scripts/README.md` - Build scripts documentation
- `../Documentation/11-versioning-system.md` - Version management details
- `../SETUP.md` - Setup instructions

