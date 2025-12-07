//
//  CAudioEngine.swift
//  AudioCore
//
//  Swift wrapper for C++ Audio Engine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Swift wrapper for C++ Audio Engine
/// Provides a Swift-friendly interface to the C++ audio engine
@MainActor
public final class CAudioEngine {
    
    // MARK: - Properties
    
    /// Current playback state
    public private(set) var state: PlaybackState = .stopped
    
    /// Current playback position in seconds
    public private(set) var currentPosition: TimeInterval = 0.0
    
    /// Track duration in seconds
    public private(set) var duration: TimeInterval = 0.0
    
    /// Playback volume (0.0 to 1.0)
    public var volume: Float {
        get {
            cppEngine.getVolume()
        }
        set {
            cppEngine.setVolume(newValue)
            updateState()
        }
    }
    
    /// Playback rate (0.5 to 2.0, higher rates may be clamped by AVAudioPlayer)
    public var rate: Float {
        get {
            cppEngine.getRate()
        }
        set {
            cppEngine.setRate(newValue)
        }
    }
    
    /// Convenience property: is engine playing?
    public var isPlaying: Bool {
        cppEngine.isPlaying()
    }
    
    /// Convenience property: is engine paused?
    public var isPaused: Bool {
        cppEngine.isPaused()
    }
    
    /// Convenience property: is engine stopped?
    public var isStopped: Bool {
        cppEngine.isStopped()
    }
    
    // MARK: - Private Properties
    
    private let cppEngine: CAudioEngineWrapper
    private var positionUpdateTask: Task<Void, Never>?
    private let positionUpdateInterval: TimeInterval = 0.1 // Update every 100ms
    
    // MARK: - Initialisation
    
    public init() {
        self.cppEngine = CAudioEngineWrapper()
        startPositionTracking()
    }
    
    deinit {
        positionUpdateTask?.cancel()
        cppEngine.stop()
    }
    
    // MARK: - Playback Control
    
    /// Load an audio file for playback
    /// - Parameter filePath: Path to the audio file
    /// - Returns: true if file loaded successfully
    /// - Note: This operation may perform blocking I/O, so it's async to avoid blocking the main thread
    public func loadFile(_ filePath: String) async -> Bool {
        // Run blocking I/O operation off the main actor
        // Note: AVAudioPlayer initialisation can block, so we run it in a detached task
        let success = await Task.detached {
            await self.cppEngine.loadFile(filePath)
        }.value
        
        // Update state on main actor
        if success {
            duration = cppEngine.getDuration()
            currentPosition = 0.0
            state = .stopped
        } else {
            state = .error("Failed to load file: \(filePath)")
        }
        return success
    }
    
    /// Start playback
    /// - Returns: true if playback started successfully
    @discardableResult
    public func play() async -> Bool {
        let success = cppEngine.play()
        if success {
            state = .playing
        }
        return success
    }
    
    /// Pause playback
    public func pause() {
        cppEngine.pause()
        state = .paused
    }
    
    /// Stop playback and reset position
    public func stop() {
        cppEngine.stop()
        currentPosition = 0.0
        state = .stopped
    }
    
    /// Seek to a specific position
    /// - Parameter position: Position in seconds
    /// - Returns: true if seek successful
    @discardableResult
    public func seek(to position: TimeInterval) async -> Bool {
        let success = cppEngine.seekTo(position)
        if success {
            currentPosition = position
        }
        return success
    }
    
    /// Set playback volume
    /// - Parameter volume: Volume level (0.0 to 1.0), will be clamped
    public func setVolume(_ volume: Float) {
        self.volume = volume
    }
    
    /// Set playback rate
    /// - Parameter rate: Playback rate multiplier
    public func setRate(_ rate: Float) {
        self.rate = rate
    }
    
    /// Get current playback rate
    public func getRate() -> Float {
        rate
    }
    
    // MARK: - Private Methods
    
    private func updateState() {
        if cppEngine.isPlaying() {
            state = .playing
        } else if cppEngine.isPaused() {
            state = .paused
        } else {
            state = .stopped
        }
    }
    
    private func startPositionTracking() {
        positionUpdateTask?.cancel()
        positionUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                self.currentPosition = self.cppEngine.getPosition()
                self.updateState()
                try? await Task.sleep(nanoseconds: UInt64(self.positionUpdateInterval * 1_000_000_000))
            }
        }
    }
}

