# Test Fixtures

This directory contains sample audio files for integration testing.

## Structure

```
Fixtures/
├── Audio/
│   ├── mp3/
│   │   └── sample.mp3
│   ├── flac/
│   │   └── sample.flac
│   ├── aac/
│   │   └── sample.aac
│   ├── wav/
│   │   └── sample.wav
│   ├── m4a/
│   │   └── sample.m4a
│   ├── ogg/
│   │   └── sample.ogg
│   ├── opus/
│   │   └── sample.opus
│   ├── alac/
│   │   └── sample.alac
│   ├── ape/
│   │   └── sample.ape
│   ├── aiff/
│   │   └── sample.aiff
│   ├── caf/
│   │   └── sample.caf
│   └── mp4/
│       └── sample.mp4
└── README.md
```

## Required Sample Files

### Minimum Required Files for Testing

You need at least one sample file for each supported format:

1. **MP3** (`sample.mp3`) - ~1-2 seconds, 44.1kHz, stereo, 128-320kbps
2. **FLAC** (`sample.flac`) - ~1-2 seconds, 44.1kHz, stereo, 16-bit
3. **AAC** (`sample.aac`) - ~1-2 seconds, 44.1kHz, stereo
4. **WAV** (`sample.wav`) - ~1-2 seconds, 44.1kHz, stereo, 16-bit
5. **M4A** (`sample.m4a`) - ~1-2 seconds, 44.1kHz, stereo

### Optional Files (for comprehensive testing)

6. **OGG** (`sample.ogg`) - ~1-2 seconds, 44.1kHz, stereo
7. **Opus** (`sample.opus`) - ~1-2 seconds, 44.1kHz, stereo
8. **ALAC** (`sample.alac`) - ~1-2 seconds, 44.1kHz, stereo, 16-bit
9. **APE** (`sample.ape`) - ~1-2 seconds, 44.1kHz, stereo
10. **AIFF** (`sample.aiff`) - ~1-2 seconds, 44.1kHz, stereo, 16-bit
11. **CAF** (`sample.caf`) - ~1-2 seconds, 44.1kHz, stereo
12. **MP4** (`sample.mp4`) - ~1-2 seconds, 44.1kHz, stereo

## File Placement

### Location in Project

Place files in: `Tests/AudioCoreTests/Fixtures/Audio/[format]/sample.[ext]`

For example:
- `Tests/AudioCoreTests/Fixtures/Audio/mp3/sample.mp3`
- `Tests/AudioCoreTests/Fixtures/Audio/flac/sample.flac`

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
// Use real sample files for integration tests
if let sampleFile = TestFixtures.sampleMP3() {
    let track = Track(/* ... */, filePath: sampleFile.path)
    try await engine.loadTrack(track)
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
./Scripts/generate_test_fixtures.sh
```

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