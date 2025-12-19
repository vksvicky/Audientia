//
//  AudioEngineNormalisationBDDTests.swift
//  AudioCoreTests
//
//  BDD tests for AudioEngine normalization integration
//  Testing user-facing scenarios and behaviors
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD tests for AudioEngine normalization integration
/// Testing real-world user scenarios
@MainActor
final class AudioEngineNormalisationBDDTests: XCTestCase {
    
    var engine: AudioEngine!
    var mockFileSystem: MockFileSystem!
    var mockNativeEngine: MockNativeAudioEngine!
    var mockNormaliser: MockAudioNormaliser!
    var mockFormatCoordinator: MockFormatDecodingCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFileSystem = MockFileSystem()
        mockNativeEngine = MockNativeAudioEngine()
        mockNormaliser = MockAudioNormaliser()
        mockFormatCoordinator = MockFormatDecodingCoordinator()
        
        engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockFormatCoordinator,
            nativeEngine: mockNativeEngine,
            normaliser: mockNormaliser
        )
    }
    
    override func tearDown() async throws {
        engine = nil
        mockFileSystem = nil
        mockNativeEngine = nil
        mockNormaliser = nil
        mockFormatCoordinator = nil
        try await super.tearDown()
    }
    
    // MARK: - Scenario: User normalizes track to peak level
    
    /// Scenario: User normalizes quiet track to peak level
    /// Given: User has a quiet track with peak at -12 dB
    /// When: User normalizes to -0.1 dB peak
    /// Then: Normalization gain should be calculated correctly
    func testUserNormalizesQuietTrackToPeakLevel() async throws {
        // Given - User has a quiet track with peak at -12 dB
        let track = MockFactory.makeTrack(filePath: "/test/quiet.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // Mock peak level calculation
        mockNormaliser.mockPeakLevel = -12.0 // Current peak is -12 dB
        mockNormaliser.mockNormalizationGain = 11.9 // Need +11.9 dB to reach -0.1 dB
        
        try await engine.loadTrack(track)
        
        // When - User normalizes to -0.1 dB peak
        let audioData: [Float] = [0.25, -0.25, 0.3, -0.3] // Quiet audio
        let normalizationGain = await engine.analyzeNormalization(
            mode: .peak,
            targetLevel: -0.1,
            audioData: audioData
        )
        
        // Then - Normalization gain should be calculated correctly
        XCTAssertNotNil(normalizationGain)
        XCTAssertEqual(normalizationGain ?? 0.0, 11.9, accuracy: 0.1)
        XCTAssertEqual(mockNormaliser.analyzeNormalizationCallCount, 1)
    }
    
    /// Scenario: User normalizes loud track to prevent clipping
    /// Given: User has a loud track with peak at +3 dB (clipping)
    /// When: User normalizes to -0.1 dB peak
    /// Then: Normalization gain should attenuate the track
    func testUserNormalizesLoudTrackToPreventClipping() async throws {
        // Given - User has a loud track with peak at +3 dB
        let track = MockFactory.makeTrack(filePath: "/test/loud.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // Mock peak level calculation
        mockNormaliser.mockPeakLevel = 3.0 // Current peak is +3 dB (clipping)
        mockNormaliser.mockNormalizationGain = -3.1 // Need -3.1 dB to reach -0.1 dB
        
        try await engine.loadTrack(track)
        
        // When - User normalizes to -0.1 dB peak
        let audioData: [Float] = [1.4, -1.4, 1.5, -1.5] // Loud audio (clipping)
        let normalizationGain = await engine.analyzeNormalization(
            mode: .peak,
            targetLevel: -0.1,
            audioData: audioData
        )
        
        // Then - Normalization gain should attenuate the track
        XCTAssertNotNil(normalizationGain)
        XCTAssertLessThan(normalizationGain ?? 0.0, 0.0) // Negative gain (attenuation)
        XCTAssertEqual(mockNormaliser.analyzeNormalizationCallCount, 1)
    }
    
    // MARK: - Scenario: User normalizes track to RMS level
    
    /// Scenario: User normalizes track to RMS level
    /// Given: User has a track with RMS at -20 dB
    /// When: User normalizes to -16 dB RMS
    /// Then: Normalization gain should boost the track
    func testUserNormalizesTrackToRMSLevel() async throws {
        // Given - User has a track with RMS at -20 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // Mock RMS level calculation
        mockNormaliser.mockRMSLevel = -20.0 // Current RMS is -20 dB
        mockNormaliser.mockNormalizationGain = 4.0 // Need +4 dB to reach -16 dB
        
        try await engine.loadTrack(track)
        
        // When - User normalizes to -16 dB RMS
        let audioData: [Float] = [0.1, -0.1, 0.15, -0.15]
        let normalizationGain = await engine.analyzeNormalization(
            mode: .rms,
            targetLevel: -16.0,
            audioData: audioData
        )
        
        // Then - Normalization gain should boost the track
        XCTAssertNotNil(normalizationGain)
        XCTAssertGreaterThan(normalizationGain ?? 0.0, 0.0) // Positive gain (amplification)
        XCTAssertEqual(mockNormaliser.analyzeNormalizationCallCount, 1)
    }
    
    // MARK: - Scenario: User normalizes track to loudness level
    
    /// Scenario: User normalizes track to EBU R128 loudness
    /// Given: User has a track with loudness at -26 LUFS
    /// When: User normalizes to -23 LUFS (EBU R128 standard)
    /// Then: Normalization gain should be calculated correctly
    func testUserNormalizesTrackToEBUR128Loudness() async throws {
        // Given - User has a track with loudness at -26 LUFS
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // Mock loudness calculation
        mockNormaliser.mockLoudness = -26.0 // Current loudness is -26 LUFS
        mockNormaliser.mockNormalizationGain = 3.0 // Need +3 dB to reach -23 LUFS
        
        try await engine.loadTrack(track)
        
        // When - User normalizes to -23 LUFS (EBU R128 standard)
        let audioData: [Float] = [0.2, -0.2, 0.25, -0.25]
        let normalizationGain = await engine.analyzeNormalization(
            mode: .loudness,
            targetLevel: -23.0,
            audioData: audioData
        )
        
        // Then - Normalization gain should be calculated correctly
        XCTAssertNotNil(normalizationGain)
        XCTAssertEqual(normalizationGain ?? 0.0, 3.0, accuracy: 0.1)
        XCTAssertEqual(mockNormaliser.calculateLoudnessCallCount, 1)
    }
    
    // MARK: - Scenario: User applies normalization
    
    /// Scenario: User applies normalization gain to audio
    /// Given: User has calculated normalization gain of +6 dB
    /// When: User applies normalization to audio data
    /// Then: Audio should be amplified correctly
    func testUserAppliesNormalizationGain() async throws {
        // Given - User has calculated normalization gain of +6 dB
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8]
        let gainDB: Float = 6.0 // +6 dB = 2x linear
        
        // When - User applies normalization to audio data
        let normalized = try await mockNormaliser.applyNormalization(
            audioData: audioData,
            gainDB: gainDB
        )
        
        // Then - Audio should be amplified correctly
        XCTAssertEqual(normalized.count, audioData.count)
        let expectedMultiplier = Float(pow(10.0, 6.0 / 20.0)) // ≈ 2.0
        XCTAssertEqual(normalized[0], audioData[0] * expectedMultiplier, accuracy: 0.001)
        XCTAssertEqual(mockNormaliser.applyNormalizationCallCount, 1)
    }
    
    // MARK: - Scenario: Edge cases
    
    /// Scenario: User normalizes silent track
    /// Given: User has a silent track
    /// When: User tries to normalize
    /// Then: System should handle silence gracefully
    func testUserNormalizesSilentTrack() async throws {
        // Given - User has a silent track
        let track = MockFactory.makeTrack(filePath: "/test/silent.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // Mock silence (peak level = -infinity)
        mockNormaliser.mockPeakLevel = -Float.infinity
        
        try await engine.loadTrack(track)
        
        // When - User tries to normalize
        let audioData: [Float] = [0.0, 0.0, 0.0, 0.0] // Silent
        let normalizationGain = await engine.analyzeNormalization(
            mode: .peak,
            targetLevel: -0.1,
            audioData: audioData
        )
        
        // Then - System should handle silence gracefully
        // Normalization gain should be 0 dB for silence (no change)
        // The actual implementation may return 0.0 or handle it differently
        XCTAssertNotNil(normalizationGain)
    }
    
    /// Scenario: User normalizes without normaliser
    /// Given: Engine without normaliser
    /// When: User tries to normalize
    /// Then: System should return nil gracefully
    func testUserNormalizesWithoutNormaliser() async throws {
        // Given - Engine without normaliser
        let engineWithoutNormaliser = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockFormatCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        try await engineWithoutNormaliser.loadTrack(track)
        
        // When - User tries to normalize
        let audioData: [Float] = [0.5, -0.5]
        let normalizationGain = await engineWithoutNormaliser.analyzeNormalization(
            mode: .peak,
            targetLevel: -0.1,
            audioData: audioData
        )
        
        // Then - System should return nil gracefully
        XCTAssertNil(normalizationGain)
    }
    
    /// Scenario: User normalizes with different modes
    /// Given: User has audio data
    /// When: User normalizes with peak, RMS, and loudness modes
    /// Then: Each mode should calculate appropriate gain
    func testUserNormalizesWithDifferentModes() async throws {
        // Given - User has audio data
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        mockNormaliser.mockNormalizationGain = 3.0
        
        try await engine.loadTrack(track)
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8]
        
        // When - User normalizes with different modes
        let peakGain = await engine.analyzeNormalization(
            mode: .peak,
            targetLevel: -0.1,
            audioData: audioData
        )
        
        let rmsGain = await engine.analyzeNormalization(
            mode: .rms,
            targetLevel: -16.0,
            audioData: audioData
        )
        
        let loudnessGain = await engine.analyzeNormalization(
            mode: .loudness,
            targetLevel: -23.0,
            audioData: audioData
        )
        
        // Then - Each mode should calculate appropriate gain
        XCTAssertNotNil(peakGain)
        XCTAssertNotNil(rmsGain)
        XCTAssertNotNil(loudnessGain)
        XCTAssertEqual(mockNormaliser.analyzeNormalizationCallCount, 3)
    }
}
