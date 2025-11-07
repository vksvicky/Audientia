# Test Fixtures

This directory contains sample audio files for integration testing.

**Important**: Audio fixture files in the `Audio/` directory are auto-generated and are ignored by git. To generate these files, run:

```bash
Scripts/generate_audio_test_fixtures.sh
```

See [`../../Scripts/generate_audio_test_fixtures.sh`](../../Scripts/generate_audio_test_fixtures.sh) for the generation script.

## Structure

```
Fixtures/
├── Audio/
│   ├── mp3/
│   │   ├── valid_44.1k.mp3
│   │   ├── invalid_empty.mp3
│   │   ├── invalid_header.mp3
│   │   └── ...
│   ├── flac/
│   │   ├── valid_44.1k.flac
│   │   ├── valid_48k.flac
│   │   ├── valid_88.2k.flac
│   │   ├── valid_96k.flac
│   │   ├── valid_176.4k.flac
│   │   ├── valid_192k.flac
│   │   └── ...
│   ├── aac/
│   │   ├── valid_44.1k.aac
│   │   ├── valid_48k.aac
│   │   └── ...
│   ├── wav/
│   │   ├── valid_44.1k.wav
│   │   ├── valid_48k.wav
│   │   └── ...
│   ├── m4a/
│   │   ├── valid_44.1k.m4a
│   │   ├── valid_48k.m4a
│   │   └── ...
│   ├── ogg/
│   │   ├── valid_44.1k.ogg
│   │   ├── valid_48k.ogg
│   │   └── ...
│   ├── opus/
│   │   ├── valid_8k.opus
│   │   ├── valid_16k.opus
│   │   ├── valid_24k.opus
│   │   ├── valid_32k.opus
│   │   ├── valid_44.1k.opus
│   │   ├── valid_48k.opus
│   │   └── ...
│   ├── alac/
│   │   ├── valid_44.1k.alac
│   │   ├── valid_48k.alac
│   │   └── ...
│   ├── ape/
│   │   ├── valid_44.1k.ape
│   │   ├── valid_48k.ape
│   │   └── ...
│   ├── aiff/
│   │   ├── valid_44.1k.aiff
│   │   ├── valid_48k.aiff
│   │   └── ...
│   ├── caf/
│   │   ├── valid_44.1k.caf
│   │   └── ...
│   ├── mp4/
│   │   ├── valid_44.1k.mp4
│   │   ├── valid_48k.mp4
│   │   └── ...
│   ├── wma/
│   │   ├── valid_44.1k.wma
│   │   └── ...
│   ├── webm/
│   │   ├── valid_48k.webm
│   │   └── ...
│   ├── flv/
│   │   ├── valid_44.1k.flv
│   │   └── ...
│   ├── ac3/
│   │   ├── valid_48k.ac3
│   │   └── ...
│   ├── dts/
│   │   ├── valid_48k.dts
│   │   ├── valid_96k.dts
│   │   └── ...
│   ├── dsf/
│   │   ├── valid_2.822MHz.dsf
│   │   ├── valid_5.644MHz.dsf
│   │   └── ...
│   ├── dff/
│   │   ├── valid_2.822MHz.dff
│   │   ├── valid_5.644MHz.dff
│   │   └── ...
│   └── wv/
│       ├── valid_44.1k.wv
│       ├── valid_48k.wv
│       └── ...
└── README.md
```

## Required Sample Files

### File Naming Convention

Valid files are named with their sample rate: `valid_{sample_rate}.{extension}`

Examples:
- `valid_44.1k.mp3` - MP3 file at 44.1kHz
- `valid_48k.flac` - FLAC file at 48kHz
- `valid_96k.wav` - WAV file at 96kHz
- `valid_2.822MHz.dsf` - DSF file at 2.8224MHz (DSD64)

### Supported Formats and Sample Rates

#### Lossy Formats

1. **MP3** (`.mp3`)
   - Sample Rates: 44.1kHz
   - Files: `valid_44.1k.mp3`

2. **AAC** (`.aac`, `.m4a`, `.mp4`)
   - Sample Rates: 44.1kHz, 48kHz
   - Files: `valid_44.1k.aac`, `valid_48k.aac`, etc.

3. **OGG Vorbis** (`.ogg`)
   - Sample Rates: 44.1kHz, 48kHz
   - Files: `valid_44.1k.ogg`, `valid_48k.ogg`

4. **Opus** (`.opus`)
   - Sample Rates: 8kHz, 16kHz, 24kHz, 32kHz, 44.1kHz, 48kHz
   - Files: `valid_8k.opus`, `valid_16k.opus`, etc.

