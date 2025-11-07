// AudioEngine.swift
// Audientia - Audio Playback Engine
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// FileSystemProtocol is defined in FileSystemProtocol.swift

/// Main audio playback engine
/// Handles track loading, playback control, queue management, and position tracking
@MainActor
// swiftlint:disable:next todo
// TODO: Refactor AudioEngine to reduce class body length (currently 351 lines, limit is 300)
// swiftlint:disable:next type_body_length
public final class AudioEngine: AudioEngineProtocol {
    
    // MARK: - Properties
    
    /// Current playback state
    public private(set) var state: PlaybackState = .stopped
    
    /// Currently loaded track
    public private(set) var currentTrack: Track?
    
    /// Current playback position in seconds
    public private(set) var currentPosition: TimeInterval = 0.0
    
    /// Track duration in seconds (prefers detected format metadata)
    public var duration: TimeInterval {
        if let detected = detectedFormat, detected.duration > 0 {
            return detected.duration
        }
        return currentTrack?.duration ?? 0.0
    }
    
    /// Playback progress (0.0 to 1.0)
    public var progress: Double {
        guard duration > 0 else { return 0.0 }
        return currentPosition / duration
    }
    
    /// Playback queue
    public private(set) var queue: [Track] = []
    
    /// Current volume (0.0 to 1.0)
    public var volume: Float = 1.0 {
        didSet {
            self.volume = max(0.0, min(1.0, self.volume))
            if !self.isMuted {
                // Apply volume to audio engine (when implemented)
                Logger.audio.debug("Volume set to \(self.volume)")
            }
        }
    }
    
    /// Is currently muted
    public var isMuted: Bool = false {
        didSet {
            if self.isMuted {
                self.previousVolume = self.volume
                self.volume = 0.0
            } else {
                self.volume = self.previousVolume
            }
            Logger.audio.debug("Mute state: \(self.isMuted)")
        }
    }
    
    /// Current loop mode
    public var loopMode: LoopMode = .none
    
    /// Convenience property: is engine playing?
    public var isPlaying: Bool {
        state == .playing
    }
    
    /// Convenience property: is engine paused?
    public var isPaused: Bool {
        state == .paused
    }
    
    /// Convenience property: is engine stopped?
    public var isStopped: Bool {
        state == .stopped
    }
    
    // MARK: - Private Properties
    
    private var positionUpdateTask: Task<Void, Never>?
    private let positionUpdateInterval: TimeInterval = 0.1 // Update every 100ms
    private let fileSystem: FileSystemProtocol
    private let formatCoordinator: FormatDecodingCoordinating
    private var currentQueueIndex: Int = -1 // Index of current track in queue history
    private var queueHistory: [Track] = [] // History of played tracks for previous navigation
    private var previousVolume: Float = 1.0 // Volume before muting
    
    // MARK: - Initialization
    
    /// Current detected audio format (if available)
    public private(set) var detectedFormat: DecodedAudioFormat?
    public private(set) var lastFormatDetectionError: Error?
    
    /// Initialize AudioEngine with default dependencies
    public init() {
        self.fileSystem = RealFileSystem()
        self.formatCoordinator = DefaultFormatDecodingCoordinator()
        Logger.audio.debug("AudioEngine initialized")
    }
    
    /// Initialize AudioEngine with custom dependencies (mainly for testing)
    /// - Parameters:
    ///   - fileSystem: File system abstraction
    ///   - formatCoordinator: Format decoder coordinator
    @MainActor
    init(
        fileSystem: FileSystemProtocol,
        formatCoordinator: FormatDecodingCoordinating = DefaultFormatDecodingCoordinator()
    ) {
        self.fileSystem = fileSystem
        self.formatCoordinator = formatCoordinator
        Logger.audio.debug("AudioEngine initialized with custom dependencies")
    }
    
    deinit {
        positionUpdateTask?.cancel()
        Logger.audio.debug("AudioEngine deinitialized")
    }
    
    // MARK: - Track Loading
    
    /// Load a track for playback
    /// - Parameter track: The track to load
    /// - Throws: AudioEngineError if loading fails
    public func loadTrack(_ track: Track) async throws {
        Logger.audio.info("Loading track: \(track.title)")
        
        state = .loading
        
        // Validate file exists
        guard fileSystem.fileExists(atPath: track.filePath) else {
            let error = AudioEngineError.trackLoadFailed("File not found: \(track.filePath)")
            state = .error(error.errorDescription ?? "File not found")
            Logger.audio.error("Failed to load track: \(error.localizedDescription)")
            throw error
        }
        
        // Attempt to decode format metadata (non-fatal on failure)
        do {
            let format = try await formatCoordinator.decodeFormat(for: track.filePath)
            detectedFormat = format
            lastFormatDetectionError = nil
            Logger.audio.info("Detected format: codec=\(format.codec) sampleRate=\(format.sampleRate)Hz")
        } catch {
            detectedFormat = nil
            lastFormatDetectionError = error
            Logger.audio.warning("Format detection failed: \(error.localizedDescription)")
        }
        
        // Reset position
        currentPosition = 0.0
        currentTrack = track
        
        state = .stopped
        
        Logger.audio.info("Track loaded successfully: \(track.title)")
    }
    