// MARK: - C++ Bridge

/// C++ bridge wrapper using C interface
/// Nonisolated since it's just a thin wrapper around C functions
private nonisolated final class CAudioEngineWrapper {
    private let cppEngine: CAudioEngineRef
    
    init() {
        self.cppEngine = CAudioEngineCreate()
    }
    
    deinit {
        CAudioEngineDestroy(cppEngine)
    }
    
    func loadFile(_ filePath: String) -> Bool {
        filePath.withCString { cString in
            CAudioEngineLoadFile(cppEngine, cString) != 0
        }
    }
    
    func play() -> Bool {
        CAudioEnginePlay(cppEngine) != 0
    }
    
    func pause() {
        CAudioEnginePause(cppEngine)
    }
    
    func stop() {
        CAudioEngineStop(cppEngine)
    }
    
    func seekTo(_ position: TimeInterval) -> Bool {
        CAudioEngineSeekTo(cppEngine, position) != 0
    }
    
    func getPosition() -> TimeInterval {
        CAudioEngineGetPosition(cppEngine)
    }
    
    func getDuration() -> TimeInterval {
        CAudioEngineGetDuration(cppEngine)
    }
    
    func setVolume(_ volume: Float) {
        CAudioEngineSetVolume(cppEngine, volume)
    }
    
    func getVolume() -> Float {
        CAudioEngineGetVolume(cppEngine)
    }
    
    func setRate(_ rate: Float) {
        CAudioEngineSetRate(cppEngine, rate)
    }
    
    func getRate() -> Float {
        CAudioEngineGetRate(cppEngine)
    }
    
    func isPlaying() -> Bool {
        CAudioEngineIsPlaying(cppEngine) != 0
    }
    
    func isPaused() -> Bool {
        CAudioEngineIsPaused(cppEngine) != 0
    }
    
    func isStopped() -> Bool {
        CAudioEngineIsStopped(cppEngine) != 0
    }
}

// MARK: - NativeAudioEngineProtocol

extension CAudioEngine: NativeAudioEngineProtocol {}

// C interface declarations (implemented in CAudioEngineBridge.cpp)
typealias CAudioEngineRef = OpaquePointer

@_silgen_name("CAudioEngineCreate")
func CAudioEngineCreate() -> CAudioEngineRef

@_silgen_name("CAudioEngineDestroy")
func CAudioEngineDestroy(_ engine: CAudioEngineRef)

@_silgen_name("CAudioEngineLoadFile")
func CAudioEngineLoadFile(_ engine: CAudioEngineRef, _ filePath: UnsafePointer<CChar>) -> Int32

@_silgen_name("CAudioEnginePlay")
func CAudioEnginePlay(_ engine: CAudioEngineRef) -> Int32

@_silgen_name("CAudioEnginePause")
func CAudioEnginePause(_ engine: CAudioEngineRef)

@_silgen_name("CAudioEngineStop")
func CAudioEngineStop(_ engine: CAudioEngineRef)

@_silgen_name("CAudioEngineSeekTo")
func CAudioEngineSeekTo(_ engine: CAudioEngineRef, _ position: Double) -> Int32

@_silgen_name("CAudioEngineGetPosition")
func CAudioEngineGetPosition(_ engine: CAudioEngineRef) -> Double

@_silgen_name("CAudioEngineGetDuration")
func CAudioEngineGetDuration(_ engine: CAudioEngineRef) -> Double

@_silgen_name("CAudioEngineSetVolume")
func CAudioEngineSetVolume(_ engine: CAudioEngineRef, _ volume: Float)

@_silgen_name("CAudioEngineGetVolume")
func CAudioEngineGetVolume(_ engine: CAudioEngineRef) -> Float

@_silgen_name("CAudioEngineSetRate")
func CAudioEngineSetRate(_ engine: CAudioEngineRef, _ rate: Float)

@_silgen_name("CAudioEngineGetRate")
func CAudioEngineGetRate(_ engine: CAudioEngineRef) -> Float

@_silgen_name("CAudioEngineIsPlaying")
func CAudioEngineIsPlaying(_ engine: CAudioEngineRef) -> Int32

@_silgen_name("CAudioEngineIsPaused")
func CAudioEngineIsPaused(_ engine: CAudioEngineRef) -> Int32

@_silgen_name("CAudioEngineIsStopped")
func CAudioEngineIsStopped(_ engine: CAudioEngineRef) -> Int32
