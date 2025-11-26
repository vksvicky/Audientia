//
//  PlaybackCoordinator.swift
//  Audientia
//
//  Coordinates playback actions from track selection
//

import AudioCore
import Foundation
import os.log
import Shared

/// Errors that can occur during playback coordination
public enum PlaybackCoordinatorError: Error, LocalizedError, Equatable {
    case noTrackSelected

    public var errorDescription: String? {
        switch self {
        case .noTrackSelected:
            return "No track selected"
        }
    }
}

/// Coordinates playback actions from track selection to audio engine
@MainActor
public final class PlaybackCoordinator: ObservableObject {
    private let audioEngine: AudioEngineProtocol
    private let trackSelection: TrackSelectionStore
    private let logger = Logger.userInterface

    public init(
        audioEngine: AudioEngineProtocol,
        trackSelection: TrackSelectionStore
    ) {
        self.audioEngine = audioEngine
        self.trackSelection = trackSelection
    }

    /// Play the currently selected track
    /// - Throws: PlaybackCoordinatorError if no track is selected
    public func playSelectedTrack() async throws {
        guard let track = trackSelection.selectedTrack else {
            throw PlaybackCoordinatorError.noTrackSelected
        }

        logger.info("Playing selected track: \(track.title, privacy: .public)")
        try await audioEngine.loadTrack(track)
        try await audioEngine.play()
        logger.info("Track started playing")
    }

    /// Queue the currently selected track
    public func queueSelectedTrack() async {
        guard let track = trackSelection.selectedTrack else {
            logger.debug("No track selected for queueing")
            return
        }

        logger.info("Queueing selected track: \(track.title, privacy: .public)")
        audioEngine.addToQueue(track)
    }

    /// Queue multiple tracks
    /// - Parameter tracks: Tracks to queue
    public func queueTracks(_ tracks: [Track]) async {
        guard !tracks.isEmpty else { return }

        logger.info("Queueing \(tracks.count) tracks")
        for track in tracks {
            audioEngine.addToQueue(track)
        }
    }

    /// Play a specific track
    /// - Parameter track: Track to play
    /// - Throws: AudioEngineError if playback fails
    public func playTrack(_ track: Track) async throws {
        logger.info("Playing track: \(track.title, privacy: .public)")
        try await audioEngine.loadTrack(track)
        try await audioEngine.play()
    }

    /// Queue a specific track
    /// - Parameter track: Track to queue
    public func queueTrack(_ track: Track) {
        logger.info("Queueing track: \(track.title, privacy: .public)")
        audioEngine.addToQueue(track)
    }

    /// Pause playback
    public func pause() async {
        logger.info("Pausing playback")
        await audioEngine.pause()
    }

    /// Resume playback
    /// - Throws: AudioEngineError if resume fails
    public func resume() async throws {
        logger.info("Resuming playback")
        try await audioEngine.play()
    }

    /// Stop playback
    public func stop() async {
        logger.info("Stopping playback")
        await audioEngine.stop()
    }
}

