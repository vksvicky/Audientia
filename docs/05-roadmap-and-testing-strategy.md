# Roadmap and Testing Strategy

## Development Phases

### Phase 0: Foundation & Infrastructure (Weeks 1-4)

#### Backend Components
- **AudioCore Foundation**
  - C++ audio engine skeleton with AVFoundation bridge
  - Basic playback engine (play/pause/seek)
  - Format detection and routing
  - **Tests**: Unit tests for playback state machine, format detection accuracy

- **DataLayer Foundation**
  - CoreData model design (Track, Album, Artist, Playlist entities)
  - SQLite schema for metadata cache
  - Migration system
  - **Tests**: CoreData stack initialization, migration tests, data integrity

- **Shared Models**
  - Swift models for Track, Album, Artist, Playlist
  - Codable conformance for persistence
  - **Tests**: Model serialization/deserialization, equality checks

#### Testing Infrastructure
- XCTest framework setup
- Mock factories for audio engine, data layer
- Test fixtures (sample audio files, metadata)
- CI/CD pipeline (GitHub Actions for macOS)

**Right-BICEP Coverage:**
- **[Right]**: Verify playback state transitions, data persistence
- **[B]**: Test with empty library, single track, 100k+ tracks
- **[I]**: Add track then remove, verify library state unchanged
- **[C]**: Compare CoreData queries with direct SQLite queries
- **[E]**: Corrupt database, missing audio files, invalid formats
- **[P]**: Library scan < 1s per 1000 tracks, playback latency < 50ms
- **Edge**: Unicode filenames, very long paths, missing permissions

---

### Phase 1: Core Playback & Library (Weeks 5-12)

#### 1.1 Audio Playback Engine (Weeks 5-8)

**Backend (AudioCore):**
- C++ playback engine with CoreAudio integration
- Format decoder abstraction (FFmpeg wrapper)
- Playback queue management
- Seek and position tracking
- Volume control and mute

**UI (SwiftUI):**
- Now Playing view with basic controls
- Progress slider with scrubbing
- Volume control
- Playback state indicators

**Tests:**
- **TDD**: Write tests for each playback operation first
- **Unit**: Playback state machine, queue management, seek accuracy
- **Integration**: End-to-end playback with real audio files
- **BDD**: "As a user, I want to play a track and see progress update"

**Right-BICEP:**
- **[Right]**: Verify audio output matches expected format/sample rate
- **[B]**: Test with 1s clips, 3-hour files, various bitrates
- **[I]**: Play → Pause → Play, verify position maintained
- **[C]**: Compare AVFoundation duration with tag metadata
- **[E]**: Corrupt file, network interruption, device unplugged
- **[P]**: Start playback < 100ms, seek accuracy ±10ms
- **Edge**: VBR files, gapless playback, sample rate changes

#### 1.2 Library Management (Weeks 9-12)

**Backend (DataLayer):**
- Library scanner (FileManager integration)
- Metadata extraction (delegate to MetadataEngine)
- Indexing and search
- Library statistics

**Backend (MetadataEngine):**
- Tag parser (ID3v2, Vorbis, MP4)
- Artwork extraction
- Metadata normalization

**UI:**
- Library browser (list/grid views)
- Search interface
- Library statistics view
- Import/scan progress

**Tests:**
- **TDD**: Scanner, indexer, search algorithms
- **Unit**: Tag parsing accuracy, search relevance
- **Integration**: Full library scan with various file types
- **BDD**: "As a user, I want to scan my music folder and see all tracks"

**Right-BICEP:**
- **[Right]**: Verify all tracks found, metadata accurate
- **[B]**: Empty folder, 100k+ files, nested 20 levels deep
- **[I]**: Scan → Remove file → Rescan, verify removed
- **[C]**: Compare tag values with external tag editor
- **[E]**: Permission denied, disk full, interrupted scan
- **[P]**: Scan 10k tracks < 5 minutes, search < 100ms
- **Edge**: Symlinks, aliases, network drives, read-only files

---

### Phase 2: Advanced Playback & Organization (Weeks 13-20)

#### 2.1 DSP & Audio Processing (Weeks 13-16)

**Backend (AudioCore):**
- Equalizer (10-band parametric)
- ReplayGain analysis and application
- Crossfade between tracks
- Audio visualizer feed (FFT data)

**UI:**
- EQ interface with presets
- Visualizer view (Metal rendering)
- ReplayGain settings

