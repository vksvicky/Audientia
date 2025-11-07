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
public final class AudioEngine {
    
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
            let format = try formatCoordinator.decodeFormat(for: track.filePath)
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
    public func pause() {
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
    public func stop() {
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
    
    private func handleTrackCompletion() async {
        Logger.audio.info("Track completed, checking queue")
        
        if !self.queue.isEmpty {
            // Auto-advance to next track
            let nextTrack = self.queue.removeFirst()
            do {
                try await self.loadTrack(nextTrack)
                try await self.play()
                Logger.audio.info("Auto-advanced to next track: \(nextTrack.title)")
            } catch {
                Logger.audio.error("Failed to auto-advance to next track: \(error.localizedDescription)")
                self.state = .error(error.localizedDescription)
            }
        } else {
            // No more tracks, stop playback
            self.stop()
            Logger.audio.info("Queue empty, stopping playback")
        }
    }
}
