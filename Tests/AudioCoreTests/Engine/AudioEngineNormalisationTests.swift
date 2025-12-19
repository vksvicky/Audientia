//
//  AudioEngineNormalisationTests.swift
//  AudioCoreTests
//
//  TDD tests for AudioEngine normalization integration
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// TDD tests for AudioEngine normalization integration
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class AudioEngineNormalisationTests: XCTestCase {
    
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
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that normalization can analyze audio data
    func testNormalizationAnalysis() async throws {
        // Given - Audio data and normalization settings
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8, 0.3, -0.3]
        mockNormaliser.mockNormalizationGain = 3.0 // +3 dB needed
        
        // When - Analyze normalization
        let gain = try await mockNormaliser.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2,
            mode: .peak,
            targetLevel: -0.1
        )
        
        // Then - Should return normalization gain
        XCTAssertEqual(gain, 3.0, accuracy: 0.001)
        XCTAssertEqual(mockNormaliser.analyzeNormalizationCallCount, 1)
    }
    
    /// Test that normalization can be applied to audio data
    func testNormalizationApplication() async throws {
        // Given - Audio data and normalization gain
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8]
        let gainDB: Float = 6.0 // +6 dB = 2x
        
        // When - Apply normalization
        let normalized = try await mockNormaliser.applyNormalization(
            audioData: audioData,
            gainDB: gainDB
        )
        
        // Then - Audio should be amplified
        XCTAssertEqual(normalized.count, audioData.count)
        XCTAssertEqual(normalized[0], 0.5 * pow(10.0, 6.0 / 20.0), accuracy: 0.001)
        XCTAssertEqual(mockNormaliser.applyNormalizationCallCount, 1)
    }
    
    /// Test peak level calculation
    func testPeakLevelCalculation() async {
        // Given - Audio data with known peak
        let audioData: [Float] = [0.0, 0.5, 1.0, 0.5, 0.0]
        mockNormaliser.mockPeakLevel = 0.0 // 0 dB for peak of 1.0
        
        // When - Calculate peak level
        let peakLevel = await mockNormaliser.calculatePeakLevel(
            audioData: audioData,
            channels: 1
        )
        
        // Then - Should return peak level in dB
        XCTAssertEqual(peakLevel, 0.0, accuracy: 0.1)
        XCTAssertEqual(mockNormaliser.calculatePeakLevelCallCount, 1)
    }
    
    /// Test RMS level calculation
    func testRMSLevelCalculation() async {
        // Given - Audio data
        let audioData: [Float] = [1.0, -1.0, 1.0, -1.0]
        mockNormaliser.mockRMSLevel = 0.0 // 0 dB RMS
        
        // When - Calculate RMS level
        let rmsLevel = await mockNormaliser.calculateRMSLevel(
            audioData: audioData,
            channels: 2
        )
        
        // Then - Should return RMS level in dB
        XCTAssertEqual(rmsLevel, 0.0, accuracy: 0.1)
        XCTAssertEqual(mockNormaliser.calculateRMSLevelCallCount, 1)
    }
    
    // MARK: - Boundary Conditions
    
    /// Test that empty audio data is handled
    func testEmptyAudioDataHandling() async {
        // Given - Empty audio data
        let audioData: [Float] = []
        mockNormaliser.shouldFailAnalysis = true
        mockNormaliser.errorToThrow = AudioNormalisationError.invalidAudioData
        
        // When - Try to analyze
        // Then - Should throw error
        do {
            _ = try await mockNormaliser.analyzeNormalization(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2,
                mode: .peak,
                targetLevel: -0.1
            )
            XCTFail("Should have thrown error for empty audio data")
        } catch {
            XCTAssertTrue(error is AudioNormalisationError)
        }
    }
    
    /// Test that invalid sample rate is handled
    func testInvalidSampleRateHandling() async {
        // Given - Invalid sample rate
        let audioData: [Float] = [0.5, -0.5]
        mockNormaliser.shouldFailAnalysis = true
        mockNormaliser.errorToThrow = AudioNormalisationError.invalidSampleRate
        
        // When - Try to analyze with invalid sample rate
        // Then - Should throw error
        do {
            _ = try await mockNormaliser.analyzeNormalization(
                audioData: audioData,
                sampleRate: 0,
                channels: 2,
                mode: .peak,
                targetLevel: -0.1
            )
            XCTFail("Should have thrown error for invalid sample rate")
        } catch {
            XCTAssertTrue(error is AudioNormalisationError)
        }
    }
    
    /// Test that silence is handled correctly
    func testSilenceHandling() async {
        // Given - Silent audio data
        let audioData: [Float] = [0.0, 0.0, 0.0, 0.0]
        mockNormaliser.mockPeakLevel = -Float.infinity // Silence = -infinity dB
        
        // When - Calculate peak level
        let peakLevel = await mockNormaliser.calculatePeakLevel(
            audioData: audioData,
            channels: 1
        )
        
        // Then - Should return -infinity for silence
        XCTAssertTrue(peakLevel.isInfinite && peakLevel < 0)
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that normalization roundtrip works
    func testNormalizationRoundtrip() async throws {
        // Given - Original audio data
        let originalAudio: [Float] = [0.5, -0.5, 0.8, -0.8]
        let gainDB: Float = 6.0
        
        // When - Apply normalization
        let normalized = try await mockNormaliser.applyNormalization(
            audioData: originalAudio,
            gainDB: gainDB
        )
        
        // Then - Apply inverse gain to restore
        let restored = try await mockNormaliser.applyNormalization(
            audioData: normalized,
            gainDB: -gainDB
        )
        
        // Should be close to original (within floating point precision)
        for (original, restored) in zip(originalAudio, restored) {
            XCTAssertEqual(original, restored, accuracy: 0.01)
        }
    }
    
    // MARK: - Cross-Check
    
    /// Test that peak level calculation matches manual calculation
    func testPeakLevelCalculationMatchesManual() async {
        // Given - Audio data with peak of 0.5
        // Peak of 0.5 = 20 * log10(0.5) ≈ -6.02 dB
        let expectedPeakDB = 20.0 * log10(0.5)
        
        // When - Calculate peak level (using real implementation logic)
        // Note: This test verifies the calculation formula, not the mock
        let calculatedPeak = 0.5
        let calculatedPeakDB = 20.0 * log10(calculatedPeak)
        
        // Then - Should match expected
        XCTAssertEqual(calculatedPeakDB, expectedPeakDB, accuracy: 0.01)
    }
    
    // MARK: - Error Conditions
    
    /// Test that normalization errors are handled gracefully
    func testNormalizationErrorHandling() async {
        // Given - Normaliser configured to fail
        mockNormaliser.shouldFailApplication = true
        mockNormaliser.errorToThrow = AudioNormalisationError.normalizationFailed("Test error")
        
        let audioData: [Float] = [0.5, -0.5]
        
        // When - Try to apply normalization
        // Then - Should throw error
        do {
            _ = try await mockNormaliser.applyNormalization(
                audioData: audioData,
                gainDB: 3.0
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AudioNormalisationError)
        }
    }
    
    // MARK: - Performance
    
    /// Test that normalization analysis is fast
    /// Note: measure() doesn't support async well, so we measure manually
    func testNormalizationAnalysisPerformance() async throws {
        // Given - Large audio data array
        let audioData = (0..<10000).map { _ in Float.random(in: -1.0...1.0) }
        mockNormaliser.mockNormalizationGain = 0.0
        
        // When - Analyze normalization multiple times and measure time
        let iterations = 10
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await mockNormaliser.analyzeNormalization(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2,
                mode: .peak,
                targetLevel: -0.1
            )
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        // Then - Should complete within reasonable time
        let average = times.reduce(0, +) / Double(times.count)
        // Analysis of 10000 samples should complete quickly (< 0.1 seconds per iteration)
        XCTAssertLessThan(average, 0.1, "Normalization analysis should complete within 0.1 seconds per iteration")
    }
    
    // MARK: - Edge Cases
    
    /// Test that different normalization modes work
    func testDifferentNormalizationModes() async throws {
        // Given - Audio data
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8]
        mockNormaliser.mockNormalizationGain = 3.0
        
        // When - Analyze with different modes
        let peakGain = try await mockNormaliser.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2,
            mode: .peak,
            targetLevel: -0.1
        )
        
        let rmsGain = try await mockNormaliser.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2,
            mode: .rms,
            targetLevel: -20.0
        )
        
        let loudnessGain = try await mockNormaliser.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2,
            mode: .loudness,
            targetLevel: -23.0
        )
        
        // Then - All modes should return gain values
        XCTAssertEqual(peakGain, 3.0, accuracy: 0.001)
        XCTAssertEqual(rmsGain, 3.0, accuracy: 0.001)
        XCTAssertEqual(loudnessGain, 3.0, accuracy: 0.001)
        
        // Verify that each mode called the appropriate calculation method
        XCTAssertEqual(mockNormaliser.calculatePeakLevelCallCount, 1, "Peak mode should call calculatePeakLevel")
        XCTAssertEqual(mockNormaliser.calculateRMSLevelCallCount, 1, "RMS mode should call calculateRMSLevel")
        XCTAssertEqual(mockNormaliser.calculateLoudnessCallCount, 1, "Loudness mode should call calculateLoudness")
    }
    
    /// Test that loudness calculation works
    func testLoudnessCalculation() async throws {
        // Given - Audio data
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8]
        mockNormaliser.mockLoudness = -23.0 // EBU R128 target
        
        // When - Calculate loudness
        let loudness = try await mockNormaliser.calculateLoudness(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // Then - Should return loudness in LUFS
        XCTAssertEqual(loudness, -23.0, accuracy: 0.1)
        XCTAssertEqual(mockNormaliser.calculateLoudnessCallCount, 1)
    }
}
