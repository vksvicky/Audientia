// AudioEngine.swift
// Audientia - Audio Playback Engine
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import AVFoundation
import Foundation
import os.log
import Shared

// Import AudioVisualiser for visualisation support
// Note: AudioVisualiser is in the AudioCore module

// FileSystemProtocol is defined in FileSystemProtocol.swift

/// Main audio playback engine
/// Handles track loading, playback control, queue management, and position tracking
@MainActor
public final class AudioEngine: AudioEngineProtocol {
    
    // MARK: - Properties
    
    /// Current playback state
    public internal(set) var state: PlaybackState = .stopped
    
    /// Currently loaded track
    public private(set) var currentTrack: Track?
    
    /// Current playback position in seconds
    public internal(set) var currentPosition: TimeInterval = 0.0
    
    /// Track duration in seconds (prefers native or detected metadata)
    public var duration: TimeInterval {
        // If we have detected format metadata, prefer that (most accurate)
        // But only if it's non-zero - zero duration from format detection might be a default
        if let detected = detectedFormat, detected.duration > 0 {
            return detected.duration
        }
        // If track has an explicit duration (including 0.0), use it
        // Track metadata is authoritative, even for zero-duration tracks
        if let track = currentTrack {
            return track.duration
        }
        // Last resort: use native engine's duration if available
        if nativeEngine.duration > 0 {
            return nativeEngine.duration
        }
        return 0.0
    }
    
    /// Playback progress (0.0 to 1.0)
    public var progress: Double {
        guard duration > 0 else { return 0.0 }
        return currentPosition / duration
    }
    
    /// Playback queue
    public internal(set) var queue: [Track] = []
    
    /// Current volume (0.0 to 1.0)
    public var volume: Float = 1.0 {
        didSet {
            let clamped = max(0.0, min(1.0, volume))
            if clamped != volume {
                volume = clamped
                return
            }
            applyVolumeWithGain(baseVolume: clamped)
        }
    }
    
    /// Apply volume with gain control (if available)
    /// - Parameter baseVolume: Base volume (0.0 to 1.0)
    private func applyVolumeWithGain(baseVolume: Float) {
        // CRITICAL: If muted, always set volume to 0 regardless of base volume or gain
        if isMuted {
            let mutedMessage = "MUTED: Setting native engine volume to 0.0 " +
                "(isMuted=\(self.isMuted), baseVolume=\(baseVolume))"
            Logger.audio.info("\(mutedMessage)")
            nativeEngine.setVolume(0.0)
            Logger.audio.debug("Volume set to 0.0 (muted)")
            return
        }
        
        // Check if gain control is enabled in settings
        let gainMultiplier = AppSettings.shared.isGainControlEnabled ? currentGainMultiplier : 1.0
        
        // Calculate effective volume
        // Apply gain as a multiplier to the base volume
        let effectiveVolume = baseVolume * gainMultiplier
        
        // Clamp to valid range (0.0 to 1.0) to prevent clipping
        let clampedVolume = max(0.0, min(1.0, effectiveVolume))
        
        // Warn if gain is being clamped (user won't hear the full gain effect)
        if AppSettings.shared.isGainControlEnabled && effectiveVolume > 1.0 {
            let gainDB = gainControl?.linearToGainDB(gainMultiplier) ?? 0.0
            let gainDBStr = String(format: "%.2f", gainDB)
            let multiplierStr = String(format: "%.4f", gainMultiplier)
            let suggestedVolume = String(format: "%.2f", 1.0 / gainMultiplier)
            let warningMessage = "Gain \(gainDBStr) dB (multiplier \(multiplierStr)) would cause " +
                "volume to exceed maximum. Clamping to 1.0. Reduce base volume to " +
                "\(suggestedVolume) to hear full gain effect."
            Logger.audio.warning("\(warningMessage)")
        }
        
        let volumeInfoMessage = "Setting native engine volume to \(clampedVolume) " +
            "(baseVolume=\(baseVolume), gainMultiplier=\(gainMultiplier), isMuted=\(self.isMuted))"
        Logger.audio.info("\(volumeInfoMessage)")
        nativeEngine.setVolume(clampedVolume)
        
        if AppSettings.shared.isGainControlEnabled {
            // Calculate effective gain in dB for logging
            let effectiveGainDB: Float
            if let gainControl = gainControl {
                effectiveGainDB = gainControl.linearToGainDB(gainMultiplier)
            } else {
                effectiveGainDB = 0.0
            }
            let multiplierStr = String(format: "%.4f", gainMultiplier)
            let gainDBStr = String(format: "%.2f", effectiveGainDB)
            let volumeStr = String(format: "%.4f", clampedVolume)
            let volumeDebugMessage = "Volume set to \(baseVolume), gain enabled: multiplier=\(multiplierStr) " +
                "(\(gainDBStr) dB), effective volume: \(volumeStr)"
            Logger.audio.debug("\(volumeDebugMessage)")
        } else {
            let volumeStr = String(format: "%.4f", clampedVolume)
            Logger.audio.debug("Volume set to \(baseVolume), gain disabled, effective volume: \(volumeStr)")
        }
    }
    
