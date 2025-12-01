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
    
    // MARK: - Queue History (for previous track navigation)
    
    public var queueHistory: [Track] = []
    public var currentQueueIndex: Int = -1
    
    // MARK: - Additional Mock Properties
    
    public var volume: Float = 1.0
    public var isMuted: Bool = false
    public var loopMode: LoopMode = .none
    public var isShuffleEnabled: Bool = false
    public let visualiser: AudioVisualiserProtocol = AudioVisualiser()
    
    var playCalled = false
    var pauseCalled = false
    var stopCalled = false
    var seekCalled = false
    var loadTrackCalled = false
    var playNextCalled = false
    var playPreviousCalled = false
    var replayCalled = false
    
    var shouldFailPlay = false
    var shouldFailLoad = false
    var previousVolume: Float = 1.0
    
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
    
    // MARK: - Queue Navigation
    
    public func addToQueue(_ track: Track) {
        queue.append(track)
    }
    
    public func removeFromQueue(_ track: Track) {
        queue.removeAll { $0.id == track.id }
    }
    
    public func playNext() async throws {
        playNextCalled = true
        if queue.isEmpty {
            throw AudioEngineError.queueEmpty
        }
        let nextTrack = queue.removeFirst()
        try await loadTrack(nextTrack)
        try await play()
    }
    
    public func playPrevious() async throws {
        playPreviousCalled = true
        
        // Check if we have history to go back to
        guard currentQueueIndex > 0 else {
            throw AudioEngineError.queueEmpty
        }
        
        // Get previous track from history
        let previousIndex = currentQueueIndex - 1
        let previousTrack = queueHistory[previousIndex]
        
        // Move current track back to queue if it exists
        if let current = currentTrack {
            queue.insert(current, at: 0)
        }
        
        // Update index before loading previous track
        currentQueueIndex = previousIndex
        try await loadTrack(previousTrack)
        try await play()
    }
    
    // MARK: - Volume Control
    
    public func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
    }
    
    public func setMuted(_ muted: Bool) {
        if muted {
            previousVolume = volume
            volume = 0.0
        } else {
            volume = previousVolume
        }
        isMuted = muted
    }
    
    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            previousVolume = volume
            volume = 0.0
        } else {
            volume = previousVolume
        }
    }
    
    // MARK: - Advanced Playback
    
    public func replay() async throws {
        replayCalled = true
        guard currentTrack != nil else {
            throw AudioEngineError.noTrackLoaded
        }
        currentPosition = 0.0
        if state == .paused {
            state = .playing
        }
    }
    
    public func skipForward(seconds: TimeInterval) async throws {
        currentPosition = min(currentPosition + seconds, duration)
    }
    
    public func skipBackward(seconds: TimeInterval) async throws {
        currentPosition = max(currentPosition - seconds, 0.0)
    }
    
    // MARK: - Loop Control
    
    public func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
    }
    
    public func toggleLoopMode() {
        switch loopMode {
        case .none:
            loopMode = .track
        case .track:
            loopMode = .queue
        case .queue:
            loopMode = .none
        }
    }
    
    // MARK: - Shuffle Control
    
    public func toggleShuffle() {
        isShuffleEnabled.toggle()
        if isShuffleEnabled && !queue.isEmpty {
            queue.shuffle()
        }
    }
    
    public func setShuffle(_ enabled: Bool) {
        isShuffleEnabled = enabled
        if isShuffleEnabled && !queue.isEmpty {
            queue.shuffle()
        }
    }
}
