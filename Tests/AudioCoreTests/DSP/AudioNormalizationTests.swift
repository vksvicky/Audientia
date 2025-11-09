//
//  AudioNormalizationTests.swift
//  AudioCoreTests
//
//  TDD tests for Audio Normalization
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// TDD tests for AudioNormalization
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class AudioNormalizationTests: XCTestCase {
    
    var normalizer: AudioNormalizer!
    
    override func setUp() async throws {
        normalizer = AudioNormalizer()
    }
    
    override func tearDown() async throws {
        normalizer = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test peak level calculation for known audio data
    func testCalculatePeakLevel() async {
        // Given - Audio data with known peak (1.0 = 0 dB)
        let audioData: [Float] = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0]
        let channels = 1
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: channels)
        
        // Then - Should be approximately 0 dB (peak of 1.0)
        XCTAssertEqual(peakLevel, 0.0, accuracy: 0.1, "Peak level should be 0 dB for peak of 1.0")
    }
    
    /// Test RMS level calculation for known audio data
    func testCalculateRMSLevel() async {
        // Given - Audio data with known RMS
        // RMS of [1.0, -1.0, 1.0, -1.0] = sqrt((1^2 + 1^2 + 1^2 + 1^2) / 4) = 1.0 = 0 dB
        let audioData: [Float] = [1.0, -1.0, 1.0, -1.0]
        let channels = 1
        
        // When - Calculate RMS level
        let rmsLevel = await normalizer.calculateRMSLevel(audioData: audioData, channels: channels)
        
        // Then - Should be approximately 0 dB
        XCTAssertEqual(rmsLevel, 0.0, accuracy: 0.1, "RMS level should be approximately 0 dB")
    }
    
    /// Test peak normalization analysis
    func testPeakNormalizationAnalysis() async throws {
        // Given - Audio data with peak at -6 dB (0.5)
        let audioData = generateSineWave(amplitude: 0.5, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -0.1 // Target peak at -0.1 dB
        
        // When - Analyze for peak normalization
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: targetLevel
        )
        
        // Then - Should suggest gain to bring peak to target
        // Peak is at -6 dB, target is -0.1 dB, so gain should be approximately +5.9 dB
        XCTAssertEqual(gainDB, 5.9, accuracy: 0.5, "Gain should bring peak to target level")
    }
    
    /// Test RMS normalization analysis
    func testRMSNormalizationAnalysis() async throws {
        // Given - Audio data with known RMS
        // Sine wave with amplitude 0.25 has RMS ≈ 0.177 (amplitude / sqrt(2))
        // RMS in dB ≈ 20 * log10(0.177) ≈ -15 dB
        let audioData = generateSineWave(amplitude: 0.25, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -20.0 // Target RMS at -20 dB
        
        // When - Analyze for RMS normalization
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .rms,
            targetLevel: targetLevel
        )
        
        // Then - Should suggest gain to bring RMS to target
        // RMS is approximately -15 dB, target is -20 dB, so gain should be approximately -5 dB
        XCTAssertEqual(gainDB, -5.0, accuracy: 2.0, "Gain should bring RMS to target level")
    }
    
    /// Test applying normalization gain
    func testApplyNormalization() async throws {
        // Given - Audio data and gain adjustment
        let audioData: [Float] = [0.5, -0.5, 0.3, -0.3]
        let gainDB: Float = 6.0 // +6 dB (doubles amplitude)
        
        // When - Apply normalization
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        
        // Then - Audio should be amplified by approximately 2x
        XCTAssertEqual(normalized[0], 1.0, accuracy: 0.1, "First sample should be approximately 1.0 after +6 dB gain")
        XCTAssertEqual(normalized[1], -1.0, accuracy: 0.1, "Second sample should be approximately -1.0 after +6 dB gain")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test with empty audio data
    func testEmptyAudioData() async {
        // Given - Empty audio data
        let audioData: [Float] = []
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - Should handle gracefully (return -infinity or very negative value)
        XCTAssertTrue(peakLevel.isInfinite || peakLevel < -100, "Empty audio should return -infinity or very negative peak level")
    }
    
    /// Test with silence (all zeros)
    func testSilenceAudioData() async {
        // Given - Silent audio data
        let audioData: [Float] = Array(repeating: 0.0, count: 1000)
        
        // When - Calculate peak and RMS levels
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        let rmsLevel = await normalizer.calculateRMSLevel(audioData: audioData, channels: 1)
        
        // Then - Should handle silence gracefully
        XCTAssertTrue(peakLevel.isInfinite || peakLevel < -100, "Silence should return -infinity or very negative peak level")
        XCTAssertTrue(rmsLevel.isInfinite || rmsLevel < -100, "Silence should return -infinity or very negative RMS level")
    }
    
    /// Test with very loud audio (clipping)
    func testVeryLoudAudio() async {
        // Given - Audio data with values > 1.0 (clipping)
        let audioData: [Float] = [1.5, -1.5, 2.0, -2.0]
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - Should detect clipping (positive dB value)
        XCTAssertGreaterThan(peakLevel, 0.0, "Clipped audio should have positive peak level")
    }
    
    /// Test with single sample
    func testSingleSample() async {
        // Given - Single audio sample
        let audioData: [Float] = [0.5]
        
        // When - Calculate peak and RMS levels
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        let rmsLevel = await normalizer.calculateRMSLevel(audioData: audioData, channels: 1)
        
        // Then - Should handle single sample correctly
        XCTAssertEqual(peakLevel, -6.0, accuracy: 0.1, "Single sample at 0.5 should have peak at -6 dB")
        XCTAssertEqual(rmsLevel, -6.0, accuracy: 0.1, "Single sample at 0.5 should have RMS at -6 dB")
    }
    
    /// Test with stereo audio data
    func testStereoAudioData() async {
        // Given - Stereo audio data (interleaved: L, R, L, R, ...)
        let audioData: [Float] = [1.0, 0.5, -1.0, -0.5, 0.8, 0.4]
        let channels = 2
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: channels)
        
        // Then - Should find peak across all channels
        XCTAssertEqual(peakLevel, 0.0, accuracy: 0.1, "Peak level should be 0 dB (peak of 1.0)")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that applying gain then removing it restores original
    func testApplyThenRemoveGainRestoresOriginal() async throws {
        // Given - Original audio data
        let original: [Float] = [0.5, -0.5, 0.3, -0.3]
        
        // When - Apply gain then remove it
        let gainDB: Float = 6.0
        let normalized = try await normalizer.applyNormalization(audioData: original, gainDB: gainDB)
        let restored = try await normalizer.applyNormalization(audioData: normalized, gainDB: -gainDB)
        
        // Then - Should restore to original (within rounding error)
        for i in 0..<original.count {
            XCTAssertEqual(restored[i], original[i], accuracy: 0.01, "Sample \(i) should be restored to original")
        }
    }
    
    /// Test that normalization analysis and application are consistent
    func testNormalizationAnalysisAndApplicationConsistency() async throws {
        // Given - Audio data
        let audioData = generateSineWave(amplitude: 0.5, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -0.1
        
        // When - Analyze and apply normalization
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: targetLevel
        )
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        let newPeak = await normalizer.calculatePeakLevel(audioData: normalized, channels: 1)
        
        // Then - New peak should be close to target
        XCTAssertEqual(newPeak, targetLevel, accuracy: 0.5, "Normalized peak should match target level")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that peak calculation matches manual calculation
    func testPeakCalculationMatchesManual() async {
        // Given - Known audio data
        let audioData: [Float] = [0.1, 0.5, 0.8, 1.0, 0.3]
        // Peak is 1.0, which is 0 dB
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - Should match manual calculation
        XCTAssertEqual(peakLevel, 0.0, accuracy: 0.1, "Peak level should match manual calculation")
    }
    
    /// Test that RMS calculation matches manual calculation
    func testRMSCalculationMatchesManual() async {
        // Given - Known audio data: [1.0, -1.0, 0.5, -0.5]
        // RMS = sqrt((1^2 + 1^2 + 0.5^2 + 0.5^2) / 4) = sqrt(2.5/4) = sqrt(0.625) ≈ 0.791
        // In dB: 20 * log10(0.791) ≈ -2.0 dB
        let audioData: [Float] = [1.0, -1.0, 0.5, -0.5]
        
        // When - Calculate RMS level
        let rmsLevel = await normalizer.calculateRMSLevel(audioData: audioData, channels: 1)
        
        // Then - Should match manual calculation
        XCTAssertEqual(rmsLevel, -2.0, accuracy: 0.5, "RMS level should match manual calculation")
    }
    
    // MARK: - Error Conditions
    
    /// Test with invalid sample rate
    func testInvalidSampleRate() async {
        // Given - Invalid sample rate
        let audioData = generateSineWave(amplitude: 0.5, samples: 100, sampleRate: 44100)
        
        // When - Analyze with invalid sample rate
        do {
            _ = try await normalizer.analyzeNormalization(
                audioData: audioData,
                sampleRate: 0, // Invalid
                channels: 1,
                mode: .peak,
                targetLevel: -0.1
            )
            XCTFail("Should throw error for invalid sample rate")
        } catch let error as AudioNormalizationError {
            XCTAssertEqual(error, .invalidSampleRate, "Should throw invalidSampleRate error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test with invalid channel count
    func testInvalidChannelCount() async {
        // Given - Audio data
        let audioData: [Float] = [0.5, -0.5]
        
        // When - Calculate with invalid channel count
        do {
            _ = try await normalizer.analyzeNormalization(
                audioData: audioData,
                sampleRate: 44100,
                channels: 0, // Invalid
                mode: .peak,
                targetLevel: -0.1
            )
            XCTFail("Should throw error for invalid channel count")
        } catch let error as AudioNormalizationError {
            XCTAssertEqual(error, .invalidChannelCount, "Should throw invalidChannelCount error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test with mismatched audio data length for channels
    func testMismatchedAudioDataLength() async {
        // Given - Audio data that doesn't match channel count
        let audioData: [Float] = [0.5] // Only 1 sample
        let channels = 2 // But stereo
        
        // When - Calculate peak level
        // Should handle gracefully (processes available samples)
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: channels)
        
        // Then - Should handle gracefully (processes what's available, peak of 0.5 = -6 dB)
        XCTAssertEqual(peakLevel, -6.0, accuracy: 0.1, "Should process available samples even with mismatched channel count")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test performance of peak calculation for large audio data
    func testPeakCalculationPerformance() async {
        // Given - Large audio data (1 second at 44.1kHz = 44100 samples)
        let audioData = generateSineWave(amplitude: 0.5, samples: 44100, sampleRate: 44100)
        
        // When - Calculate peak level and measure time
        let startTime = Date()
        _ = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (e.g., < 100ms)
        XCTAssertLessThan(duration, 0.1, "Peak calculation should complete within 100ms")
    }
    
    /// Test performance of RMS calculation for large audio data
    func testRMSCalculationPerformance() async {
        // Given - Large audio data
        let audioData = generateSineWave(amplitude: 0.5, samples: 44100, sampleRate: 44100)
        
        // When - Calculate RMS level and measure time
        let startTime = Date()
        _ = await normalizer.calculateRMSLevel(audioData: audioData, channels: 1)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (e.g., < 100ms)
        XCTAssertLessThan(duration, 0.1, "RMS calculation should complete within 100ms")
    }
    
    /// Test performance of normalization analysis
    func testNormalizationAnalysisPerformance() async throws {
        // Given - Large audio data
        let audioData = generateSineWave(amplitude: 0.5, samples: 44100, sampleRate: 44100)
        
        // When - Analyze normalization and measure time
        let startTime = Date()
        _ = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: -0.1
        )
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (e.g., < 200ms)
        XCTAssertLessThan(duration, 0.2, "Normalization analysis should complete within 200ms")
    }
    
    // MARK: - Edge Cases
    
    /// Test with very small audio values
    func testVerySmallAudioValues() async {
        // Given - Very small audio values
        let audioData: [Float] = [0.0001, -0.0001, 0.00005]
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - Should handle very small values correctly
        XCTAssertLessThan(peakLevel, -60.0, "Very small values should result in very negative dB")
    }
    
    /// Test with NaN values in audio data
    func testNaNValuesInAudioData() async {
        // Given - Audio data with NaN
        let audioData: [Float] = [0.5, Float.nan, 0.3]
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - Should handle NaN gracefully (should not crash, may return NaN or ignore)
        XCTAssertFalse(peakLevel.isNaN || peakLevel.isInfinite, "Should handle NaN gracefully")
    }
    
    /// Test with infinity values in audio data
    func testInfinityValuesInAudioData() async {
        // Given - Audio data with infinity
        let audioData: [Float] = [0.5, Float.infinity, 0.3]
        
        // When - Calculate peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - Should handle infinity gracefully
        XCTAssertTrue(peakLevel.isInfinite || peakLevel > 0, "Should handle infinity gracefully")
    }
    
    /// Test applying very large gain (potential clipping)
    func testApplyVeryLargeGain() async throws {
        // Given - Audio data and very large gain
        let audioData: [Float] = [0.5, -0.5]
        let gainDB: Float = 40.0 // +40 dB (100x amplification)
        
        // When - Apply normalization
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        
        // Then - Should handle clipping (values may exceed 1.0)
        XCTAssertGreaterThan(abs(normalized[0]), 1.0, "Very large gain should cause clipping")
    }
    
    /// Test applying very negative gain (potential silence)
    func testApplyVeryNegativeGain() async throws {
        // Given - Audio data and very negative gain
        let audioData: [Float] = [0.5, -0.5]
        let gainDB: Float = -60.0 // -60 dB (0.001x amplification)
        
        // When - Apply normalization
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        
        // Then - Should handle very quiet audio
        XCTAssertLessThan(abs(normalized[0]), 0.01, "Very negative gain should make audio very quiet")
    }
    
    // MARK: - Helper Methods
    
    /// Generate a sine wave for testing
    private func generateSineWave(amplitude: Float, samples: Int, sampleRate: Int) -> [Float] {
        var audioData: [Float] = []
        let frequency: Float = 440.0 // A4 note
        for i in 0..<samples {
            let time = Float(i) / Float(sampleRate)
            let sample = amplitude * sin(2.0 * Float.pi * frequency * time)
            audioData.append(sample)
        }
        return audioData
    }
}
