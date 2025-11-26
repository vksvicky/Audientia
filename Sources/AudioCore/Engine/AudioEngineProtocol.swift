// AudioEngineProtocol.swift
// Audientia - Audio Engine Protocol
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import Shared

/// Protocol defining the interface for audio playback engines
/// Allows for dependency injection and testing with mock implementations
@MainActor
public protocol AudioEngineProtocol {
    /// Current playback state
    var state: PlaybackState { get }
    
    /// Currently loaded track
    var currentTrack: Track? { get }
    
    /// Current playback position in seconds
    var currentPosition: TimeInterval { get }
    
    /// Track duration in seconds
    var duration: TimeInterval { get }
    
    /// Playback queue
    var queue: [Track] { get }
    
    /// Load a track for playback
    /// - Parameter track: The track to load
    /// - Throws: AudioEngineError if loading fails
    func loadTrack(_ track: Track) async throws
    
    /// Start playback
    /// - Throws: AudioEngineError if playback cannot start
    func play() async throws
    
    /// Pause playback
    func pause() async
    
    /// Stop playback and reset position
    func stop() async
    
    /// Seek to a specific position
    /// - Parameter position: Position in seconds
    /// - Throws: AudioEngineError if seek fails
    func seek(to position: TimeInterval) async throws
    
    // MARK: - Queue Navigation
    
    /// Add a track to the playback queue
    /// - Parameter track: The track to add
    func addToQueue(_ track: Track)
    
    /// Remove a track from the playback queue
    /// - Parameter track: The track to remove
    func removeFromQueue(_ track: Track)
    
    /// Play next track in queue
    /// - Throws: AudioEngineError if no next track available
    func playNext() async throws
    
    /// Play previous track in queue
    /// - Throws: AudioEngineError if no previous track available
    func playPrevious() async throws
    
    // MARK: - Volume Control
    
    /// Current volume (0.0 to 1.0)
    var volume: Float { get set }
    
    /// Is currently muted
    var isMuted: Bool { get }
    
    /// Set volume level
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setVolume(_ volume: Float)
    
    /// Set muted state
    /// - Parameter muted: Whether to mute
    func setMuted(_ muted: Bool)
    
    /// Toggle mute state
    func toggleMute()
    
    // MARK: - Advanced Playback
    
    /// Replay current track from beginning
    /// - Throws: AudioEngineError if no track loaded
    func replay() async throws
    
    /// Skip forward by specified seconds
    /// - Parameter seconds: Number of seconds to skip forward
    /// - Throws: AudioEngineError if seek fails
    func skipForward(seconds: TimeInterval) async throws
    
    /// Skip backward by specified seconds
    /// - Parameter seconds: Number of seconds to skip backward
    /// - Throws: AudioEngineError if seek fails
    func skipBackward(seconds: TimeInterval) async throws
    
    // MARK: - Loop Control
    
    /// Current loop mode
    var loopMode: LoopMode { get set }
    
    /// Set loop mode
    /// - Parameter mode: Loop mode to set
    func setLoopMode(_ mode: LoopMode)
    
    /// Toggle loop mode (none -> track -> queue -> none)
    func toggleLoopMode()
}