5. **WMA** (`.wma`)
   - Sample Rates: 44.1kHz
   - Files: `valid_44.1k.wma`

6. **WebM** (`.webm`)
   - Sample Rates: 48kHz
   - Files: `valid_48k.webm`

7. **FLV** (`.flv`)
   - Sample Rates: 44.1kHz
   - Files: `valid_44.1k.flv`

8. **AC3** (`.ac3`)
   - Sample Rates: 48kHz
   - Files: `valid_48k.ac3`

9. **DTS** (`.dts`)
   - Sample Rates: 48kHz, 96kHz
   - Files: `valid_48k.dts`, `valid_96k.dts`

#### Lossless Formats

10. **FLAC** (`.flac`)
    - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz
    - Files: `valid_44.1k.flac`, `valid_48k.flac`, `valid_88.2k.flac`, etc.

11. **ALAC** (`.alac`)
    - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
    - Files: `valid_44.1k.alac`, `valid_48k.alac`, etc.

12. **APE** (`.ape`)
    - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
    - Files: `valid_44.1k.ape`, `valid_48k.ape`, etc.

13. **WavPack** (`.wv`)
    - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
    - Files: `valid_44.1k.wv`, `valid_48k.wv`, etc.

14. **DSD** (`.dsf`, `.dff`)
    - Sample Rates: 2.8224MHz (DSD64), 5.6448MHz (DSD128)
    - Files: `valid_2.822MHz.dsf`, `valid_5.644MHz.dsf`, etc.

#### Uncompressed Formats

15. **WAV** (`.wav`)
    - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz
    - Files: `valid_44.1k.wav`, `valid_48k.wav`, etc.

16. **AIFF** (`.aiff`)
    - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz
    - Files: `valid_44.1k.aiff`, `valid_48k.aiff`, etc.

17. **CAF** (`.caf`)
    - Sample Rates: 44.1kHz (and any other rate)
    - Files: `valid_44.1k.caf`

## File Placement

### Location in Project

Place files in: `Tests/AudioCoreTests/Fixtures/Audio/[format]/valid_{sample_rate}.{ext}`

For example:
- `Tests/AudioCoreTests/Fixtures/Audio/mp3/valid_44.1k.mp3`
- `Tests/AudioCoreTests/Fixtures/Audio/flac/valid_48k.flac`
- `Tests/AudioCoreTests/Fixtures/Audio/wav/valid_96k.wav`

### Invalid/Corrupt Files

Invalid and corrupt test files follow a similar naming pattern:
- `invalid_empty.{ext}` - Empty file
- `invalid_header.{ext}` - File with invalid header
- `invalid_truncated.{ext}` - Truncated file
- `invalid_zero_size.{ext}` - Zero-size file
- `invalid_no_audio_data.{ext}` - Header only, no audio data
- `corrupt_payload.{ext}` - Valid header, corrupted payload
- `corrupt_magic.{ext}` - Corrupted magic bytes
- `corrupt_middle.{ext}` - Byte corruption in middle of file

### Adding to Xcode Project

1. Files must be added to the `AudioCoreTests` target
2. Files must be in the "Copy Bundle Resources" build phase
3. Files should be marked as "Resources" (not compiled sources)

### File Size Guidelines

- **Recommended**: 1-2 seconds of audio (~100KB - 1MB depending on format)
- **Maximum**: Keep under 5MB for fast test execution
- **Minimum**: At least 0.1 seconds to test minimal file handling

## Usage

### In Tests

```swift
// Use default valid file (typically 44.1kHz)
if let sampleFile = TestFixtures.sampleMP3() {
    let track = Track(/* ... */, filePath: sampleFile.path)
    try await engine.loadTrack(track)
}

// Use specific sample rate
if let highResFile = TestFixtures.validFile(format: "flac", sampleRate: 96000) {
    let track = Track(/* ... */, filePath: highResFile.path)
    try await engine.loadTrack(track)
}

// Use invalid/corrupt files for error testing
if let emptyFile = TestFixtures.invalidEmptyFile(format: "mp3") {
    // Test error handling
}
```

### Runtime Generation

For FLAC files, we can generate test fixtures at runtime:

```swift
let flacFile = try TestFixtures.createTemporaryFLACSample(
    sampleRate: 44_100,
    channels: 2,
    bitsPerSample: 16,
    durationSeconds: 1.0
)
defer { TestFixtures.removeTemporaryFile(at: flacFile) }
```

