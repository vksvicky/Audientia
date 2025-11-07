# MetadataEngine Framework

Tag parsing, artwork extraction, and metadata enhancement.

## Overview

MetadataEngine handles reading and writing audio file metadata (tags), extracting artwork, and enhancing metadata through external APIs.

## Structure

```
MetadataEngine/
├── Parsers/   # Tag parsers (ID3v2, Vorbis, MP4)
├── Writers/   # Tag writers
└── Artwork/   # Artwork extraction and processing
```

## Features

### Tag Parsing
- ID3v2 (MP3)
- Vorbis Comments (OGG, FLAC)
- MP4/M4A tags
- Metadata normalization

### Tag Writing
- Write tags to audio files
- Batch tag operations
- Tag validation
- Undo/redo system

### Artwork Extraction
- Extract embedded artwork
- Artwork format conversion
- Thumbnail generation
- Artwork caching

### Metadata Enhancement
- AcoustID/Chromaprint integration
- MusicBrainz API client
- Discogs API client
- Metadata merge strategies

## Dependencies

- `Shared` - Models and utilities
- External APIs: MusicBrainz, Discogs, AcoustID

## Usage

```swift
import MetadataEngine

let parser = MetadataParser()
let metadata = try await parser.parse(filePath: track.filePath)
let artwork = try await parser.extractArtwork(filePath: track.filePath)
```

## Implementation Status

🚧 **In Development** - Framework structure created, implementation pending.

See [`../../Documentation/05-roadmap-and-testing-strategy.md`](../../Documentation/05-roadmap-and-testing-strategy.md) for roadmap.

## Testing

MetadataEngine tests should cover:
- Tag parsing accuracy
- Tag writing roundtrip
- Artwork extraction
- API integration
- Error handling

See [`../../Documentation/05-roadmap-and-testing-strategy.md`](../../Documentation/05-roadmap-and-testing-strategy.md) for Right-BICEP testing guidelines.
