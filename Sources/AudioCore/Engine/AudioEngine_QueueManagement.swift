//
//  AudioEngine_QueueManagement.swift
//  AudioCore
//
//  Queue management extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// MARK: - Queue Management Extension
extension AudioEngine {
    /// Add a track to the playback queue
    /// - Parameter track: The track to add
    public func addToQueue(_ track: Track) {
        queue.append(track)
        Logger.audio.debug(
            "Added track to queue: \(track.title) (queue size: \(self.queue.count))"
        )
    }
    
    /// Remove a track from the playback queue
    /// - Parameter track: The track to remove
    public func removeFromQueue(_ track: Track) {
        queue.removeAll { $0.id == track.id }
        Logger.audio.debug(
            "Removed track from queue: \(track.title) (queue size: \(self.queue.count))"
        )
    }
    
    /// Clear the playback queue
    public func clearQueue() {
        queue.removeAll()
        Logger.audio.debug("Queue cleared")
    }
}
