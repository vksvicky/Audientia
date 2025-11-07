// MockAudioEngine.swift
// Audientia - UI Test Infrastructure
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation

@testable import AudioCore
@testable import Shared

/// Mock AudioEngine for UI testing
/// Provides a testable implementation of AudioEngine behavior
@MainActor
final class MockAudioEngine: AudioEngineProtocol {
    // MARK: - AudioEngineProtocol Properties
    
    public var currentTrack: Track?
    public var state: PlaybackState = PlaybackState.stopped
    public var currentPosition: TimeInterval = 0.0
    public var duration: TimeInterval = 0.0
    public var queue: [Track] = []
    
    // MARK: - Additional Mock Properties
    
    var volume: Float = 1.0
    
    var playCalled = false
    var pauseCalled = false
    var stopCalled = false
    var seekCalled = false
    var loadTrackCalled = false
    
    var shouldFailPlay = false
    var shouldFailLoad = false
    
    // MARK: - AudioEngineProtocol Methods
    
    public func play() async throws {
        playCalled = true
        if shouldFailPlay || currentTrack == nil {
            throw AudioEngineError.noTrackLoaded
        }
        state = PlaybackState.playing
    }
    
    public func pause() async {
        pauseCalled = true
        state = PlaybackState.paused
    }
    
    public func stop() async {
        stopCalled = true
        state = PlaybackState.stopped
        currentPosition = 0.0
    }
    
    public func seek(to position: TimeInterval) async throws {
        seekCalled = true
        currentPosition = min(position, duration)
    }
    
    public func loadTrack(_ track: Track) async throws {
        loadTrackCalled = true
        if shouldFailLoad {
            throw AudioEngineError.trackLoadFailed("Mock load failure")
        }
        currentTrack = track
        duration = track.duration
        state = PlaybackState.stopped
    }
}