## Mock vs Real Files

- **Mocks**: Use `MockFileSystem` for unit tests (fast, no dependencies)
- **Real Files**: Use `TestFixtures` for integration tests (validates actual file handling)

## Obtaining Sample Files

### Royalty-Free Sources

1. **Freesound.org** - Search for "test tone" or "sine wave"
2. **BBC Sound Effects Library** - Free test tones
3. **Generate using Audacity** - Create 1-2 second test tones
4. **Generate using FFmpeg** - Create synthetic audio files

### FFmpeg Generation Examples

```bash
# Generate MP3 test file (1 second, 44.1kHz, stereo, 128kbps)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -b:a 128k Tests/AudioCoreTests/Fixtures/Audio/mp3/sample.mp3

# Generate FLAC test file (1 second, 44.1kHz, stereo, 16-bit)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 Tests/AudioCoreTests/Fixtures/Audio/flac/sample.flac

# Generate WAV test file (1 second, 44.1kHz, stereo, 16-bit)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 Tests/AudioCoreTests/Fixtures/Audio/wav/sample.wav
```

## File Requirements

### Minimum File Size

- **Absolute minimum**: 1KB (to test minimal file handling)
- **Practical minimum**: 10KB (to ensure valid audio headers)
- **Recommended**: 100KB - 1MB (for realistic testing)

### File Validation

Files should:
- Have valid audio headers
- Be playable in standard audio players
- Contain actual audio data (not just headers)
- Be properly formatted according to their codec specification


# Sample Files Guide for Testing

## Answers to Your Questions

### a) What Sample Files Are Needed for Testing?

**Minimum Required Files:**
1. **MP3** - `sample.mp3` (1-2 seconds, 44.1kHz, stereo, 128-320kbps)
2. **FLAC** - `sample.flac` (1-2 seconds, 44.1kHz, stereo, 16-bit)
3. **AAC** - `sample.aac` (1-2 seconds, 44.1kHz, stereo)
4. **WAV** - `sample.wav` (1-2 seconds, 44.1kHz, stereo, 16-bit)
5. **M4A** - `sample.m4a` (1-2 seconds, 44.1kHz, stereo)

**Optional Files (for comprehensive testing):**
6. **OGG** - `sample.ogg`
7. **Opus** - `sample.opus`
8. **ALAC** - `sample.alac`
9. **APE** - `sample.ape`
10. **AIFF** - `sample.aiff`
11. **CAF** - `sample.caf`
12. **MP4** - `sample.mp4`

**File Specifications:**
- **Duration**: 1-2 seconds (enough for testing, keeps files small)
- **Sample Rate**: 44.1kHz (standard)
- **Channels**: Stereo (2 channels)
- **Bit Depth**: 16-bit (for lossless formats)
- **Bitrate**: 128-320kbps (for lossy formats)
- **File Size**: 100KB - 1MB (recommended), max 5MB

### b) Where to Place Sample Files?

**Directory Structure:**
```
Tests/AudioCoreTests/Fixtures/Audio/
├── mp3/
│   └── sample.mp3
├── flac/
│   └── sample.flac
├── aac/
│   └── sample.aac
├── wav/
│   └── sample.wav
├── m4a/
│   └── sample.m4a
├── ogg/
│   └── sample.ogg
├── opus/
│   └── sample.opus
├── alac/
│   └── sample.alac
├── ape/
│   └── sample.ape
├── aiff/
│   └── sample.aiff
├── caf/
│   └── sample.caf
└── mp4/
    └── sample.mp4
```

**Full Path Example:**
- `Tests/AudioCoreTests/Fixtures/Audio/mp3/sample.mp3`
- `Tests/AudioCoreTests/Fixtures/Audio/flac/sample.flac`

**Xcode Configuration:**
1. Files must be added to `AudioCoreTests` target
2. Files must be in "Copy Bundle Resources" build phase
3. Files should be marked as "Resources" (not compiled sources)

### c) Tests for Minimal File Size and Corruption Detection

**✅ Tests Implemented in `FileValidationTests.swift`:**

1. **Minimal File Size:**
   - `testMinimalFileSize()` - Tests files with 1KB (minimal valid size)
   - `testZeroSizeFileThrowsError()` - Tests zero-size files (should fail)
   - `testVeryLargeFile()` - Tests very large files (500MB)

