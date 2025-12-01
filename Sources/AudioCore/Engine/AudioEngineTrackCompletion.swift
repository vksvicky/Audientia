//
//  AudioEngineTrackCompletion.swift
//  Audientia
//
//  Extracted track completion and queue handling logic to keep AudioEngine.swift
//  within SwiftLint's recommended file length limits.
//

import Foundation
import os.log

// MARK: - Track Completion Handling Extension

// Keep in same module as AudioEngine; defined in AudioEngine.swift

extension AudioEngine {
    func handleTrackCompletion() async {
        Logger.audio.info("Track completed, checking loop mode and queue")
        
        // Handle loop modes
        if await handleLoopMode() {
            return // Loop mode handled the completion
        }
        
        // Normal completion: advance to next track or stop
        await handleNormalCompletion()
    }
    
    func handleLoopMode() async -> Bool {
        switch loopMode {
        case .track:
            return await handleTrackLoop()
        case .queue:
            return await handleQueueLoop()
        case .none:
            return false
        }
    }
    
    func handleTrackLoop() async -> Bool {
        guard let track = currentTrack else { return false }
        do {
            try await replay()
            Logger.audio.info("Looped current track: \(track.title)")
            return true
        } catch {
            Logger.audio.error("Failed to loop track: \(error.localizedDescription)")
            return false
        }
    }
    
    func handleQueueLoop() async -> Bool {
        guard queue.isEmpty, !queueHistory.isEmpty else { return false }
        let firstTrack = queueHistory[0]
        queueHistory.removeAll()
        currentQueueIndex = -1
        
        // Stop current playback before loading next track to prevent overlapping
        if state == .playing {
            Logger.audio.debug("Stopping current track before looping to first track")
            stopPositionTracking()
            visualiserTap?.stop()
            nativeEngine.stop()
            currentPosition = 0.0
        }
        
        do {
            try await loadTrack(firstTrack)
            queueHistory.append(firstTrack)
            currentQueueIndex = 0
            try await play()
            Logger.audio.info("Looped to first track in queue")
            return true
        } catch {
            Logger.audio.error("Failed to loop queue: \(error.localizedDescription)")
            return false
        }
    }
    
    func handleNormalCompletion() async {
        guard !queue.isEmpty else {
            await stop()
            Logger.audio.info("Queue empty, stopping playback")
            return
        }
        
        // Check if next track is the same as current track (prevents infinite loop when single track finishes)
        if let currentTrack = currentTrack,
           let nextTrack = queue.first,
           currentTrack.id == nextTrack.id,
           loopMode == .none {
            // Same track in queue with no loop mode - stop instead of replaying
            await stop()
            Logger.audio.info("Track completed, same track in queue with loop mode off - stopping playback")
            return
        }
        
        // Auto-advance to next track
        let nextTrack = queue.removeFirst()
        // Add current track to history
        if let current = currentTrack {
            queueHistory.append(current)
            currentQueueIndex = queueHistory.count - 1
        }
        
        // CRITICAL: Stop current playback before loading next track to prevent overlapping
        // This ensures the current track stops playing before the next one starts
        if state == .playing {
            Logger.audio.debug("Stopping current track before loading next track")
            stopPositionTracking()
            visualiserTap?.stop()
            nativeEngine.stop()
            currentPosition = 0.0
            // Don't set state to .stopped yet - we'll set it to .loading in loadTrack
        }
        
        do {
            try await loadTrack(nextTrack)
            queueHistory.append(nextTrack)
            currentQueueIndex = queueHistory.count - 1
            try await play()
            Logger.audio.info("Auto-advanced to next track: \(nextTrack.title)")
        } catch {
            Logger.audio.error("Failed to auto-advance to next track: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
}