    // MARK: - Playback Control
    
    /// Start playback
    /// - Throws: AudioEngineError if playback cannot start
    public func play() async throws {
        // Check if queue has tracks but no current track
        if currentTrack == nil && !queue.isEmpty {
            let nextTrack = queue.removeFirst()
            try await loadTrack(nextTrack)
            // Track is now loaded, add to history
            queueHistory.append(nextTrack)
            currentQueueIndex = queueHistory.count - 1
        }
        
        guard let track = currentTrack else {
            // If no track is loaded, check if queue is empty
            if queue.isEmpty {
                throw AudioEngineError.queueEmpty
            } else {
                // This shouldn't happen as we load from queue above,
                // but handle it just in case
                throw AudioEngineError.noTrackLoaded
            }
        }
        
        Logger.audio.info("Starting playback: \(track.title)")
        
        // Start position tracking
        startPositionTracking()
        
        state = .playing
        Logger.audio.debug("Playback started")
    }
    
    /// Pause playback
    /// Made async to support concurrent operations and non-blocking I/O
    public func pause() async {
        guard state == .playing else {
            Logger.audio.debug("Pause called but not playing (state: \(String(describing: self.state)))")
            return
        }
        
        Logger.audio.info("Pausing playback")
        stopPositionTracking()
        state = .paused
    }
    
    /// Resume playback
    /// - Throws: AudioEngineError if resume fails
    public func resume() async throws {
        guard state == .paused else {
            if self.state == .stopped {
                throw AudioEngineError.noTrackLoaded
            }
            Logger.audio.debug("Resume called but not paused (state: \(String(describing: self.state)))")
            return
        }
        
        guard currentTrack != nil else {
            throw AudioEngineError.noTrackLoaded
        }
        
        Logger.audio.info("Resuming playback")
        startPositionTracking()
        state = .playing
    }
    
    /// Stop playback and reset position
    /// Made async to support concurrent operations and non-blocking I/O
    public func stop() async {
        Logger.audio.info("Stopping playback")
        stopPositionTracking()
        currentPosition = 0.0
        state = .stopped
    }
    
    // MARK: - Queue Management
    
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
    
    // MARK: - Seek and Position
    
    /// Seek to a specific position
    /// - Parameter position: Target position in seconds
    /// - Throws: AudioEngineError if seek fails
    public func seek(to position: TimeInterval) async throws {
        guard let track = currentTrack else {
            throw AudioEngineError.noTrackLoaded
        }
        
        // Clamp position to valid range
        let clampedPosition = max(0.0, min(position, track.duration))
        
        guard clampedPosition >= 0.0 && clampedPosition <= track.duration else {
            throw AudioEngineError.invalidSeekPosition
        }
        
        Logger.audio.debug("Seeking to position: \(clampedPosition)s")
        currentPosition = clampedPosition
    }
    
    /// Seek by a relative amount
    /// - Parameter offset: Amount to seek (positive = forward, negative = backward)
    /// - Throws: AudioEngineError if seek fails
    public func seek(by offset: TimeInterval) async throws {
        let newPosition = currentPosition + offset
        try await seek(to: newPosition)
    }
    
    // MARK: - Queue Navigation
    
