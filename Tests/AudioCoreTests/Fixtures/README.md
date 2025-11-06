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
│   └── [other formats]/
│       └── sample.[ext]
└── README.md
```

## Usage

### In Tests

```swift
// Use real sample files for integration tests
if let sampleFile = TestFixtures.sampleMP3() {
    let track = Track(/* ... */, filePath: sampleFile.path)
    try await engine.loadTrack(track)
}
```

### Adding New Sample Files

1. Place sample files in the appropriate format directory
2. Name them `sample.[ext]` for consistency
3. Keep files small (< 1MB) for fast test execution
4. Use royalty-free test audio

## Mock vs Real Files

- **Mocks**: Use `MockFileSystem` for unit tests (fast, no dependencies)
- **Real Files**: Use `TestFixtures` for integration tests (validates actual file handling)

