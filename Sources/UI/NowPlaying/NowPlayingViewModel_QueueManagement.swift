//
//  NowPlayingViewModel_QueueManagement.swift
//  Audientia
//
//  Queue management extension for NowPlayingViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
import Shared

// MARK: - Queue Management Extension
extension NowPlayingViewModel {
    // MARK: - Queue Management

    /// Queue a track for playback
    /// - Parameter track: The track to queue
    public func queueTrack(_ track: Shared.Track) {
        audioEngine.addToQueue(track)
        updateState()
        Logger.userInterface.info("Queued track: \(track.title, privacy: .public)")
    }

    /// Queue multiple tracks for playback
    /// - Parameter tracks: The tracks to queue
    public func queueTracks(_ tracks: [Shared.Track]) {
        for track in tracks {
            audioEngine.addToQueue(track)
        }
        updateState()
        Logger.userInterface.info("Queued \(tracks.count) tracks")
    }

    /// Remove a track from the queue
    /// - Parameter track: The track to remove
    public func removeFromQueue(_ track: Shared.Track) {
        audioEngine.removeFromQueue(track)
        updateState()
        Logger.userInterface.info("Removed track from queue: \(track.title, privacy: .public)")
    }
}