    /// Play next track in queue
    /// - Throws: AudioEngineError if no next track available
    public func playNext() async throws {
        Logger.audio.info("Play next requested")
        
        // Check if we have a next track in queue
        if !queue.isEmpty {
            let nextTrack = queue.removeFirst()
            // Add current track to history if it exists
            if let current = currentTrack {
                queueHistory.append(current)
                currentQueueIndex = queueHistory.count - 1
            }
            try await loadTrack(nextTrack)
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
        
        // Update history and index
        currentQueueIndex = previousIndex
        try await loadTrack(previousTrack)
        try await play()
        Logger.audio.info("Went back to previous track: \(previousTrack.title)")
    }
    
    // MARK: - Volume Control
    
    /// Set volume level
    /// - Parameter volume: Volume level (0.0 to 1.0)
    public func setVolume(_ volume: Float) {
        self.volume = volume
    }
    
    /// Set muted state
    /// - Parameter muted: Whether to mute
    public func setMuted(_ muted: Bool) {
        self.isMuted = muted
    }
    
    /// Toggle mute state
    public func toggleMute() {
        isMuted.toggle()
    }
    
    // MARK: - Advanced Playback
    
    /// Replay current track from beginning
    /// - Throws: AudioEngineError if no track loaded
    public func replay() async throws {
        Logger.audio.info("Replay requested")
        guard currentTrack != nil else {
            throw AudioEngineError.noTrackLoaded
        }
        
        try await seek(to: 0.0)
        if state == .paused {
            try await resume()
        } else if state == .stopped {
            try await play()
        }
        Logger.audio.info("Track replayed from beginning")
    }
    
    /// Skip forward by specified seconds
    /// - Parameter seconds: Number of seconds to skip forward
    /// - Throws: AudioEngineError if seek fails
    public func skipForward(seconds: TimeInterval) async throws {
        let newPosition = min(currentPosition + seconds, duration)
        try await seek(to: newPosition)
        Logger.audio.debug("Skipped forward \(seconds) seconds")
    }
    
    /// Skip backward by specified seconds
    /// - Parameter seconds: Number of seconds to skip backward
    /// - Throws: AudioEngineError if seek fails
    public func skipBackward(seconds: TimeInterval) async throws {
        let newPosition = max(currentPosition - seconds, 0.0)
        try await seek(to: newPosition)
        Logger.audio.debug("Skipped backward \(seconds) seconds")
    }
    
    // MARK: - Loop Control
    
    /// Set loop mode
    /// - Parameter mode: Loop mode to set
    public func setLoopMode(_ mode: LoopMode) {
        self.loopMode = mode
        Logger.audio.debug("Loop mode set to: \(mode)")
    }
    
    /// Toggle loop mode (none -> track -> queue -> none)
    public func toggleLoopMode() {
        switch self.loopMode {
        case .none:
            self.loopMode = .track
        case .track:
            self.loopMode = .queue
        case .queue:
            self.loopMode = .none
        }
        Logger.audio.debug("Loop mode toggled to: \(self.loopMode)")
    }
    
    // MARK: - Position Tracking
    
    private func startPositionTracking() {
        stopPositionTracking()
        
        positionUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                if self.state == .playing {
                    self.currentPosition += self.positionUpdateInterval
                    
                    // Check if we've reached the end
                    if let track = self.currentTrack,
                       self.currentPosition >= track.duration {
                        // Auto-advance to next track or stop
                        await self.handleTrackCompletion()
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.positionUpdateInterval * 1_000_000_000))
            }
        }
    }
    
    private func stopPositionTracking() {
        positionUpdateTask?.cancel()
        positionUpdateTask = nil
    }
    
    // swiftlint:disable:next todo
    // TODO: Refactor handleTrackCompletion to reduce function body length (currently 51 lines, limit is 50)
    // swiftlint:disable:next function_body_length
    private func handleTrackCompletion() async {
        Logger.audio.info("Track completed, checking loop mode and queue")
        
        // Handle loop modes
        switch loopMode {
        case .track:
            // Replay current track
            if let track = currentTrack {
                do {
                    try await replay()
                    Logger.audio.info("Looped current track: \(track.title)")
                    return
                } catch {
                    Logger.audio.error("Failed to loop track: \(error.localizedDescription)")
                }
            }
            
        case .queue:
            // Check if we can loop to first track in history
            if !queueHistory.isEmpty {
                let firstTrack = queueHistory[0]
                queueHistory.removeAll()
                currentQueueIndex = -1
                do {
                    try await loadTrack(firstTrack)
                    queueHistory.append(firstTrack)
                    currentQueueIndex = 0
                    try await play()
                    Logger.audio.info("Looped to first track in queue")
                    return
                } catch {
                    Logger.audio.error("Failed to loop queue: \(error.localizedDescription)")
                }
            }
            
        case .none:
            break // Continue with normal completion handling
        }
        
        // Normal completion: advance to next track or stop
        if !self.queue.isEmpty {
            // Auto-advance to next track
            let nextTrack = self.queue.removeFirst()
            // Add current track to history
            if let current = self.currentTrack {
                self.queueHistory.append(current)
                self.currentQueueIndex = self.queueHistory.count - 1
            }
            do {
                try await self.loadTrack(nextTrack)
                self.queueHistory.append(nextTrack)
                self.currentQueueIndex = self.queueHistory.count - 1
                try await self.play()
                Logger.audio.info("Auto-advanced to next track: \(nextTrack.title)")
            } catch {
                Logger.audio.error("Failed to auto-advance to next track: \(error.localizedDescription)")
                self.state = .error(error.localizedDescription)
            }
        } else {
            // No more tracks, stop playback
            await self.stop()
            Logger.audio.info("Queue empty, stopping playback")
        }
    }
}