2. **Corruption Detection:**
   - `testCorruptFileThrowsError()` - Tests corrupt files (should fail)
   - `testInvalidFileHeaderThrowsError()` - Tests files with invalid headers
   - `testTruncatedFileThrowsError()` - Tests truncated/incomplete files
   - `testNonExistentFileThrowsError()` - Tests missing files

**How Corruption is Detected:**
- Format decoders attempt to parse file headers
- Invalid magic bytes → `decoderFailed` error
- Truncated data → `decoderFailed` error
- Missing files → `trackLoadFailed` with "File not found"
- Zero-size files → Format decoder fails (no data to parse)

### d) Tests for Supported File Extensions

**✅ Tests Implemented in `FileValidationTests.swift`:**

1. **Supported Extensions:**
   - `testSupportedFileExtensions()` - Tests all supported formats:
     - AVFoundation: `mp3`, `aac`, `m4a`, `wav`, `aiff`, `caf`, `mp4`
     - FFmpeg: `flac`, `ogg`, `opus`, `alac`, `ape`

2. **Unsupported Extensions:**
   - `testUnsupportedFileExtensions()` - Tests unsupported formats:
     - `txt`, `pdf`, `jpg`, `zip`, `exe`, `bin`
     - Should throw `unsupportedFormat` error

3. **Case Sensitivity:**
   - `testCaseInsensitiveExtensions()` - Tests uppercase extensions:
     - `MP3`, `FLAC`, `WAV`, `AAC`, `M4A`
     - Should be recognized (case-insensitive)

4. **Edge Cases:**
   - `testFileWithoutExtension()` - Tests files with no extension
   - `testFileWithMultipleExtensions()` - Tests `file.tar.gz.mp3` (uses last extension)
   - `testVariousExtensionFormats()` - Tests mixed case, uppercase, lowercase

**Supported Formats Summary:**

| Format | Extension | Decoder | Status |
|--------|-----------|---------|--------|
| MP3 | `.mp3` | AVFoundation | ✅ Supported |
| FLAC | `.flac` | FFmpeg | ✅ Supported |
| AAC | `.aac` | AVFoundation | ✅ Supported |
| M4A | `.m4a` | AVFoundation | ✅ Supported |
| WAV | `.wav` | AVFoundation | ✅ Supported |
| AIFF | `.aiff` | AVFoundation | ✅ Supported |
| CAF | `.caf` | AVFoundation | ✅ Supported |
| MP4 | `.mp4` | AVFoundation | ✅ Supported |
| OGG | `.ogg` | FFmpeg | ✅ Supported |
| Opus | `.opus` | FFmpeg | ✅ Supported |
| ALAC | `.alac` | FFmpeg | ✅ Supported |
| APE | `.ape` | FFmpeg | ✅ Supported |

## Quick Start

### Option 1: Automated Script (Recommended)

Run the automated script to generate all valid, invalid, and error files:

```bash
../../Scripts/generate_audio_test_fixtures.sh
```

See [`../../Scripts/generate_audio_test_fixtures.sh`](../../Scripts/generate_audio_test_fixtures.sh) for the fixture generation script.

**Note**: Generated audio fixture files are ignored by git (see `.gitignore`). Run the script to regenerate them when needed.

This script generates:
- ✅ **Valid files**: `sample.{ext}` for each format
- ❌ **Invalid (empty)**: `invalid_empty.{ext}`
- ❌ **Invalid (header)**: `invalid_header.{ext}`
- ❌ **Truncated**: `truncated.{ext}`
- ❌ **Zero-size**: `zero_size.{ext}`

### Option 2: Manual Generation

#### Generate Valid Sample Files