**Tests:**
- **TDD**: DSP algorithms, ReplayGain calculation
- **Unit**: EQ frequency response, gain accuracy
- **Integration**: Playback with EQ, verify audio output
- **BDD**: "As a user, I want to adjust bass and hear the change"

**Right-BICEP:**
- **[Right]**: Verify EQ frequency response matches settings
- **[B]**: Extreme EQ settings, silence, very loud audio
- **[I]**: Apply EQ → Reset → Verify original audio
- **[C]**: Compare ReplayGain with external tools (foobar2000)
- **[E]**: Invalid EQ settings, NaN values, buffer underrun
- **[P]**: EQ processing < 5% CPU, visualizer 60fps
- **Edge**: Very high sample rates, mono/stereo/multichannel

#### 2.2 Playlists & Organization (Weeks 17-20)

**Backend (DataLayer):**
- Playlist CRUD operations
- Smart playlist rule engine
- Playlist statistics

**UI:**
- Playlist browser
- Playlist editor
- Smart playlist rule builder
- Drag-and-drop reordering

**Tests:**
- **TDD**: Rule engine, playlist operations
- **Unit**: Rule evaluation, playlist sorting
- **Integration**: Create smart playlist, verify matches
- **BDD**: "As a user, I want to create a playlist of 5-star songs from 2020"

**Right-BICEP:**
- **[Right]**: Verify playlist matches rule criteria
- **[B]**: Empty playlist, 10k tracks, complex nested rules
- **[I]**: Add track → Remove → Verify not in playlist
- **[C]**: Compare rule results with manual filtering
- **[E]**: Invalid rules, circular references, missing fields
- **[P]**: Rule evaluation < 50ms, playlist load < 200ms
- **Edge**: Unicode in rules, date edge cases, null values

---

### Phase 3: Tagging & Metadata (Weeks 21-28)

#### 3.1 Tag Editor (Weeks 21-24)

**Backend (MetadataEngine):**
- Tag writing (ID3v2, Vorbis, MP4)
- Batch tag operations
- Tag validation
- Undo/redo system

**UI:**
- Tag editor view
- Batch tag operations UI
- Tag validation warnings
- Undo/redo controls

**Tests:**
- **TDD**: Tag writers, validation logic
- **Unit**: Tag write/read roundtrip, validation rules
- **Integration**: Edit tags, verify file updated correctly
- **BDD**: "As a user, I want to edit a track's artist and see it saved"

**Right-BICEP:**
- **[Right]**: Verify tags written correctly, readable by other apps
- **[B]**: Very long tags, empty tags, special characters
- **[I]**: Write tag → Read → Verify match
- **[C]**: Compare with external tag editors (TagEditor, Kid3)
- **[E]**: Read-only files, disk full, corrupt tags
- **[P]**: Tag write < 100ms, batch 100 tracks < 10s
- **Edge**: Multiple tag formats, encoding issues, embedded artwork

#### 3.2 Metadata Enhancement (Weeks 25-28)

**Backend:**
- AcoustID/Chromaprint integration
- MusicBrainz API client
- Discogs API client
- Metadata merge strategies

**UI:**
- Metadata lookup interface
- Merge conflict resolution
- Auto-tagging progress

**Tests:**
- **TDD**: API clients, merge logic
- **Unit**: API response parsing, merge algorithms
- **Integration**: Lookup track, verify metadata enriched
- **BDD**: "As a user, I want to auto-tag an album using MusicBrainz"

**Right-BICEP:**
- **[Right]**: Verify fetched metadata accurate and complete
- **[B]**: Unknown tracks, multiple matches, partial data
- **[I]**: Fetch → Apply → Revert → Verify original
- **[C]**: Compare with manual MusicBrainz lookup
- **[E]**: Network failure, API rate limits, invalid responses
- **[P]**: Lookup < 2s, batch lookup with rate limiting
- **Edge**: Ambiguous matches, conflicting sources, missing artwork

---

### Phase 4: Device Sync & Transcoding (Weeks 29-36)

#### 4.1 Device Discovery & Sync (Weeks 29-32)

**Backend:**
- USB device detection (IOKit)
- MTP protocol implementation
- SMB network share access
- Sync job queue
- Conflict detection

**UI:**
- Device browser
- Sync configuration
- Sync progress and logs
- Conflict resolution UI

**Tests:**
- **TDD**: Device detection, sync algorithms
- **Unit**: Sync diff calculation, conflict detection
- **Integration**: Full sync with test device
- **BDD**: "As a user, I want to sync my library to a USB device"

