//
//  AudioEngine_PlaybackControl.swift
//  AudioCore
//
//  Playback control extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// MARK: - Volume Control Extension
extension AudioEngine {
    /// Set volume level
    /// - Parameter volume: Volume level (0.0 to 1.0)
    public func setVolume(_ volume: Float) {
        // CRITICAL: If muted, don't allow volume changes (except to 0.0)
        if isMuted && volume > 0.0 {
            Logger.audio.debug("Volume change ignored - muted (attempted to set volume to \(volume))")
            return
        }
        self.volume = volume
    }
    
    /// Increase volume by a specified step
    /// - Parameter step: Step size (default: 0.01 = 1%)
    /// Volume increments are in percentage (0.0 to 1.0), not in dB like gain control
    /// If step is negative, volume will decrease instead
    public func increaseVolume(by step: Float = 0.01) {
        let newVolume = min(1.0, volume + step)
        self.volume = newVolume
        Logger.audio.debug("Volume increased by \(step * 100)% to \(newVolume * 100)%")
    }
    
    /// Decrease volume by a specified step
    /// - Parameter step: Step size (default: 0.01 = 1%)
    /// Volume decrements are in percentage (0.0 to 1.0), not in dB like gain control
    /// If step is negative, volume will increase instead
    public func decreaseVolume(by step: Float = 0.01) {
        let newVolume = max(0.0, volume - step)
        self.volume = newVolume
        Logger.audio.debug("Volume decreased by \(step * 100)% to \(newVolume * 100)%")
    }
    
    /// Set muted state
    /// - Parameter muted: Whether to mute
    public func setMuted(_ muted: Bool) {
        self.isMuted = muted
    }
    
    /// Toggle mute state
    public func toggleMute() {
        isMuted.toggle()
    }
}

// MARK: - Seek and Position Extension
extension AudioEngine {
    /// Seek to a specific position
    /// - Parameter position: Target position in seconds
    /// - Throws: AudioEngineError if seek fails
    public func seek(to position: TimeInterval) async throws {
        guard currentTrack != nil else {
            throw AudioEngineError.noTrackLoaded
        }
        
        // Clamp position to valid range
        let clampedPosition = max(0.0, min(position, duration))
        
        guard clampedPosition >= 0.0 && clampedPosition <= duration else {
            throw AudioEngineError.invalidSeekPosition
        }
        
        Logger.audio.debug("Seeking to position: \(clampedPosition)s")
        guard await nativeEngine.seek(to: clampedPosition) else {
            throw AudioEngineError.trackLoadFailed("Native audio engine failed to seek to \(clampedPosition)")
        }
        // Update position from native engine (it may have clamped the value)
        currentPosition = nativeEngine.currentPosition
    }
    
    /// Seek by a relative amount
    /// - Parameter offset: Amount to seek (positive = forward, negative = backward)
    /// - Throws: AudioEngineError if seek fails
    public func seek(by offset: TimeInterval) async throws {
        let newPosition = currentPosition + offset
        try await seek(to: newPosition)
    }
}

// MARK: - Advanced Playback Extension
extension AudioEngine {
    /// Replay current track from beginning
    /// - Throws: AudioEngineError if no track loaded
    public func replay() async throws {
        Logger.audio.info("Replay requested")
        guard currentTrack != nil else {
            throw AudioEngineError.noTrackLoaded
        }
        
        try await seek(to: 0.0)
        if state == .paused {
            try await resume()
        } else if state == .stopped {
            try await play()
        }
        Logger.audio.info("Track replayed from beginning")
    }
    
    /// Skip forward by specified seconds
    /// - Parameter seconds: Number of seconds to skip forward
    /// - Throws: AudioEngineError if seek fails
    public func skipForward(seconds: TimeInterval) async throws {
        let newPosition = min(currentPosition + seconds, duration)
        try await seek(to: newPosition)
        Logger.audio.debug("Skipped forward \(seconds) seconds")
    }
    
    /// Skip backward by specified seconds
    /// - Parameter seconds: Number of seconds to skip backward
    /// - Throws: AudioEngineError if seek fails
    public func skipBackward(seconds: TimeInterval) async throws {
        let newPosition = max(currentPosition - seconds, 0.0)
        try await seek(to: newPosition)
        Logger.audio.debug("Skipped backward \(seconds) seconds")
    }
    
    // MARK: - Loop Control
    
    /// Set loop mode
    /// - Parameter mode: Loop mode to set
    public func setLoopMode(_ mode: LoopMode) {
        self.loopMode = mode
        Logger.audio.debug("Loop mode set to: \(mode)")
    }
    
    /// Toggle loop mode (none -> track -> queue -> none)
    public func toggleLoopMode() {
        switch self.loopMode {
        case .none:
            self.loopMode = .track
        case .track:
            self.loopMode = .queue
        case .queue:
            self.loopMode = .none
        }
        Logger.audio.debug("Loop mode toggled to: \(self.loopMode)")
    }
    
    // MARK: - Shuffle Control
    
    /// Toggle shuffle mode
    public func toggleShuffle() {
        self.isShuffleEnabled.toggle()
        Logger.audio.debug("Shuffle mode toggled to: \(self.isShuffleEnabled)")
        
        // If shuffle is enabled, shuffle the queue
        if self.isShuffleEnabled && !self.queue.isEmpty {
            self.queue.shuffle()
            Logger.audio.debug("Queue shuffled: \(self.queue.count) tracks")
        }
    }
    
    /// Set shuffle mode
    /// - Parameter enabled: Whether shuffle is enabled
    public func setShuffle(_ enabled: Bool) {
        self.isShuffleEnabled = enabled
        Logger.audio.debug("Shuffle mode set to: \(enabled)")
        
        // If shuffle is enabled, shuffle the queue
        if self.isShuffleEnabled && !self.queue.isEmpty {
            self.queue.shuffle()
            Logger.audio.debug("Queue shuffled: \(self.queue.count) tracks")
        }
    }
}

// MARK: - Visualization Extension
extension AudioEngine {
    /// Set visualisation volume (0.0 to 1.0)
    /// Controls the output volume of the visualisation engine
    /// - Parameter volume: Volume level (0.0 to 1.0), will be clamped
    public func setVisualizationVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        visualiserTap?.volume = clamped
    }
    
    /// Get current visualisation volume
    /// - Returns: Current visualisation volume (0.0 to 1.0)
    public func getVisualizationVolume() -> Float {
        visualiserTap?.volume ?? 1.0
    }
}