```bash
# Create fixtures directory structure
mkdir -p Tests/AudioCoreTests/Fixtures/Audio/{mp3,flac,aac,wav,m4a,ogg,opus,alac,ape,aiff,caf,mp4}

# MP3 (1 second, 44.1kHz, stereo, 128kbps)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -b:a 128k -y Tests/AudioCoreTests/Fixtures/Audio/mp3/sample.mp3

# FLAC (1 second, 44.1kHz, stereo, 16-bit)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y Tests/AudioCoreTests/Fixtures/Audio/flac/sample.flac

# WAV (1 second, 44.1kHz, stereo, 16-bit)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y Tests/AudioCoreTests/Fixtures/Audio/wav/sample.wav

# AAC (1 second, 44.1kHz, stereo, 128kbps)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a aac -b:a 128k -y Tests/AudioCoreTests/Fixtures/Audio/aac/sample.aac

# M4A (1 second, 44.1kHz, stereo, 128kbps)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a aac -b:a 128k -y Tests/AudioCoreTests/Fixtures/Audio/m4a/sample.m4a

# MP4 (1 second, 44.1kHz, stereo, 128kbps)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a aac -b:a 128k -y Tests/AudioCoreTests/Fixtures/Audio/mp4/sample.mp4

# OGG (1 second, 44.1kHz, stereo)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a libvorbis -y Tests/AudioCoreTests/Fixtures/Audio/ogg/sample.ogg

# Opus (1 second, 44.1kHz, stereo)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a libopus -y Tests/AudioCoreTests/Fixtures/Audio/opus/sample.opus

# ALAC (1 second, 44.1kHz, stereo)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a alac -y Tests/AudioCoreTests/Fixtures/Audio/alac/sample.alac

# AIFF (1 second, 44.1kHz, stereo, 16-bit)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y Tests/AudioCoreTests/Fixtures/Audio/aiff/sample.aiff

# CAF (1 second, 44.1kHz, stereo, 16-bit)
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y Tests/AudioCoreTests/Fixtures/Audio/caf/sample.caf

# APE (1 second, 44.1kHz, stereo) - requires monkey's audio codec
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a ape -y Tests/AudioCoreTests/Fixtures/Audio/ape/sample.ape
```

#### Generate Invalid/Error Sample Files

For each format, generate invalid files to test error handling:

```bash
# For each format (replace {format} and {ext} with actual values)
FORMAT_DIR="Tests/AudioCoreTests/Fixtures/Audio/{format}"

# 1. Empty file (zero bytes)
touch "${FORMAT_DIR}/invalid_empty.{ext}"

# 2. Wrong header (garbage data)
echo "INVALID_HEADER_DATA_12345" > "${FORMAT_DIR}/invalid_header.{ext}"

# 3. Truncated file (first 100 bytes of valid file)
head -c 100 "${FORMAT_DIR}/sample.{ext}" > "${FORMAT_DIR}/truncated.{ext}"

# 4. Zero-size file (explicitly empty)
: > "${FORMAT_DIR}/zero_size.{ext}"
```

**Example for MP3:**
```bash
# Empty MP3
touch Tests/AudioCoreTests/Fixtures/Audio/mp3/invalid_empty.mp3

# Wrong header MP3
echo "INVALID_HEADER_DATA_12345" > Tests/AudioCoreTests/Fixtures/Audio/mp3/invalid_header.mp3

# Truncated MP3 (first 100 bytes)
head -c 100 Tests/AudioCoreTests/Fixtures/Audio/mp3/sample.mp3 > Tests/AudioCoreTests/Fixtures/Audio/mp3/truncated.mp3

# Zero-size MP3
: > Tests/AudioCoreTests/Fixtures/Audio/mp3/zero_size.mp3
```

**Example for FLAC:**
```bash
# Empty FLAC
touch Tests/AudioCoreTests/Fixtures/Audio/flac/invalid_empty.flac

# Wrong header FLAC
echo "INVALID_HEADER_DATA_12345" > Tests/AudioCoreTests/Fixtures/Audio/flac/invalid_header.flac

# Truncated FLAC (first 100 bytes)
head -c 100 Tests/AudioCoreTests/Fixtures/Audio/flac/sample.flac > Tests/AudioCoreTests/Fixtures/Audio/flac/truncated.flac

# Zero-size FLAC
: > Tests/AudioCoreTests/Fixtures/Audio/flac/zero_size.flac
```

**Repeat for all formats:** `aac`, `wav`, `m4a`, `ogg`, `opus`, `alac`, `ape`, `aiff`, `caf`, `mp4`

### Using Test Fixtures in Tests

```swift
// Real file integration test
if let sampleFile = TestFixtures.sampleMP3() {
    let track = Track(/* ... */, filePath: sampleFile.path)
    try await engine.loadTrack(track)
}

// Runtime-generated FLAC (for testing)
let flacFile = try TestFixtures.createTemporaryFLACSample(
    sampleRate: 44_100,
    channels: 2,
    bitsPerSample: 16,
    durationSeconds: 1.0
)
defer { TestFixtures.removeTemporaryFile(at: flacFile) }
```

## Test Coverage

All file validation tests are in `FileValidationTests.swift`:
- ✅ File extension validation (supported/unsupported)
- ✅ Case-insensitive extension handling
- ✅ File size validation (zero, minimal, large)
- ✅ Corruption detection (corrupt, invalid header, truncated)
- ✅ Missing file detection
- ✅ Edge cases (no extension, multiple extensions)