    /// Update cached gain multiplier when track loads or gain changes
    /// NOTE: This only updates volume, it does NOT trigger playback or load tracks
    internal func updateGainMultiplier() async {
        // CRITICAL: This method only updates volume/gain settings
        // It must NEVER call play(), loadTrack(), or any method that starts playback
        if let gainControl = gainControl, let track = currentTrack, AppSettings.shared.isGainControlEnabled {
            let effectiveGain = await gainControl.getEffectiveGain(for: track)
            currentGainMultiplier = gainControl.gainDBToLinear(effectiveGain)
            let gainStr = String(format: "%.2f", effectiveGain)
            let multiplierStr = String(format: "%.4f", currentGainMultiplier)
            Logger.audio.debug(
                "Gain multiplier updated: effective gain=\(gainStr) dB, multiplier=\(multiplierStr)"
            )
            // Reapply volume with new gain (this only updates volume, not playback state)
            applyVolumeWithGain(baseVolume: volume)
        } else {
            currentGainMultiplier = 1.0
            if !AppSettings.shared.isGainControlEnabled {
                Logger.audio.debug("Gain control disabled, using unity gain multiplier (1.0)")
            } else {
                Logger.audio.debug("No gain control or track available, using unity gain multiplier (1.0)")
            }
            // Reapply volume without gain (this only updates volume, not playback state)
            applyVolumeWithGain(baseVolume: volume)
        }
    }
    
    /// Is currently muted
    public var isMuted: Bool = false {
        didSet {
            if self.isMuted {
                self.previousVolume = self.volume
                // Set volume to 0 - applyVolumeWithGain will respect isMuted and set native engine to 0
                self.volume = 0.0
                // CRITICAL: Also mute the visualiser tap's audio engine
                // The visualiser tap has its own AVAudioEngine connected to output, so it needs to be muted too
                visualiserTap?.volume = 0.0
            } else {
                // Restore previous volume, which will trigger volume didSet and update native engine
                self.volume = self.previousVolume
                // Restore visualiser tap volume (use a reasonable default for visualization)
                visualiserTap?.volume = 1.0
            }
            Logger.audio.debug("Mute state: \(self.isMuted)")
        }
    }
    
    /// Current playback speed
    public var playbackSpeed: PlaybackSpeed = .normal {
        didSet {
            // Apply rate immediately, even if track is already playing
            let rate = Float(self.playbackSpeed.rawValue)
            nativeEngine.setRate(rate)
            Logger.audio.debug("Playback speed set to \(self.playbackSpeed.displayName) (rate: \(rate))")
            
            // Note: AVAudioPlayer supports rates 0.5-2.0 natively
            // For rates > 2.0 (double, quadruple), the rate will be clamped to 2.0
            // This is a limitation of AVAudioPlayer - higher rates require time pitch algorithm
            if self.playbackSpeed.rawValue > 2.0 {
                Logger.audio.warning(
                    "Playback speed \(self.playbackSpeed.displayName) exceeds AVAudioPlayer limit, will be clamped"
                )
            }
        }
    }
    
    /// Current loop mode
    public var loopMode: LoopMode = .none
    
    /// Is shuffle mode enabled
    public var isShuffleEnabled: Bool = false
    
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
    
    internal var positionUpdateTask: Task<Void, Never>?
    internal let positionUpdateInterval: TimeInterval = 0.1 // Update every 100ms
    private let fileSystem: FileSystemProtocol
    private let formatCoordinator: FormatDecodingCoordinating
    let nativeEngine: NativeAudioEngineProtocol
    var currentQueueIndex: Int = -1 // Index of current track in queue history
    var queueHistory: [Track] = [] // History of played tracks for previous navigation
    private var previousVolume: Float = 1.0 // Volume before muting
    var visualiserTap: AudioVisualiserTap?
    
    /// Audio visualiser for real-time spectrum analysis
    public let visualiser: AudioVisualiserProtocol
    
    /// Audio gain control (optional)
    internal let gainControl: AudioGainControlProtocol?
    
    /// Audio normaliser (optional)
    internal let normaliser: AudioNormalisationProtocol?
    
    /// Current gain multiplier (cached for synchronous volume updates)
    private var currentGainMultiplier: Float = 1.0
    
    // MARK: - Initialisation
    
    /// Current detected audio format (if available)
    public private(set) var detectedFormat: DecodedAudioFormat?
    public private(set) var lastFormatDetectionError: Error?
    
