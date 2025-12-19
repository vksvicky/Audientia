//
//  AudioEngine_Playback.swift
//  AudioCore
//
//  Playback control extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// MARK: - Playback Control Extension
extension AudioEngine {
    /// Start playback
    /// - Throws: AudioEngineError if playback cannot start
    public func play() async throws {
        // CRITICAL: If already playing, don't start duplicate playback
        // This ensures only one track plays at a time
        if state == .playing {
            Logger.audio.debug("Play called but already playing - ignoring to prevent duplicate playback")
            return
        }
        
        // Check if queue has tracks but no current track
        if currentTrack == nil && !queue.isEmpty {
            let nextTrack = queue.removeFirst()
            try await loadTrack(nextTrack)
            // Track is now loaded, add to history (this is the first track)
            queueHistory.append(nextTrack)
            currentQueueIndex = queueHistory.count - 1
        }
        
        guard let track = currentTrack else {
            // If no track is loaded, check if queue is empty
            if queue.isEmpty {
                throw AudioEngineError.queueEmpty
            } else {
                // This shouldn't happen as we load from queue above,
                // but handle it just in case
                throw AudioEngineError.noTrackLoaded
            }
        }
        
        Logger.audio.info("Starting playback: \(track.title)")
        
        // Save last played track for restoration on app restart
        AppSettings.shared.lastPlayedTrack = track
        
        // Start main playback engine (actual audio playback)
        guard await nativeEngine.play() else {
            throw AudioEngineError.trackLoadFailed("Native audio engine failed to start playback")
        }
        
        // CRITICAL: Reapply playback speed after starting playback
        // This ensures the saved speed is applied even if the native engine reset it
        let rate = Float(self.playbackSpeed.rawValue)
        nativeEngine.setRate(rate)
        Logger.audio.debug("Reapplied playback speed: \(self.playbackSpeed.displayName) (rate: \(rate))")
        
        // CRITICAL: Reapply audio gain after starting playback
        // This ensures the saved gain settings are applied
        await updateGainMultiplier()
        
        // Start visualiser tap for real-time audio data (runs in parallel, no audio output)
        // This provides real audio samples for visualisation
        // Sync with current playback position if available
        let currentPos = currentPosition
        if visualiserTap?.play(startPosition: currentPos > 0 ? currentPos : nil) == false {
            Logger.audio.warning("Failed to start visualiser tap, visualisation may not work")
        }
        
        // Start position tracking
        startPositionTracking()
        
        state = .playing
        Logger.audio.debug("Playback started")
    }
    
    /// Pause playback
    /// Made async to support concurrent operations and non-blocking I/O
    public func pause() async {
        guard state == .playing else {
            Logger.audio.debug("Pause called but not playing (state: \(String(describing: self.state)))")
            return
        }
        
        Logger.audio.info("Pausing playback")
        stopPositionTracking()
        visualiserTap?.pause()
        nativeEngine.pause()
        state = .paused
    }
    
    /// Resume playback
    /// - Throws: AudioEngineError if resume fails
    public func resume() async throws {
        guard state == .paused else {
            if self.state == .stopped {
                throw AudioEngineError.noTrackLoaded
            }
            Logger.audio.debug("Resume called but not paused (state: \(String(describing: self.state)))")
            return
        }
        
        guard currentTrack != nil else {
            throw AudioEngineError.noTrackLoaded
        }
        
        Logger.audio.info("Resuming playback")
        guard await nativeEngine.play() else {
            throw AudioEngineError.trackLoadFailed("Native audio engine failed to resume playback")
        }
        
        // CRITICAL: Reapply playback speed after resuming playback
        // This ensures the saved speed is applied
        let rate = Float(self.playbackSpeed.rawValue)
        nativeEngine.setRate(rate)
        Logger.audio.debug("Reapplied playback speed on resume: \(self.playbackSpeed.displayName) (rate: \(rate))")
        
        // CRITICAL: Reapply audio gain after resuming playback
        // This ensures the saved gain settings are applied
        await updateGainMultiplier()
        
        // Restart visualiser tap for real-time audio data (runs in parallel, no audio output)
        // This ensures visualisation continues after resume
        // Sync with current playback position if available
        let currentPos = currentPosition
        if visualiserTap?.play(startPosition: currentPos > 0 ? currentPos : nil) == false {
            Logger.audio.warning("Failed to restart visualiser tap on resume, visualisation may not work")
        }
        
        startPositionTracking()
        state = .playing
    }
    
    /// Stop playback and reset position
    /// Made async to support concurrent operations and non-blocking I/O
    public func stop() async {
        Logger.audio.info("Stopping playback")
        stopPositionTracking()
        visualiserTap?.stop()
        nativeEngine.stop()
        currentPosition = 0.0
        state = .stopped
    }
}
