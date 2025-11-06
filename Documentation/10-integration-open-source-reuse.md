# Integration and Reuse of Existing OSS

## Overview

Audientia leverages existing open-source projects to accelerate development while adding unique value through integration and enhancement.

## Primary Open Source Projects

### Navidrome (Go - Music Server)

**What We Reuse**:
- Subsonic API compatibility layer (concepts, not code)
- Library scanning patterns and algorithms
- Metadata extraction approaches
- Streaming architecture concepts

**How We Adapt**:
- **Not Direct Code Reuse**: Navidrome is Go-based, Audientia is Swift/C++
- **Architecture Patterns**: Learn from Navidrome's design
- **API Compatibility**: Ensure Audientia can connect to Navidrome servers
- **Future Integration**: Potential to run Navidrome as backend, Audientia as client

**License**: GPL-3.0 (compatible with our AGPL-3.0 for server components)

**Contribution Strategy**:
- Contribute improvements upstream when applicable
- Maintain compatibility with Navidrome's Subsonic API
- Share architectural insights

### Otter (Android Subsonic Client)

**What We Learn**:
- Subsonic API consumption patterns
- Mobile UX patterns (adapt for macOS)
- Offline caching strategies
- Playback queue management

**How We Adapt**:
- **UI/UX Inspiration**: Clean, minimal interface design
- **API Patterns**: Subsonic client implementation patterns
- **Caching**: Offline-first approach for remote libraries

**License**: GPL-3.0

**Contribution Strategy**:
- Share macOS-native patterns back
- Contribute to Subsonic API compatibility testing

### Monochrome (macOS Music Player)

**What We Learn**:
- Native macOS integration patterns
- SwiftUI best practices for music players
- Performance optimization techniques
- Minimalist UI design

**How We Adapt**:
- **UI Patterns**: Clean, native macOS design language
- **Performance**: Efficient library browsing techniques
- **Integration**: System media controls, menu bar integration

**License**: MIT (compatible)

**Contribution Strategy**:
- Share advanced features (tagging, sync) back
- Collaborate on macOS music player ecosystem

## Libraries and Frameworks

### Audio Processing

#### FFmpeg
- **Purpose**: Format decoding for exotic formats
- **Integration**: C++ wrapper, optional dependency
- **License**: LGPL-2.1 (dynamic linking)
- **Usage**: Fallback decoder when CoreAudio doesn't support format

#### JUCE (Optional)
- **Purpose**: Cross-platform audio framework
- **Consideration**: May be overkill, prefer native AVFoundation
- **License**: GPL/Commercial
- **Decision**: Evaluate vs. custom CoreAudio wrapper

### Metadata Processing

#### Rust Crates
- **`id3`**: ID3v2 tag reading/writing
- **`lofty`**: Multi-format tag library
- **`metaflac`**: FLAC metadata
- **Integration**: Swift FFI or direct Swift implementation
- **License**: MIT/Apache-2.0

#### Swift Libraries
- **Custom Parsers**: May implement natively in Swift
- **Performance**: Evaluate Rust FFI vs. Swift implementation

### Machine Learning

#### Core ML
- **Purpose**: On-device ML inference
- **Integration**: Native Swift/Core ML
- **Models**: Pre-trained or custom-trained
- **License**: Apple's frameworks

#### Chromaprint
- **Purpose**: Acoustic fingerprinting
- **Integration**: Rust crate or C++ library
- **License**: MIT

### Database

#### CoreData
- **Purpose**: Primary data store
- **Integration**: Native Apple framework
- **License**: Apple's frameworks

#### SQLite
- **Purpose**: Search index, metadata cache
- **Integration**: Native Swift wrapper
- **License**: Public Domain

### Plugin System

#### JavaScriptCore
- **Purpose**: JavaScript runtime for plugins
- **Integration**: Native Apple framework
- **License**: Apple's frameworks

## External APIs

### MusicBrainz
- **Purpose**: Metadata lookup and enrichment
- **API**: REST API, rate-limited
- **License**: CC0 (data), GPL (code)
- **Integration**: Swift async/await HTTP client
- **Usage**: Auto-tagging, missing metadata completion

### Discogs
- **Purpose**: Album information, artwork
- **API**: REST API, requires API key
- **License**: Proprietary (data)
- **Integration**: Swift async/await HTTP client
- **Usage**: Enhanced album metadata, high-res artwork

### AcoustID
- **Purpose**: Track identification via fingerprint
- **API**: REST API, free tier available
- **License**: Proprietary (service)
- **Integration**: Swift async/await HTTP client
- **Usage**: Unknown track identification

### Last.fm (via Plugins)
- **Purpose**: Scrobbling, recommendations
- **API**: REST API, requires API key
- **License**: Proprietary (service)
- **Integration**: Via plugin system
- **Usage**: User-installed scrobbling plugin

## Compliance and Licensing

### License Compatibility