**Right-BICEP:**
- **[Right]**: Verify all tracks synced, metadata preserved
- **[B]**: Empty device, full device, very large library
- **[I]**: Sync → Unsync → Verify device unchanged
- **[C]**: Compare file checksums before/after sync
- **[E]**: Device disconnected, insufficient space, permission denied
- **[P]**: Sync 1000 tracks < 10 minutes, progress updates < 1s
- **Edge**: FAT32 4GB limit, long filenames, special characters

#### 4.2 Transcoding Pipeline (Weeks 33-36)

**Backend:**
- FFmpeg wrapper for transcoding
- Transcode profile system
- Quality presets
- Background transcoding queue

**UI:**
- Transcode settings
- Transcode progress
- Quality presets selector

**Tests:**
- **TDD**: Transcode engine, profile system
- **Unit**: Transcode quality, format conversion
- **Integration**: Transcode file, verify output quality
- **BDD**: "As a user, I want to sync FLAC files as MP3 320kbps"

**Right-BICEP:**
- **[Right]**: Verify output format, bitrate, quality match settings
- **[B]**: Very short files, very long files, various formats
- **[I]**: Transcode → Verify → Delete → Re-transcode, verify identical
- **[C]**: Compare with external transcoder (ffmpeg CLI)
- **[E]**: Corrupt input, invalid settings, disk full
- **[P]**: Transcode real-time factor < 0.5x, queue management
- **Edge**: Unusual formats, variable bitrate, embedded chapters

---

### Phase 5: ML & AI Features (Weeks 37-44)

#### 5.1 Acoustic Fingerprinting (Weeks 37-40)

**Backend:**
- Chromaprint integration
- AcoustID lookup
- Fingerprint caching

**UI:**
- Fingerprint status indicators
- Manual fingerprint trigger

**Tests:**
- **TDD**: Fingerprint generation, lookup logic
- **Unit**: Fingerprint accuracy, cache hit/miss
- **Integration**: Fingerprint track, verify AcoustID match
- **BDD**: "As a user, I want unknown tracks to be identified automatically"

**Right-BICEP:**
- **[Right]**: Verify fingerprint matches known tracks correctly
- **[B]**: Very short clips, silence, heavily compressed audio
- **[I]**: Generate → Lookup → Verify consistency
- **[C]**: Compare with AcoustID web service directly
- **[E]**: Network failure, invalid audio, API errors
- **[P]**: Fingerprint generation < 5s per track
- **Edge**: Live recordings, remixes, low quality sources

#### 5.2 ML Classification & Recommendations (Weeks 41-44)

**Backend:**
- Core ML model integration
- Genre/mood classification
- Embedding generation
- Similarity calculation
- Recommendation engine

**UI:**
- ML-enhanced metadata display
- "More like this" recommendations
- Similarity visualization

**Tests:**
- **TDD**: ML model integration, recommendation algorithms
- **Unit**: Classification accuracy, similarity scores
- **Integration**: Classify track, verify recommendations
- **BDD**: "As a user, I want to see similar tracks based on current song"

**Right-BICEP:**
- **[Right]**: Verify classifications reasonable, recommendations relevant
- **[B]**: Unknown genres, instrumental tracks, spoken word
- **[I]**: Classify → Verify → Re-classify, check consistency
- **[C]**: Compare with manual genre assignment
- **[E]**: Invalid model, corrupted embeddings, NaN values
- **[P]**: Classification < 500ms, recommendations < 200ms
- **Edge**: Mixed genres, experimental music, very short tracks

---

### Phase 6: Plugin System (Weeks 45-52)

#### 6.1 Plugin Runtime (Weeks 45-48)

**Backend (PluginSystem):**
- JavaScriptCore runtime setup
- Plugin sandboxing
- Plugin API (Swift → JS bridge)
- Plugin lifecycle management

**UI:**
- Plugin manager
- Plugin installation/removal
- Plugin settings

**Tests:**
- **TDD**: Plugin runtime, API bridge
- **Unit**: Plugin execution, sandbox isolation
- **Integration**: Load plugin, execute, verify results
- **BDD**: "As a developer, I want to create a plugin that fetches lyrics"

**Right-BICEP:**
- **[Right]**: Verify plugins execute correctly, return expected results
- **[B]**: Empty plugins, very large plugins, many plugins
- **[I]**: Install → Execute → Uninstall → Verify cleanup
- **[C]**: Compare plugin results with direct API calls
- **[E]**: Malicious plugins, infinite loops, memory leaks
- **[P]**: Plugin execution < 100ms, no main thread blocking
- **Edge**: Async plugins, error handling, resource cleanup

