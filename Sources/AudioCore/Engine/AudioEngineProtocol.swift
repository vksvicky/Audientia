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
}