**Audientia License Strategy**:
- **Desktop App**: MIT (permissive, encourages adoption)
- **Server Components** (if any): AGPL-3.0 (copyleft, ensures open source)

**Compatible Licenses**:
- ✅ MIT: Can use freely
- ✅ Apache-2.0: Can use freely
- ✅ LGPL: Can use with dynamic linking
- ✅ GPL-3.0: Compatible with AGPL-3.0
- ⚠️ GPL-2.0: May have compatibility issues

**Incompatible Licenses**:
- ❌ Proprietary: Cannot use
- ❌ AGPL-incompatible: Check carefully

### Attribution Requirements

**Required Attributions**:
- FFmpeg: Include license notice, link to source
- Rust crates: Include license files
- Other OSS: Follow license requirements

**Implementation**:
- `LICENSES/` directory with all license files
- About dialog with attributions
- README with credit section

### Contribution Strategy

**Upstream Contributions**:
- Contribute bug fixes to upstream projects
- Share improvements when applicable
- Maintain good relationships with OSS communities

**Forking Policy**:
- Prefer using libraries over forking
- If forking, maintain clear delta documentation
- Keep forks in sync with upstream

## Integration Patterns

### Swift-C++ Bridge
```swift
// C++ interface
@_cdecl("audio_engine_create")
func audioEngineCreate() -> UnsafeMutableRawPointer

@_cdecl("audio_engine_play")
func audioEnginePlay(_ engine: UnsafeMutableRawPointer, _ url: UnsafePointer<CChar>)
```

### Swift-Rust Bridge
```rust
// Rust with C FFI
#[no_mangle]
pub extern "C" fn parse_id3(path: *const c_char) -> *mut TagData {
    // Implementation
}
```

### JavaScriptCore Integration
```swift
// Swift bridge to JavaScriptCore
let context = JSContext()
context.setObject(apiObject, forKeyedSubscript: "audientia" as NSString)
```

## Testing Compatibility

### Subsonic API Compatibility
- **Test Suite**: Ensure compatibility with Subsonic clients
- **Server Mode**: Test Audientia as Subsonic server (future)
- **Client Mode**: Test Audientia connecting to Navidrome

### File Format Compatibility
- **Test Suite**: Verify all formats work correctly
- **Edge Cases**: Corrupt files, unusual encodings
- **Cross-Platform**: Ensure files work across platforms

## Future Integration Opportunities

### Subsonic Server Mode
- **Potential**: Run Navidrome-compatible server
- **Benefit**: Remote access to library
- **Timeline**: Post-v1.0

### Cloud Sync
- **Potential**: Integrate with cloud storage providers
- **Providers**: iCloud, Dropbox, Google Drive
- **Timeline**: Post-v1.0

### Streaming Services
- **Potential**: Connect to streaming APIs
- **Services**: Spotify (if API available), Apple Music
- **Timeline**: Post-v2.0

## Dependency Management

### Swift Package Manager
- **Primary**: Use SPM for Swift dependencies
- **Examples**:
  - Combine (built-in)
  - SwiftUI (built-in)
  - Third-party: Add as needed

### C++ Dependencies
- **spdlog**: Logging library
- **FFmpeg**: Optional, dynamic linking
- **CMake/Conan**: Build system for C++ dependencies

### Rust Dependencies
- **Cargo**: Rust package manager
- **FFI**: Expose Rust functions to Swift via C interface
- **Examples**: `id3`, `lofty`, `chromaprint`

### JavaScript Dependencies
- **JavaScriptCore**: Built-in, no external dependencies
- **Plugin SDK**: Provide API, plugins use vanilla JS

## Version Management

### Dependency Versions
- **Pinning**: Pin major versions, allow minor/patch updates
- **Security**: Regular updates for security patches
- **Compatibility**: Test updates before merging

### API Compatibility
- **Subsonic API**: Maintain compatibility with Subsonic clients
- **Plugin API**: Version plugin API, maintain backward compatibility
- **Internal APIs**: Can evolve, but document breaking changes

## Documentation Requirements

### Attribution Documentation
- **LICENSES/**: Directory with all license files
- **CREDITS.md**: List of all OSS projects and libraries used
- **About Dialog**: Show attributions in app

### Integration Documentation
- **API Docs**: Document how to integrate with Audientia
- **Plugin SDK**: Complete plugin development guide
- **Architecture**: Document integration points

## Legal Considerations

### License Compliance
- **Review**: Regular review of all dependencies
- **Updates**: Update license information as dependencies change
- **Legal Review**: Consider legal review for complex cases

### Patent Considerations
- **Research**: Research any patent issues with technologies used
- **Mitigation**: Use alternative approaches if needed

## Community Engagement

### Upstream Contributions
- **Bug Fixes**: Contribute fixes back to upstream projects
- **Features**: Share useful features when applicable
- **Documentation**: Improve documentation for dependencies

### Ecosystem Building
- **Plugin Marketplace**: Encourage community plugin development
- **Documentation**: Help others integrate with Audientia
- **Community**: Build community around Audientia
