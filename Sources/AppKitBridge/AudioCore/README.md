# AudioCore Framework

C++/Swift audio playback engine with format support and DSP capabilities.

## Overview

AudioCore provides the audio playback engine for Audientia, handling audio decoding, playback, and processing. It uses a hybrid C++/Swift approach for performance and native integration.

## Structure

```
AudioCore/
├── Engine/      # Core playback engine (C++)
├── Bridge/      # Swift ↔ C++ bridge
├── Decoder/     # Format decoders (FFmpeg wrapper)
└── DSP/         # Audio processing (EQ, ReplayGain, etc.)
```

## Features

### Playback Engine
- Play, pause, stop, seek
- Queue management
- Position tracking
- Volume control and mute

### Format Support
- MP3, FLAC, AAC, OGG, WAV, and more
- FFmpeg integration for broad format support
- Automatic format detection

### Audio Processing
- 10-band parametric equalizer
- ReplayGain analysis and application
- Crossfade between tracks
- Audio visualizer feed (FFT data)

## Dependencies

- `Shared` - Common models and utilities
- FFmpeg (external library)

## Architecture

### C++ Engine
Core audio processing in C++ for performance:
- Low-latency audio I/O
- Real-time DSP processing
- Efficient memory management

### Swift Bridge
Swift interface for C++ engine:
- Swift-friendly API
- Swift Concurrency integration
- Error handling

## Usage

```swift
import AudioCore

let audioEngine = AudioEngine()
try await audioEngine.loadTrack(track)
try await audioEngine.play()
```

## Implementation Status

🚧 **In Development** - Framework structure created, implementation pending.

See [`../../../Documentation/05-roadmap-and-testing-strategy.md`](../../../Documentation/05-roadmap-and-testing-strategy.md) for roadmap.

## Testing

Audio engine tests should cover:
- Playback state machine
- Format detection accuracy
- Seek accuracy
- Performance characteristics

See [`../../../Documentation/05-roadmap-and-testing-strategy.md`](../../../Documentation/05-roadmap-and-testing-strategy.md) for Right-BICEP testing guidelines.
