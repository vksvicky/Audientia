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
    static func createMockEngine(withTracks tracks: [Track] = []) -> AudioEngine {
        let mockFileSystem = MockFileSystem()
        for track in tracks {
            mockFileSystem.addFile(track.filePath)
        }
        // Use internal initializer (fileSystem parameter)
        return AudioEngine(fileSystem: mockFileSystem)
    }
    
    /// Create an AudioEngine with real file system for integration tests
    /// - Returns: AudioEngine configured for integration testing
    static func createRealEngine() -> AudioEngine {
        AudioEngine() // Uses real file system
    }
    
    /// Create an AudioEngine with a track already loaded (for convenience)
    /// - Parameter track: Track to load
    /// - Returns: AudioEngine with track loaded
    static func createEngineWithTrack(_ track: Track) async throws -> AudioEngine {
        let engine = createMockEngine(withTracks: [track])
        try await engine.loadTrack(track)
        return engine
    }
    
    /// Create an AudioEngine with mock file system and tracks already in queue
    /// - Parameter tracks: Array of tracks to add to queue and mock file system
    /// - Returns: AudioEngine with tracks in queue and registered in mock file system
    static func createMockEngineWithQueue(_ tracks: [Track]) -> AudioEngine {
        let engine = createMockEngine(withTracks: tracks)
        for track in tracks {
            engine.addToQueue(track)
        }
        return engine
    }
}