    /// Initialise AudioEngine with default dependencies
    public init() {
        self.fileSystem = RealFileSystem()
        self.formatCoordinator = DefaultFormatDecodingCoordinator()
        self.nativeEngine = CAudioEngine()
        let visualiserInstance = AudioVisualiser()
        self.visualiser = visualiserInstance
        // Use processingRate from visualiser config to reduce CPU usage
        let processingRate = visualiserInstance.currentConfig.processingRate
        self.visualiserTap = AudioVisualiserTap(visualiser: self.visualiser, processingRate: processingRate)
        self.gainControl = AudioGainControl()
        self.normaliser = AudioNormaliser()
        
        // Load saved playback speed from AppSettings
        let savedSpeed = AppSettings.shared.playbackSpeed
        self.playbackSpeed = savedSpeed
        
        Logger.audio.debug("AudioEngine initialised with playback speed: \(savedSpeed.displayName)")
        
        // Observe gain changes from external sources (e.g., AudioGainControlView)
        NotificationCenter.default.addObserver(
            forName: .audioGainChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshGain()
            }
        }
    }
    
    /// Initialise AudioEngine with custom dependencies (mainly for testing)
    /// - Parameters:
    ///   - fileSystem: File system abstraction
    ///   - formatCoordinator: Format decoder coordinator
    ///   - nativeEngine: Native audio engine protocol
    ///   - visualiser: Audio visualiser protocol (optional)
    ///   - gainControl: Audio gain control protocol (optional)
    ///   - normaliser: Audio normaliser protocol (optional)
    @MainActor
    init(
        fileSystem: FileSystemProtocol,
        formatCoordinator: FormatDecodingCoordinating = DefaultFormatDecodingCoordinator(),
        nativeEngine: NativeAudioEngineProtocol,
        visualiser: AudioVisualiserProtocol? = nil,
        gainControl: AudioGainControlProtocol? = nil,
        normaliser: AudioNormalisationProtocol? = nil
    ) {
        self.fileSystem = fileSystem
        self.formatCoordinator = formatCoordinator
        self.nativeEngine = nativeEngine
        self.visualiser = visualiser ?? AudioVisualiser()
        self.gainControl = gainControl
        self.normaliser = normaliser
        Logger.audio.debug("AudioEngine initialised with custom dependencies")
    }
    
    @MainActor
    convenience init(
        fileSystem: FileSystemProtocol,
        formatCoordinator: FormatDecodingCoordinating = DefaultFormatDecodingCoordinator()
    ) {
        self.init(
            fileSystem: fileSystem,
            formatCoordinator: formatCoordinator,
            nativeEngine: CAudioEngine()
        )
    }
    
    deinit {
        positionUpdateTask?.cancel()
        Logger.audio.debug("AudioEngine deinitialised")
    }
    
    // MARK: - Track Loading
    
    /// Load a track for playback
    /// - Parameter track: The track to load
    /// - Throws: AudioEngineError if loading fails
    public func loadTrack(_ track: Track) async throws {
        Logger.audio.info("Loading track: \(track.title)")
        
        // Stop any current playback before loading a new track to prevent overlapping
        if state == .playing || state == .paused {
            Logger.audio.debug("Stopping current playback before loading new track")
            stopPositionTracking()
            visualiserTap?.stop()
            nativeEngine.stop()
            currentPosition = 0.0
        }
        
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
        
        // Reset position - attempt to load into native engine
        let formatDetectionFailed = detectedFormat == nil && lastFormatDetectionError != nil
        let nativeLoadSucceeded = await nativeEngine.loadFile(track.filePath)
        
        if !nativeLoadSucceeded {
            try handleNativeLoadFailure(
                track: track,
                formatDetectionFailed: formatDetectionFailed
            )
        }
        
        currentPosition = nativeEngine.currentPosition
        currentTrack = track
        
        // Update gain multiplier for new track
        await updateGainMultiplier()
        
        // Setup audio tap for visualisation if available
        // This provides real-time audio data for the visualiser
        if visualiserTap?.setupAudioEngine(filePath: track.filePath) == true {
            Logger.audio.debug("Audio visualiser tap installed for: \(track.title)")
        }
        
        state = .stopped
        
        Logger.audio.info("Track loaded successfully: \(track.title)")
    }
    
    /// Handle native engine load failure
    private func handleNativeLoadFailure(
        track: Track,
        formatDetectionFailed: Bool
    ) throws {
        if formatDetectionFailed {
            // For invalid files, allow the track to be "loaded" but with errors
        currentPosition = 0.0
            currentTrack = track
            state = .error("Format detection and native engine load both failed")
            Logger.audio.warning(
                "Track loaded with errors (format detection and native engine both failed): \(track.title)"
            )
        } else {
            // Format detection succeeded but native engine failed - this is a real error
            let error = AudioEngineError.trackLoadFailed("Unable to open audio file: \(track.filePath)")
            state = .error(error.errorDescription ?? "File not found")
            Logger.audio.error("Failed to load track: \(error.localizedDescription)")
            throw error
        }
    }
    
}
