//
//  NowPlayingViewModel_PlaybackControl.swift
//  Audientia
//
//  Playback control extension for NowPlayingViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
import Shared

// MARK: - Playback Control Extension
extension NowPlayingViewModel {
    // MARK: - Playback Control

    /// Pause playback
    public func pause() async {
        Logger.userInterface.info("Pause requested")
        await audioEngine.pause()
        updateState()
        Logger.userInterface.info("Playback paused")
    }

    /// Stop playback
    public func stop() async {
        Logger.userInterface.info("Stop requested")
        await audioEngine.stop()
        updateState()
        Logger.userInterface.info("Playback stopped")
    }

    /// Seek to a specific position
    /// - Parameter position: Position in seconds
    public func seek(to position: TimeInterval) async {
        let clampedPosition = max(0.0, min(position, duration))
        Logger.userInterface.info("Seek requested to \(clampedPosition, privacy: .public) seconds")

        do {
            try await audioEngine.seek(to: clampedPosition)
            updateState()
            Logger.userInterface.debug("Seek completed to \(clampedPosition, privacy: .public) seconds")
        } catch {
            lastError = error
            Logger.userInterface.error("Seek failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Play next track in queue
    public func playNext() async throws {
        Logger.userInterface.info("Play next requested")
        lastError = nil

        do {
            try await audioEngine.playNext()
            updateState()
            Logger.userInterface.info("Advanced to next track")
        } catch {
            lastError = error
            Logger.userInterface.error("Play next failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Play previous track in queue
    public func playPrevious() async throws {
        Logger.userInterface.info("Play previous requested")
        lastError = nil

        do {
            try await audioEngine.playPrevious()
            updateState()
            Logger.userInterface.info("Went back to previous track")
        } catch {
            lastError = error
            Logger.userInterface.error("Play previous failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Replay current track from beginning
    public func replay() async throws {
        Logger.userInterface.info("Replay requested")
        lastError = nil

        do {
            try await audioEngine.replay()
            updateState()
            Logger.userInterface.info("Track replayed")
        } catch {
            lastError = error
            Logger.userInterface.error("Replay failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Skip forward by specified seconds
    /// - Parameter seconds: Number of seconds to skip forward (default: 10)
    public func skipForward(seconds: TimeInterval = 10.0) async throws {
        Logger.userInterface.info("Skip forward requested")
        lastError = nil

        do {
            try await audioEngine.skipForward(seconds: seconds)
            updateState()
        } catch {
            lastError = error
            Logger.userInterface.error("Skip forward failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Skip backward by specified seconds
    /// - Parameter seconds: Number of seconds to skip backward (default: 10)
    public func skipBackward(seconds: TimeInterval = 10.0) async throws {
        Logger.userInterface.info("Skip backward requested")
        lastError = nil

        do {
            try await audioEngine.skipBackward(seconds: seconds)
            updateState()
        } catch {
            lastError = error
            Logger.userInterface.error("Skip backward failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
