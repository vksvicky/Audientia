//
//  MockDSPComponents.swift
//  Audientia - UI Test Infrastructure
//
//  Mock implementations of DSP components for UI testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

@testable import AudioCore
@testable import Shared

// MARK: - Mock AudioEqualiser

@MainActor
final class MockAudioEqualiser: AudioEqualiserProtocol {
    var bands: [EqualiserBand] = []
    var isEnabled: Bool = true
    var setBandGainCalled = false
    var resetCalled = false
    var setEnabledCalled = false
    var processCalled = false
    
    var shouldFailSetBandGain = false
    var shouldFailProcess = false
    
    init() {
        // Initialise with standard 10-band frequencies
        let frequencies: [Float] = [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]
        bands = frequencies.map { EqualiserBand(frequency: $0, gain: 0.0, qualityFactor: 1.0) }
    }
    
    func getBands() async -> [EqualiserBand] {
        bands
    }
    
    func setBandGain(_ bandIndex: Int, gain: Float) async throws {
        setBandGainCalled = true
        if shouldFailSetBandGain {
            throw AudioEqualiserError.invalidBandIndex(bandIndex)
        }
        guard bandIndex >= 0 && bandIndex < bands.count else {
            throw AudioEqualiserError.invalidBandIndex(bandIndex)
        }
        bands[bandIndex] = EqualiserBand(
            frequency: bands[bandIndex].frequency,
            gain: gain,
            qualityFactor: bands[bandIndex].qualityFactor
        )
    }
    
    func getBandGain(_ bandIndex: Int) async throws -> Float {
        guard bandIndex >= 0 && bandIndex < bands.count else {
            throw AudioEqualiserError.invalidBandIndex(bandIndex)
        }
        return bands[bandIndex].gain
    }
    
    func reset() async {
        resetCalled = true
        bands = bands.map { EqualiserBand(frequency: $0.frequency, gain: 0.0, qualityFactor: $0.qualityFactor) }
    }
    
    func process(audioData: [Float], sampleRate: Int, channels: Int) async throws -> [Float] {
        processCalled = true
        if shouldFailProcess {
            throw AudioEqualiserError.processingFailed("Mock processing failure")
        }
        return audioData // Return unchanged for mock
    }
    
    func isEnabled() async -> Bool {
        isEnabled
    }
    
    func setEnabled(_ enabled: Bool) async {
        setEnabledCalled = true
        isEnabled = enabled
    }
}

// MARK: - Mock AudioGainControl

final class MockAudioGainControl: AudioGainControlProtocol, @unchecked Sendable {
    var globalGain: Float = 0.0
    var trackGains: [UUID: Float] = [:]
    
    var setGlobalGainCalled = false
    var setTrackGainCalled = false
    var removeTrackGainCalled = false
    
    func getTrackGain(for track: Track) async -> Float? {
        trackGains[track.id]
    }
    
    func setTrackGain(_ gain: Float, for track: Track) async {
        setTrackGainCalled = true
        trackGains[track.id] = gain
    }
    
    func removeTrackGain(for track: Track) async {
        removeTrackGainCalled = true
        trackGains.removeValue(forKey: track.id)
    }
    
    func getGlobalGain() async -> Float {
        globalGain
    }
    
    func setGlobalGain(_ gain: Float) async {
        setGlobalGainCalled = true
        globalGain = gain
    }
    
    func getEffectiveGain(for track: Track) async -> Float {
        let trackGain = trackGains[track.id] ?? 0.0
        return globalGain + trackGain
    }
    
    func gainDBToLinear(_ gainDB: Float) -> Float {
        pow(10.0, gainDB / 20.0)
    }
    
    func linearToGainDB(_ linear: Float) -> Float {
        20.0 * log10(max(linear, 0.0001))
    }
}

// MARK: - Mock AudioNormaliser

@MainActor
final class MockAudioNormaliser: AudioNormalisationProtocol {
    var mode: NormalizationMode = .peak
    var targetLevel: Float = -3.0
    
    var analyzeCalled = false
    var applyCalled = false
    
    var shouldFailAnalyze = false
    var shouldFailApply = false
    