#### 6.2 Plugin SDK & Examples (Weeks 49-52)

**Backend:**
- Plugin SDK documentation
- Example plugins (Last.fm scrobbler, Discogs metadata)
- Plugin marketplace infrastructure

**UI:**
- Plugin browser
- Plugin documentation viewer

**Tests:**
- **TDD**: SDK APIs, example plugins
- **Unit**: SDK function coverage
- **Integration**: Example plugins end-to-end
- **BDD**: "As a user, I want to install a Last.fm scrobbler plugin"

**Right-BICEP:**
- **[Right]**: Verify example plugins work as documented
- **[B]**: Simple plugins, complex plugins, plugin dependencies
- **[I]**: Install → Use → Uninstall → Reinstall, verify state
- **[C]**: Compare plugin behavior with native implementation
- **[E]**: Outdated plugins, incompatible versions, broken plugins
- **[P]**: Plugin load time < 50ms, no performance degradation
- **Edge**: Plugin conflicts, version mismatches, permission issues

---

### Phase 7: Polish & Optimization (Weeks 53-60)

#### 7.1 UI/UX Refinement
- Accessibility (VoiceOver, keyboard navigation)
- Dark mode optimization
- Window management
- Performance profiling and optimization

#### 7.2 Integration & Ecosystem
- Apple Music library import
- iCloud Drive integration
- System media controls
- Share extensions

#### 7.3 Documentation & Release
- User documentation
- Developer documentation
- API documentation
- Release preparation

---

## Testing Methodology Summary

### TDD (Test-Driven Development)
- Write tests before implementation
- Red → Green → Refactor cycle
- Focus on unit tests for core logic

### BDD (Behavior-Driven Development)
- Gherkin-style scenarios for user flows
- Example: "Given I have a music library, When I search for 'jazz', Then I see jazz tracks"
- Use Quick/Nimble for Swift BDD

### ATDD (Acceptance Test-Driven Development)
- Acceptance criteria as executable tests
- Integration tests for features
- End-to-end tests for critical paths

### Right-BICEP Checklist (for every feature)

1. **[Right]**: Are the results right?
   - Golden tests, expected outputs, regression tests

2. **[B]oundary Conditions**: 
   - Empty inputs, maximum inputs, edge values, null/undefined

3. **[I]nverse Relationships**:
   - Reversible operations, roundtrip tests, undo/redo

4. **[C]ross-Check Using Other Means**:
   - Alternative implementations, external tools, manual verification

5. **[E]rror Conditions**:
   - Invalid inputs, network failures, resource exhaustion, corruption

6. **[P]erformance Characteristics**:
   - Response times, throughput, memory usage, CPU usage

7. **Edge Cases**:
   - Unicode, special characters, very large/small values, race conditions

---

## Test Coverage Goals

- **Unit Tests**: > 80% code coverage
- **Integration Tests**: All critical paths covered
- **Performance Tests**: All operations meet SLA targets
- **BDD Scenarios**: All user-facing features have scenarios

## CI/CD Pipeline

- **On every commit**: Unit tests, linting, build verification
- **On PR**: Integration tests, code coverage report
- **On merge to main**: Full test suite, performance benchmarks, release candidate build
- **Weekly**: Full regression suite, dependency updates

## Testing Tools

### Swift
- **XCTest**: Unit and integration tests
- **Quick/Nimble**: BDD-style testing
- **Mocking**: Protocol-based mocks, OCMock for Objective-C bridges

### C++
- **Google Test**: Unit testing framework
- **Google Mock**: Mocking framework
- **Valgrind**: Memory leak detection

### Rust (if used)
- **Built-in `#[test]`**: Unit tests
- **Criterion**: Benchmarking
- **Mockall**: Mocking framework

### JavaScript (Plugins)
- **Jest**: Unit testing for plugin examples
- **Manual Testing**: Plugin sandbox verification

## Performance Benchmarks

### Library Operations
- Scan 10,000 tracks: < 5 minutes
- Search 100,000 tracks: < 100ms (P95)
- Load playlist (1000 tracks): < 200ms

### Playback
- Start playback: < 100ms
- Seek accuracy: ±10ms
- UI responsiveness: < 16ms (60fps)

### Tagging
- Single tag write: < 100ms
- Batch 100 tracks: < 10s
- Tag read: < 10ms

### ML/AI
- Genre classification: < 500ms per track
- Fingerprint generation: < 5s per track
- Recommendations: < 200ms
