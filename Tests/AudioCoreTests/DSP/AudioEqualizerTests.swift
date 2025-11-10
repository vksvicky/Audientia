//
//  AudioEqualizerTests.swift
//  AudioCoreTests
//
//  TDD tests for 10-band parametric equalizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// TDD tests for AudioEqualizer
/// Following Right-BICEP principles
final class AudioEqualizerTests: XCTestCase {
    
    var equalizer: AudioEqualizer!
    
    override func setUp() {
        super.setUp()
        equalizer = AudioEqualizer()
    }
    
    override func tearDown() {
        equalizer = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given a new equalizer, when I check the bands, then all bands should be at 0.0 dB (flat)
    func testInitialBandsAreFlat() async {
        // Given & When
        let bands = await equalizer.getBands()
        
        // Then
        XCTAssertEqual(bands.count, 10, "Should have 10 bands")
        for (index, band) in bands.enumerated() {
            XCTAssertEqual(band.gain, 0.0, accuracy: 0.01, "Band \(index) should be flat (0.0 dB)")
        }
    }
    
    /// BDD: Given an equalizer, when I set a band gain, then that band should have the new gain
    func testSetBandGain() async throws {
        // Given
        let bandIndex = 5
        let gain: Float = 3.0
        
        // When
        try await equalizer.setBandGain(bandIndex, gain: gain)
        
        // Then
        let retrievedGain = try await equalizer.getBandGain(bandIndex)
        XCTAssertEqual(retrievedGain, gain, accuracy: 0.01, "Band gain should be set correctly")
    }
    
    /// BDD: Given an equalizer with modified bands, when I reset, then all bands should be flat
    func testResetMakesAllBandsFlat() async throws {
        // Given
        try await equalizer.setBandGain(0, gain: 5.0)
        try await equalizer.setBandGain(5, gain: -3.0)
        try await equalizer.setBandGain(9, gain: 2.0)
        
        // When
        await equalizer.reset()
        
        // Then
        let bands = await equalizer.getBands()
        for band in bands {
            XCTAssertEqual(band.gain, 0.0, accuracy: 0.01, "All bands should be flat after reset")
        }
    }
    
    /// BDD: Given an equalizer, when I process audio with flat bands, then output should match input
    func testFlatEqualizerDoesNotModifyAudio() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        
        // When
        let processed = try await equalizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        XCTAssertEqual(processed.count, audioData.count, "Output should have same length as input")
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(processed[index], value, accuracy: 0.001, "Flat EQ should not modify audio at index \(index)")
        }
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given an equalizer, when I set gain to maximum, then it should be clamped
    func testSetBandGainClampsToMaximum() async throws {
        // Given
        let bandIndex = 0
        let extremeGain: Float = 100.0
        
        // When
        try await equalizer.setBandGain(bandIndex, gain: extremeGain)
        
        // Then
        let retrievedGain = try await equalizer.getBandGain(bandIndex)
        XCTAssertLessThanOrEqual(retrievedGain, 20.0, "Gain should be clamped to maximum")
    }
    
    /// BDD: Given an equalizer, when I set gain to minimum, then it should be clamped
    func testSetBandGainClampsToMinimum() async throws {
        // Given
        let bandIndex = 0
        let extremeGain: Float = -100.0
        
        // When
        try await equalizer.setBandGain(bandIndex, gain: extremeGain)
        
        // Then
        let retrievedGain = try await equalizer.getBandGain(bandIndex)
        XCTAssertGreaterThanOrEqual(retrievedGain, -20.0, "Gain should be clamped to minimum")
    }
    
    /// BDD: Given an equalizer, when I try to set gain for invalid band index, then it should throw error
    func testSetBandGainWithInvalidIndexThrowsError() async {
        // Given
        let invalidIndex = 10
        
        // When & Then
        do {
            try await equalizer.setBandGain(invalidIndex, gain: 5.0)
            XCTFail("Should throw error for invalid band index")
        } catch let error as AudioEqualizerError {
            XCTAssertEqual(error, .invalidBandIndex(invalidIndex), "Should throw invalidBandIndex error")
        } catch {
            XCTFail("Should throw AudioEqualizerError, got: \(error)")
        }
    }
    
    /// BDD: Given an equalizer, when I process empty audio, then it should throw error
    func testProcessEmptyAudioThrowsError() async {
        // Given
        let emptyAudio: [Float] = []
        
        // When & Then
        do {
            _ = try await equalizer.process(
                audioData: emptyAudio,
                sampleRate: 44100,
                channels: 2
            )
            XCTFail("Should throw error for empty audio")
        } catch let error as AudioEqualizerError {
            XCTAssertEqual(error, .invalidAudioData, "Should throw invalidAudioData error")
        } catch {
            XCTFail("Should throw AudioEqualizerError, got: \(error)")
        }
    }
    