    func analyzeNormalization(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        mode: NormalizationMode,
        targetLevel: Float
    ) async throws -> Float {
        analyzeCalled = true
        if shouldFailAnalyze {
            throw AudioNormalisationError.analysisFailed("Mock analysis failure")
        }
        // Return mock gain adjustment
        return -3.0
    }
    
    func applyNormalization(
        audioData: [Float],
        gainDB: Float
    ) async throws -> [Float] {
        applyCalled = true
        if shouldFailApply {
            throw AudioNormalisationError.normalizationFailed("Mock application failure")
        }
        let multiplier = pow(10.0, gainDB / 20.0)
        return audioData.map { $0 * multiplier }
    }
    
    func calculatePeakLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float {
        guard let max = audioData.max() else { return -Float.infinity }
        return 20.0 * log10(abs(max))
    }
    
    func calculateRMSLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float {
        guard !audioData.isEmpty else { return -Float.infinity }
        let sumOfSquares = audioData.reduce(0.0) { $0 + $1 * $1 }
        let meanSquare = sumOfSquares / Float(audioData.count)
        return 20.0 * log10(sqrt(meanSquare))
    }
    
    func calculateLoudness(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> Float {
        if shouldFailAnalyze {
            throw AudioNormalisationError.analysisFailed("Mock loudness calculation failure")
        }
        // Return mock loudness value in LUFS
        return -23.0
    }
}

// MARK: - Mock ReplayGain

@MainActor
final class MockReplayGain: ReplayGainProtocol {
    var analyzeCalled = false
    var applyCalled = false
    
    var shouldFailAnalyze = false
    var shouldFailApply = false
    
    func analyzeReplayGain(audioData: [Float], sampleRate: Int, channels: Int) async throws -> ReplayGainResult {
        analyzeCalled = true
        if shouldFailAnalyze {
            throw ReplayGainError.analysisFailed("Mock analysis failure")
        }
        return ReplayGainResult(trackGain: -3.0, albumGain: -3.5, peak: 0.95)
    }
    
    func applyReplayGain(audioData: [Float], replayGain: ReplayGainResult, mode: ReplayGainMode) async throws -> [Float] {
        applyCalled = true
        if shouldFailApply {
            throw ReplayGainError.applicationFailed("Mock application failure")
        }
        let gainDB = mode == .track ? replayGain.trackGain : (replayGain.albumGain ?? replayGain.trackGain)
        let multiplier = pow(10.0, gainDB / 20.0)
        return audioData.map { min(max($0 * multiplier, -replayGain.peak), replayGain.peak) }
    }
    
    func calculateAlbumGain(from trackResults: [ReplayGainResult]) async throws -> Float {
        guard !trackResults.isEmpty else {
            throw ReplayGainError.invalidTrackResults
        }
        // Simple average of track gains for mock
        let sum = trackResults.reduce(0.0) { $0 + $1.trackGain }
        return sum / Float(trackResults.count)
    }
}

// MARK: - Mock AudioVisualiser

@MainActor
final class MockAudioVisualiser: AudioVisualiserProtocol {
    var config: AudioVisualiserConfig
    var frames: [AudioVisualiserFrame] = []
    
    var processCalled = false
    var getRecentFramesCalled = false
    
    var shouldFailProcess = false
    
    init(config: AudioVisualiserConfig = AudioVisualiserConfig()) {
        self.config = config
    }
    
    func process(audioData: [Float], sampleRate: Int, channels: Int) async throws -> AudioVisualiserFrame {
        processCalled = true
        if shouldFailProcess {
            throw AudioVisualiserError.invalidAudioData
        }
        
        // Create a mock frame with some test data
        let fftSize = config.fftSize
        let magnitudes = (0..<(fftSize / 2)).map { _ in Float.random(in: 0...100) }
        
        let frame = AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
        
        frames.append(frame)
        if frames.count > config.historyLength {
            frames.removeFirst()
        }
        
        return frame
    }
    
    func latestFrame() async -> AudioVisualiserFrame? {
        frames.last
    }
    
    func recentFrames(limit: Int) async -> [AudioVisualiserFrame] {
        getRecentFramesCalled = true
        return Array(frames.suffix(limit))
    }
}

// MARK: - Mock Factory Helper

private enum MockFactory {
    static func makeTrack(
        id: UUID = UUID(),
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3"
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
}
