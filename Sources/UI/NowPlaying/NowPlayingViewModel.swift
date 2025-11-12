// NowPlayingViewModel.swift
// Audientia - Now Playing ViewModel
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import AudioCore
import Combine
import Foundation
import os.log
import Shared

/// ViewModel for the Now Playing view
/// Manages playback state, track information, and user interactions
@MainActor
public final class NowPlayingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently playing track
    @Published public private(set) var currentTrack: Shared.Track?
    
    /// Current playback state
    @Published public private(set) var playbackState: PlaybackState = .stopped
    
    /// Current playback position in seconds
    @Published public private(set) var currentPosition: TimeInterval = 0.0
    
    /// Playback progress (0.0 to 1.0)
    @Published public private(set) var progress: Double = 0.0
    
    /// Current volume (0.0 to 1.0)
    @Published public var volume: Float = 1.0 {
        didSet {
            Task {
                await setVolume(volume)
            }
        }
    }
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    // MARK: - Computed Properties
    
    /// Is currently playing
    public var isPlaying: Bool {
        playbackState == .playing
    }
    
    /// Is currently paused
    public var isPaused: Bool {
        playbackState == .paused
    }
    
    /// Is currently stopped
    public var isStopped: Bool {
        playbackState == .stopped
    }
    
    /// Is currently loading
    public var isLoading: Bool {
        if case .loading = playbackState {
            return true
        }
        return false
    }
    
    /// Track duration in seconds
    public var duration: TimeInterval {
        audioEngine.duration
    }
    
    // MARK: - Private Properties
    
    private let audioEngine: AudioEngineProtocol
    private var cancellables = Set<AnyCancellable>()
    private var positionUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initialize with AudioEngine
    /// - Parameter audioEngine: The audio engine to control
    public init(audioEngine: AudioEngineProtocol) {
        self.audioEngine = audioEngine
        setupObservers()
        Logger.userInterface.info("NowPlayingViewModel initialized")
    }
    
    /// Convenience initializer that creates a default AudioEngine
    /// This initializer must be called from the main actor
    public convenience init() {
        // Create AudioEngine on the main actor
        let engine = AudioEngine()
        self.init(audioEngine: engine)
    }
    
    deinit {
        positionUpdateTask?.cancel()
        Logger.userInterface.debug("NowPlayingViewModel deinitialized")
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe audio engine state changes
        // Note: AudioEngine doesn't use Combine, so we'll use a polling approach
        // or add Combine support to AudioEngine in the future
        
        // Start position tracking
        startPositionTracking()
    }
    
    private func startPositionTracking() {
        positionUpdateTask?.cancel()
        positionUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.updateState()
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }
    
    // MARK: - State Updates
    
    /// Update state from audio engine
    /// This is a synchronous operation that reads current state
    public func updateState() {
        currentTrack = audioEngine.currentTrack
        playbackState = audioEngine.state
        currentPosition = audioEngine.currentPosition
        
        // Calculate progress
        let duration = self.duration
        if duration > 0 {
            progress = currentPosition / duration
        } else {
            progress = 0.0
        }
        
        // Clamp progress to valid range
        progress = max(0.0, min(1.0, progress))
    }
    
    // MARK: - Playback Control
    
    /// Load a track for playback
    /// - Parameter track: The track to load
    public func loadTrack(_ track: Shared.Track) async throws {
        Logger.userInterface.info("Loading track: \(track.title, privacy: .public)")
        lastError = nil
        
        do {
            try await audioEngine.loadTrack(track)
            updateState()
            Logger.userInterface.info("Track loaded successfully: \(track.title, privacy: .public)")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to load track: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
    /// Start or resume playback
    public func play() async throws {
        Logger.userInterface.info("Play requested")
        lastError = nil
        
        do {
            try await audioEngine.play()
            updateState()
            Logger.userInterface.info("Playback started")
        } catch {
            lastError = error
            Logger.userInterface.error("Playback failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
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
    
    /// Set volume
    /// - Parameter volume: Volume level (0.0 to 1.0)
    private func setVolume(_ volume: Float) async {
        let clampedVolume = max(0.0, min(1.0, volume))
        audioEngine.setVolume(clampedVolume)
        updateState()
        Logger.userInterface.debug("Volume changed to \(clampedVolume, privacy: .public)")
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
    
    /// Toggle mute state
    public func toggleMute() {
        audioEngine.toggleMute()
        updateState()
        Logger.userInterface.info("Mute toggled: \(self.audioEngine.isMuted, privacy: .public)")
    }
    
    /// Toggle loop mode
    public func toggleLoopMode() {
        audioEngine.toggleLoopMode()
        updateState()
        Logger.userInterface.info("Loop mode toggled: \(self.audioEngine.loopMode, privacy: .public)")
    }
    
    /// Current loop mode
    public var loopMode: LoopMode {
        audioEngine.loopMode
    }
    
    /// Is currently muted
    public var isMuted: Bool {
        audioEngine.isMuted
    }
}
