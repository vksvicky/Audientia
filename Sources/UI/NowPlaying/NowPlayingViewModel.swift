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
    
    /// Current playback speed
    @Published public var playbackSpeed: PlaybackSpeed = .normal {
        didSet {
            Task {
                await setPlaybackSpeed(playbackSpeed)
            }
        }
    }
    
    /// Last error that occurred
    @Published public internal(set) var lastError: Error?
    
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
    
    /// Playback queue
    @Published public private(set) var queue: [Shared.Track] = []
    
    /// Audio engine's visualiser for real-time spectrum analysis
    public var visualiser: AudioVisualiserProtocol {
        audioEngine.visualiser
    }
    
    // MARK: - Private Properties
    
    internal let audioEngine: AudioEngineProtocol
    private var cancellables = Set<AnyCancellable>()
    private var positionUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialisation
    
    /// Initialise with AudioEngine
    /// - Parameter audioEngine: The audio engine to control
    public init(audioEngine: AudioEngineProtocol) {
        self.audioEngine = audioEngine
        
        // Load saved playback speed from AppSettings and sync with engine
        if let engine = audioEngine as? AudioEngine {
            self.playbackSpeed = engine.playbackSpeed
        } else {
            self.playbackSpeed = AppSettings.shared.playbackSpeed
        }
        
        setupObservers()
        restoreLastPlayedTrack()
        Logger.userInterface.info("NowPlayingViewModel initialised")
    }
    
    /// Convenience initialiser that creates a default AudioEngine
    /// This initialiser must be called from the main actor
    public convenience init() {
        // Create AudioEngine on the main actor
        let engine = AudioEngine()
        self.init(audioEngine: engine)
    }
    
    deinit {
        positionUpdateTask?.cancel()
        Logger.userInterface.debug("NowPlayingViewModel deinitialised")
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe audio engine state changes
        // Note: AudioEngine doesn't use Combine, so we'll use a polling approach
        // or add Combine support to AudioEngine in the future
        
        // Start position tracking
        startPositionTracking()
    }
    
    /// Restore the last played track from AppSettings (if available and file still exists)
    private func restoreLastPlayedTrack() {
        guard let lastTrack = AppSettings.shared.lastPlayedTrack else {
            Logger.userInterface.debug("No last played track to restore")
            return
        }
        
        // Verify the file still exists before attempting to load
        guard FileManager.default.fileExists(atPath: lastTrack.filePath) else {
            Logger.userInterface.warning(
                "Last played track file no longer exists: \(lastTrack.filePath, privacy: .public)"
            )
            // Show notification to user that file is missing
            Task {
                await FileNotFoundNotificationHelper.showFileNotFoundNotification(
                    trackTitle: lastTrack.title,
                    filePath: lastTrack.filePath
                )
            }
            // Clear the saved track since the file is gone
            AppSettings.shared.lastPlayedTrack = nil
            return
        }
        
        // Load the track asynchronously (but don't auto-play)
        Task {
            do {
                try await loadTrack(lastTrack)
                Logger.userInterface.info(
                    "Restored last played track: \(lastTrack.title, privacy: .public)"
                )
            } catch {
                Logger.userInterface.error(
                    "Failed to restore last played track: \(error.localizedDescription, privacy: .public)"
                )
                // Show notification if file is missing
                if let audioError = error as? AudioEngineError,
                   case .trackLoadFailed(let message) = audioError,
                   message.contains("File not found") {
                    await FileNotFoundNotificationHelper.showFileNotFoundNotification(
                        trackTitle: lastTrack.title,
                        filePath: lastTrack.filePath
                    )
                }
                // Clear the saved track if loading failed
                AppSettings.shared.lastPlayedTrack = nil
            }
        }
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
        queue = audioEngine.queue
        
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
        
        // Verify file exists before attempting to load
        guard FileManager.default.fileExists(atPath: track.filePath) else {
            let error = AudioEngineError.trackLoadFailed("File not found: \(track.filePath)")
            lastError = error
            Logger.userInterface.error(
                "Track file not found: \(track.filePath, privacy: .public)"
            )
            // Show notification to user
            await FileNotFoundNotificationHelper.showFileNotFoundNotification(
                trackTitle: track.title,
                filePath: track.filePath
            )
            throw error
        }
        
        do {
            try await audioEngine.loadTrack(track)
            updateState()
            Logger.userInterface.info("Track loaded successfully: \(track.title, privacy: .public)")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to load track: \(error.localizedDescription, privacy: .public)")
            
            // Show notification if file is missing
            if let audioError = error as? AudioEngineError,
               case .trackLoadFailed(let message) = audioError,
               message.contains("File not found") {
                await FileNotFoundNotificationHelper.showFileNotFoundNotification(
                    trackTitle: track.title,
                    filePath: track.filePath
                )
            }
            throw error
        }
    }
    
    /// Start or resume playback
    public func play() async throws {
        Logger.userInterface.info("Play requested")
        lastError = nil
        
        // If we have a current track, verify file still exists before playing
        if let track = currentTrack {
            guard FileManager.default.fileExists(atPath: track.filePath) else {
                let error = AudioEngineError.trackLoadFailed("File not found: \(track.filePath)")
                lastError = error
                Logger.userInterface.error(
                    "Track file not found when trying to play: \(track.filePath, privacy: .public)"
                )
                // Show notification to user
                await FileNotFoundNotificationHelper.showFileNotFoundNotification(
                    trackTitle: track.title,
                    filePath: track.filePath
                )
                // Clear the current track since file is missing
                // Note: We clear it on the view model, but the audio engine may still have it
                // Tests should clear it on the mock engine before calling updateState()
                currentTrack = nil
                throw error
            }
        }
        
        do {
            try await audioEngine.play()
            updateState()
            Logger.userInterface.info("Playback started")
        } catch {
            lastError = error
            Logger.userInterface.error("Playback failed: \(error.localizedDescription, privacy: .public)")
            
            // Show notification if file is missing
            if let track = currentTrack,
               let audioError = error as? AudioEngineError,
               case .trackLoadFailed(let message) = audioError,
               message.contains("File not found") {
                await FileNotFoundNotificationHelper.showFileNotFoundNotification(
                    trackTitle: track.title,
                    filePath: track.filePath
                )
            }
            throw error
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
    
    /// Set playback speed
    /// - Parameter speed: Playback speed to set
    private func setPlaybackSpeed(_ speed: PlaybackSpeed) async {
        if let engine = audioEngine as? AudioEngine {
            engine.playbackSpeed = speed
            // Save to AppSettings
            AppSettings.shared.playbackSpeed = speed
            updateState()
            Logger.userInterface.debug("Playback speed changed to \(speed.displayName, privacy: .public)")
        }
    }
    
    /// Toggle mute state
    public func toggleMute() {
        audioEngine.toggleMute()
        updateState()
        // Note: AudioEngine.isMuted didSet already logs "Mute state:", so we don't need to log here
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
    
    /// Is shuffle enabled
    public var isShuffleEnabled: Bool {
        audioEngine.isShuffleEnabled
    }
    
    /// Is gain control enabled
    public var isGainControlEnabled: Bool {
        AppSettings.shared.isGainControlEnabled
    }
    
    /// Toggle shuffle mode
    public func toggleShuffle() {
        audioEngine.toggleShuffle()
        updateState()
        Logger.userInterface.info("Shuffle toggled: \(self.audioEngine.isShuffleEnabled, privacy: .public)")
    }
    
    /// Toggle gain control
    public func toggleGainControl() {
        AppSettings.shared.isGainControlEnabled.toggle()
        
        // If disabling, set global gain to 0 dB to remove effect
        if !AppSettings.shared.isGainControlEnabled {
            Task {
                if let engine = audioEngine as? AudioEngine {
                    // Access gain control through engine and set to 0 dB
                    // Note: This requires accessing the internal gainControl
                    // For now, we'll refresh the gain which will apply the 0 dB if disabled
                    await engine.refreshGain()
                }
            }
        } else {
            // If enabling, refresh gain to apply saved settings
            Task {
                if let engine = audioEngine as? AudioEngine {
                    await engine.refreshGain()
                }
            }
        }
        
        Logger.userInterface.info("Gain control toggled: \(AppSettings.shared.isGainControlEnabled, privacy: .public)")
    }
}