    /// BDD: Given an equalizer, when I process audio with invalid sample rate, then it should throw error
    func testProcessWithInvalidSampleRateThrowsError() async {
        // Given
        let audioData: [Float] = [0.5, -0.3]
        
        // When & Then
        do {
            _ = try await equalizer.process(
                audioData: audioData,
                sampleRate: 0,
                channels: 2
            )
            XCTFail("Should throw error for invalid sample rate")
        } catch let error as AudioEqualizerError {
            XCTAssertEqual(error, .invalidSampleRate, "Should throw invalidSampleRate error")
        } catch {
            XCTFail("Should throw AudioEqualizerError, got: \(error)")
        }
    }
    
    // MARK: - [I]nverse Relationships
    
    /// BDD: Given an equalizer, when I set gain then reset, then gain should return to 0.0
    func testSetGainThenResetRoundtrip() async throws {
        // Given
        let bandIndex = 3
        let gain: Float = 4.5
        
        // When
        try await equalizer.setBandGain(bandIndex, gain: gain)
        await equalizer.reset()
        
        // Then
        let resetGain = try await equalizer.getBandGain(bandIndex)
        XCTAssertEqual(resetGain, 0.0, accuracy: 0.01, "Gain should return to 0.0 after reset")
    }
    
    // MARK: - [C]ross-Checking Using Other Means
    
    /// BDD: Given an equalizer, when I check bands via multiple methods, then they should agree
    func testBandConsistencyAcrossMethods() async throws {
        // Given
        let bandIndex = 7
        let gain: Float = 2.5
        
        // When
        try await equalizer.setBandGain(bandIndex, gain: gain)
        
        // Then
        let bands = await equalizer.getBands()
        let directGain = try await equalizer.getBandGain(bandIndex)
        
        XCTAssertEqual(bands[bandIndex].gain, directGain, accuracy: 0.01, "Band gain should be consistent")
        XCTAssertEqual(bands[bandIndex].gain, gain, accuracy: 0.01, "Band gain should match set value")
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given an equalizer, when I try to get gain for invalid band index, then it should throw error
    func testGetBandGainWithInvalidIndexThrowsError() async {
        // Given
        let invalidIndex = -1
        
        // When & Then
        do {
            _ = try await equalizer.getBandGain(invalidIndex)
            XCTFail("Should throw error for invalid band index")
        } catch let error as AudioEqualizerError {
            XCTAssertEqual(error, .invalidBandIndex(invalidIndex), "Should throw invalidBandIndex error")
        } catch {
            XCTFail("Should throw AudioEqualizerError, got: \(error)")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given an equalizer, when I process audio, then it should complete quickly
    func testProcessPerformance() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let durationSeconds: Float = 1.0
        let sampleCount = Int(Float(sampleRate) * durationSeconds * Float(channels))
        let audioData = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        
        // When & Then
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await equalizer.process(
                    audioData: audioData,
                    sampleRate: sampleRate,
                    channels: channels
                )
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    // MARK: - Edge Cases
    
    /// BDD: Given an equalizer, when I set all bands to different gains, then all should be set correctly
    func testSetAllBands() async throws {
        // Given
        let gains: [Float] = [1.0, -2.0, 3.0, -4.0, 5.0, -6.0, 7.0, -8.0, 9.0, -10.0]
        
        // When
        for (index, gain) in gains.enumerated() {
            try await equalizer.setBandGain(index, gain: gain)
        }
        
        // Then
        let bands = await equalizer.getBands()
        for (index, expectedGain) in gains.enumerated() {
            XCTAssertEqual(bands[index].gain, expectedGain, accuracy: 0.01, "Band \(index) should have correct gain")
        }
    }
    
    /// BDD: Given an equalizer, when I process mono audio, then it should handle correctly
    func testProcessMonoAudio() async throws {
        // Given
        let sampleRate = 44100
        let channels = 1
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1]
        
        // When
        let processed = try await equalizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        XCTAssertEqual(processed.count, audioData.count, "Output should have same length as input")
    }
    
    /// BDD: Given an equalizer, when I enable then disable, then processing should be bypassed
    func testEnableDisableBypass() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        try await equalizer.setBandGain(5, gain: 6.0) // Set a band to non-zero
        
        // When - Disable
        await equalizer.setEnabled(false)
        let disabledProcessed = try await equalizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Should be unchanged (bypassed)
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(disabledProcessed[index], value, accuracy: 0.001, "Disabled EQ should not modify audio")
        }
        
        // When - Enable
        await equalizer.setEnabled(true)
        let enabledProcessed = try await equalizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Should be modified
        let hasDifference = audioData.enumerated().contains { index, value in
            abs(enabledProcessed[index] - value) > 0.001
        }
        XCTAssertTrue(hasDifference, "Enabled EQ should modify audio")
    }
}
