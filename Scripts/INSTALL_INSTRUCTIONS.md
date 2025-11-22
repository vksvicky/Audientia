# Audientia Installation Instructions

## Before Installing

**Important**: Audientia requires certain external libraries to function properly. Please check if they are installed before using the app.

### Quick Dependency Check

Run the dependency checker:

```bash
./check_dependencies.sh --notify
```

Or open Terminal and run:

```bash
cd /path/to/Audientia
./check_dependencies.sh
```

### Required Dependencies

#### 1. FFmpeg (Required)
- **Minimum Version**: 6.0
- **Recommended Version**: 8.0+
- **Installation**: 
  ```bash
  brew install ffmpeg
  ```
- **Purpose**: Audio transcoding and extended format support

#### 2. chromaprint (Optional but Recommended)
- **Installation**: 
  ```bash
  brew install chromaprint
  ```
- **Purpose**: Acoustic fingerprinting for track identification
- **Note**: The app will work without this, but fingerprinting features will be unavailable

### Installation Steps

1. **Check Dependencies** (if not already installed):
   ```bash
   ./check_dependencies.sh --notify
   ```

2. **Install Missing Dependencies**:
   ```bash
   brew install ffmpeg
   brew install chromaprint  # Optional, for fingerprinting
   ```

3. **Install Audientia**:
   - Drag `Audientia.app` to your Applications folder
   - Or double-click the app to run it from the DMG

4. **First Launch**:
   - The app will verify dependencies on first launch
   - If dependencies are missing, you'll see a notification with installation instructions

### Verifying Installation

After installing dependencies, verify they're available:

```bash
# Check FFmpeg
ffmpeg -version

# Check chromaprint
fpcalc -version
```

### Troubleshooting

#### FFmpeg Not Found
- Ensure Homebrew is installed: `brew --version`
- Install FFmpeg: `brew install ffmpeg`
- Verify installation: `which ffmpeg`
- The app looks for FFmpeg in:
  - `/usr/local/bin/ffmpeg` (Intel Macs)
  - `/opt/homebrew/bin/ffmpeg` (Apple Silicon Macs)
  - `/usr/bin/ffmpeg`
  - Your PATH

#### chromaprint Not Found
- Install chromaprint: `brew install chromaprint`
- Verify installation: `which fpcalc`
- Note: This is optional - the app will work without it, but fingerprinting features will be unavailable

#### Homebrew Not Installed
Install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### System Requirements

- macOS 15.0 or later
- Apple Silicon (M1/M2/M3+) or Intel Mac
- Sufficient disk space for your music library

### Getting Help

If you encounter issues:
1. Run the dependency checker: `./check_dependencies.sh`
2. Check the [troubleshooting section](#troubleshooting) above
3. Contact support: support@cycleruncode.club

