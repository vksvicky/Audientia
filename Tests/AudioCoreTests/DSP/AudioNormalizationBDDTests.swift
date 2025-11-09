//
//  AudioNormalizationBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for Audio Normalization
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD tests for Audio Normalization
/// User-centric scenarios following "As a user, I want to..." format
@MainActor
final class AudioNormalizationBDDTests: XCTestCase {
    
    var normalizer: AudioNormalizer!
    
    override func setUp() async throws {
        try await super.setUp()
        normalizer = AudioNormalizer()
    }
    
    override func tearDown() async throws {
        normalizer = nil
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Normalize Audio Levels
    
    /// BDD: As a user, I want to normalize audio levels across my library so all tracks play at consistent volume
    func testUserNormalizesAudioLevelsAcrossLibrary() async throws {
        // Given - I have tracks with varying volume levels
        let quietTrack = generateSineWave(amplitude: 0.1, samples: 1000, sampleRate: 44100)
        let loudTrack = generateSineWave(amplitude: 0.9, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -0.1 // Target peak at -0.1 dB
        
        // When - I normalize both tracks to the same peak level
        let quietGain = try await normalizer.analyzeNormalization(
            audioData: quietTrack,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: targetLevel
        )
        let loudGain = try await normalizer.analyzeNormalization(
            audioData: loudTrack,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: targetLevel
        )
        
        let normalizedQuiet = try await normalizer.applyNormalization(audioData: quietTrack, gainDB: quietGain)
        let normalizedLoud = try await normalizer.applyNormalization(audioData: loudTrack, gainDB: loudGain)
        
        let quietPeak = await normalizer.calculatePeakLevel(audioData: normalizedQuiet, channels: 1)
        let loudPeak = await normalizer.calculatePeakLevel(audioData: normalizedLoud, channels: 1)
        
        // Then - Both tracks should have similar peak levels
        XCTAssertEqual(quietPeak, targetLevel, accuracy: 0.5, "Quiet track should be normalized to target")
        XCTAssertEqual(loudPeak, targetLevel, accuracy: 0.5, "Loud track should be normalized to target")
    }
    
    /// BDD: As a user, I want to normalize audio using peak normalization so the loudest parts are at a consistent level
    func testUserNormalizesUsingPeakNormalization() async throws {
        // Given - I have a track with varying peak levels
        let audioData = generateSineWave(amplitude: 0.5, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -0.1 // Target peak at -0.1 dB
        
        // When - I normalize using peak normalization
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: targetLevel
        )
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        let newPeak = await normalizer.calculatePeakLevel(audioData: normalized, channels: 1)
        
        // Then - The peak level should match the target
        XCTAssertEqual(newPeak, targetLevel, accuracy: 0.5, "Peak should be normalized to target level")
    }
    
    /// BDD: As a user, I want to normalize audio using RMS normalization so the average loudness is consistent
    func testUserNormalizesUsingRMSNormalization() async throws {
        // Given - I have a track with varying RMS levels
        let audioData = generateSineWave(amplitude: 0.3, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -20.0 // Target RMS at -20 dB
        
        // When - I normalize using RMS normalization
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .rms,
            targetLevel: targetLevel
        )
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        let newRMS = await normalizer.calculateRMSLevel(audioData: normalized, channels: 1)
        
        // Then - The RMS level should be close to the target
        XCTAssertEqual(newRMS, targetLevel, accuracy: 2.0, "RMS should be normalized to target level")
    }
    
    // MARK: - User Scenario: Understand Audio Levels
    
    /// BDD: As a user, I want to see the peak level of my audio so I know if it's too loud or too quiet
    func testUserViewsPeakLevelOfAudio() async {
        // Given - I have audio data
        let audioData: [Float] = [0.5, -0.5, 0.8, -0.8, 1.0, -1.0]
        
        // When - I check the peak level
        let peakLevel = await normalizer.calculatePeakLevel(audioData: audioData, channels: 1)
        
        // Then - I should see the peak level in dB
        XCTAssertEqual(peakLevel, 0.0, accuracy: 0.1, "Peak level should be 0 dB for peak of 1.0")
    }
    
    /// BDD: As a user, I want to see the RMS level of my audio so I understand the average loudness
    func testUserViewsRMSLevelOfAudio() async {
        // Given - I have audio data
        let audioData: [Float] = [1.0, -1.0, 0.5, -0.5]
        
        // When - I check the RMS level
        let rmsLevel = await normalizer.calculateRMSLevel(audioData: audioData, channels: 1)
        
        // Then - I should see the RMS level in dB
        XCTAssertLessThan(rmsLevel, 0.0, "RMS level should be less than peak level")
        XCTAssertGreaterThan(rmsLevel, -10.0, "RMS level should be reasonable for this audio")
    }
    
    // MARK: - User Scenario: Handle Different Audio Formats
    
    /// BDD: As a user, I want to normalize stereo audio so both channels are balanced
    func testUserNormalizesStereoAudio() async throws {
        // Given - I have stereo audio data (interleaved: L, R, L, R, ...)
        let audioData: [Float] = [1.0, 0.5, -1.0, -0.5, 0.8, 0.4]
        let targetLevel: Float = -0.1
        
        // When - I normalize the stereo audio
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2,
            mode: .peak,
            targetLevel: targetLevel
        )
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        let newPeak = await normalizer.calculatePeakLevel(audioData: normalized, channels: 2)
        
        // Then - The stereo audio should be normalized
        XCTAssertEqual(newPeak, targetLevel, accuracy: 0.5, "Stereo audio should be normalized to target")
    }
    
    // MARK: - User Scenario: Prevent Clipping
    
    /// BDD: As a user, I want to normalize audio without causing clipping so the audio quality is preserved
    func testUserNormalizesWithoutCausingClipping() async throws {
        // Given - I have audio that's already close to maximum
        let audioData = generateSineWave(amplitude: 0.9, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -0.1 // Target just below 0 dB to prevent clipping
        
        // When - I normalize to a safe level
        let gainDB = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: targetLevel
        )
        let normalized = try await normalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        let newPeak = await normalizer.calculatePeakLevel(audioData: normalized, channels: 1)
        
        // Then - The audio should be normalized without exceeding 0 dB
        XCTAssertLessThanOrEqual(newPeak, 0.0, "Normalized peak should not exceed 0 dB")
        XCTAssertEqual(newPeak, targetLevel, accuracy: 0.5, "Should be normalized to target level")
    }
    
    // MARK: - User Scenario: Batch Normalization
    
    /// BDD: As a user, I want to normalize multiple tracks in my library so they all have consistent levels
    func testUserNormalizesMultipleTracks() async throws {
        // Given - I have multiple tracks with different levels
        let track1 = generateSineWave(amplitude: 0.2, samples: 1000, sampleRate: 44100)
        let track2 = generateSineWave(amplitude: 0.6, samples: 1000, sampleRate: 44100)
        let track3 = generateSineWave(amplitude: 0.4, samples: 1000, sampleRate: 44100)
        let targetLevel: Float = -0.1
        
        // When - I normalize all tracks to the same target
        var normalizedPeaks: [Float] = []
        for track in [track1, track2, track3] {
            let gainDB = try await normalizer.analyzeNormalization(
                audioData: track,
                sampleRate: 44100,
                channels: 1,
                mode: .peak,
                targetLevel: targetLevel
            )
            let normalized = try await normalizer.applyNormalization(audioData: track, gainDB: gainDB)
            let peak = await normalizer.calculatePeakLevel(audioData: normalized, channels: 1)
            normalizedPeaks.append(peak)
        }
        
        // Then - All tracks should have similar peak levels
        for peak in normalizedPeaks {
            XCTAssertEqual(peak, targetLevel, accuracy: 0.5, "All tracks should be normalized to target")
        }
    }
    
    // MARK: - User Scenario: Adjust Normalization Target
    
    /// BDD: As a user, I want to adjust the normalization target so I can control how loud my library is
    func testUserAdjustsNormalizationTarget() async throws {
        // Given - I have audio data
        let audioData = generateSineWave(amplitude: 0.5, samples: 1000, sampleRate: 44100)
        
        // When - I normalize to different targets
        let target1: Float = -0.1
        let target2: Float = -3.0
        
        let gain1 = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: target1
        )
        let gain2 = try await normalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 1,
            mode: .peak,
            targetLevel: target2
        )
        
        // Then - The gain should be different for different targets
        XCTAssertNotEqual(gain1, gain2, accuracy: 0.1, "Different targets should require different gains")
        XCTAssertLessThan(gain2, gain1, "Lower target should require less gain")
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
