//
//  AudioEngine_QueueNavigation.swift
//  AudioCore
//
//  Queue navigation extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// MARK: - Queue Navigation Extension
extension AudioEngine {
    /// Play next track in queue
    /// - Throws: AudioEngineError if no next track available
    public func playNext() async throws {
        Logger.audio.info("Play next requested")
        
        // Check if we have a next track in queue
        if !queue.isEmpty {
            let nextTrack = queue.removeFirst()
            // Ensure current track is in history (should already be there from play() or previous playNext())
            if let current = currentTrack {
                // Only add if not already the last item in history
                if queueHistory.isEmpty || queueHistory.last?.id != current.id {
                    queueHistory.append(current)
                    currentQueueIndex = queueHistory.count - 1
                }
            }
            try await loadTrack(nextTrack)
            // Add the next track to history
            queueHistory.append(nextTrack)
            currentQueueIndex = queueHistory.count - 1
            try await play()
            Logger.audio.info("Advanced to next track: \(nextTrack.title)")
            return
        }
        
        // Check loop mode
        if loopMode == .queue && !queueHistory.isEmpty {
            // Restart from beginning of history
            let firstTrack = queueHistory[0]
            queueHistory.removeAll()
            currentQueueIndex = -1
            try await loadTrack(firstTrack)
            try await play()
            Logger.audio.info("Looped to first track in queue")
            return
        }
        
        throw AudioEngineError.queueEmpty
    }
    
    /// Play previous track in queue
    /// - Throws: AudioEngineError if no previous track available
    public func playPrevious() async throws {
        Logger.audio.info("Play previous requested")
        
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
        Logger.audio.info("Went back to previous track: \(previousTrack.title)")
    }
    
    /// Move a track in the queue
    /// - Parameters:
    ///   - from: Source index
    ///   - to: Destination index
    public func moveTrack(
        from sourceIndex: Int,
        to destinationIndex: Int
    ) {
        guard sourceIndex >= 0 && sourceIndex < self.queue.count,
              destinationIndex >= 0 &&
              destinationIndex < self.queue.count else {
            let message = "Invalid queue indices: from=\(sourceIndex), " +
                "to=\(destinationIndex), count=\(self.queue.count)"
            Logger.audio.warning("\(message)")
            return
        }
        
        let track = queue.remove(at: sourceIndex)
        queue.insert(track, at: destinationIndex)
        Logger.audio.debug(
            "Moved track in queue: from=\(sourceIndex), to=\(destinationIndex)"
        )
    }
}
