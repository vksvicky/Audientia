//
//  AudioEngineTestHelpers.swift
//  AudioCoreTests
//
//  Helper functions for creating AudioEngine instances in tests
//

@testable import AudioCore
import Foundation
@testable import Shared

/// Helper functions for creating AudioEngine instances in tests
@MainActor
enum AudioEngineTestHelpers {
    /// Create an AudioEngine with mock file system for unit tests
    /// - Parameter tracks: Optional array of tracks to add to mock file system
    /// - Returns: AudioEngine configured for testing
    static func createMockEngine(
        withTracks tracks: [Shared.Track] = [],
        formatCoordinator: FormatDecodingCoordinating = MockFormatDecodingCoordinator(),
        nativeEngine: NativeAudioEngineProtocol? = nil
    ) -> AudioEngine {
        let mockFileSystem = MockFileSystem()
        for track in tracks {
            mockFileSystem.addFile(track.filePath)
        }
        let engineBridge = nativeEngine ?? MockNativeAudioEngine()
        return AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: formatCoordinator,
            nativeEngine: engineBridge
        )
    }
    
    /// Create an AudioEngine with real file system for integration tests
    /// - Returns: AudioEngine configured for integration testing
    static func createRealEngine() -> AudioEngine {
        AudioEngine() // Uses real file system
    }
    
    /// Create an AudioEngine with a track already loaded (for convenience)
    /// - Parameter track: Track to load
    /// - Returns: AudioEngine with track loaded
    static func createEngineWithTrack(_ track: Shared.Track) async throws -> AudioEngine {
        let nativeEngine = MockNativeAudioEngine()
        // Set native engine duration to match track duration for accurate testing
        nativeEngine.nextLoadDuration = track.duration > 0 ? track.duration : nil
        let engine = createMockEngine(withTracks: [track], nativeEngine: nativeEngine)
        try await engine.loadTrack(track)
        return engine
    }
    
    /// Create an AudioEngine with mock file system and tracks already in queue
    /// - Parameter tracks: Array of tracks to add to queue and mock file system
    /// - Returns: AudioEngine with tracks in queue and registered in mock file system
    static func createMockEngineWithQueue(_ tracks: [Shared.Track]) -> AudioEngine {
        let engine = createMockEngine(withTracks: tracks)
        for track in tracks {
            engine.addToQueue(track)
        }
        return engine
    }
    
    /// Create an AudioEngine with mock file system and tracks already in queue, returning both engine and native engine
    /// - Parameter tracks: Array of tracks to add to queue and mock file system
    /// - Returns: Tuple with AudioEngine and MockNativeAudioEngine for position manipulation in tests
    static func createMockEngineWithQueueAndNativeEngine(_ tracks: [Shared.Track]) -> (engine: AudioEngine, nativeEngine: MockNativeAudioEngine) {
        let nativeEngine = MockNativeAudioEngine()
        // Set duration for each track when loaded
        if let firstTrack = tracks.first {
            nativeEngine.nextLoadDuration = firstTrack.duration
        }
        let engine = createMockEngine(withTracks: tracks, nativeEngine: nativeEngine)
        for track in tracks {
            engine.addToQueue(track)
        }
        return (engine, nativeEngine)
    }
    
    /// Create an AudioEngine with a track already loaded, returning both engine and native engine
    /// - Parameter track: Track to load
    /// - Returns: Tuple with AudioEngine and MockNativeAudioEngine for position manipulation in tests
    static func createEngineWithTrackAndNativeEngine(_ track: Shared.Track) async throws -> (engine: AudioEngine, nativeEngine: MockNativeAudioEngine) {
        let nativeEngine = MockNativeAudioEngine()
        // Set native engine duration to match track duration for accurate testing
        nativeEngine.nextLoadDuration = track.duration > 0 ? track.duration : nil
        let engine = createMockEngine(withTracks: [track], nativeEngine: nativeEngine)
        try await engine.loadTrack(track)
        return (engine, nativeEngine)
    }
}
