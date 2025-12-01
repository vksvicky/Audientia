//
//  AudioEqualiserBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for 10-band parametric equaliser
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// BDD-style test scenarios for AudioEqualiser
/// Following user-centric "As a user, I want to..." format
final class AudioEqualiserBDDTests: XCTestCase {
    
    var equaliser: AudioEqualiser!
    
    override func setUp() {
        super.setUp()
        equaliser = AudioEqualiser()
    }
    
    override func tearDown() {
        equaliser = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to boost the bass frequencies to make music sound warmer
    func testBoostBassFrequencies() async throws {
        // Given - I have an equaliser and audio playing
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        
        // When - I boost the bass bands (31Hz, 62Hz, 125Hz)
        try await equaliser.setBandGain(0, gain: 6.0) // 31Hz
        try await equaliser.setBandGain(1, gain: 4.0) // 62Hz
        try await equaliser.setBandGain(2, gain: 3.0) // 125Hz
        
        let processed = try await equaliser.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - The audio should be modified (boosted)
        XCTAssertNotEqual(processed, audioData, "Audio should be modified with bass boost")
        
        // And - The bass bands should have the correct gain
        let band0Gain = try await equaliser.getBandGain(0)
        let band1Gain = try await equaliser.getBandGain(1)
        let band2Gain = try await equaliser.getBandGain(2)
        
        XCTAssertEqual(band0Gain, 6.0, accuracy: 0.01, "31Hz band should be boosted to 6.0 dB")
        XCTAssertEqual(band1Gain, 4.0, accuracy: 0.01, "62Hz band should be boosted to 4.0 dB")
        XCTAssertEqual(band2Gain, 3.0, accuracy: 0.01, "125Hz band should be boosted to 3.0 dB")
    }
    
    /// BDD: As a user, I want to reduce harsh treble frequencies
    func testReduceTrebleFrequencies() async throws {
        // Given - I have an equaliser
        // When - I reduce the treble bands (8kHz, 16kHz)
        try await equaliser.setBandGain(8, gain: -4.0) // 8kHz
        try await equaliser.setBandGain(9, gain: -6.0) // 16kHz
        
        // Then - The treble bands should be attenuated
        let band8Gain = try await equaliser.getBandGain(8)
        let band9Gain = try await equaliser.getBandGain(9)
        
        XCTAssertEqual(band8Gain, -4.0, accuracy: 0.01, "8kHz band should be reduced to -4.0 dB")
        XCTAssertEqual(band9Gain, -6.0, accuracy: 0.01, "16kHz band should be reduced to -6.0 dB")
    }
    
    /// BDD: As a user, I want to reset all equaliser settings to flat
    func testResetAllBandsToFlat() async throws {
        // Given - I have adjusted several bands
        try await equaliser.setBandGain(0, gain: 5.0)
        try await equaliser.setBandGain(5, gain: -3.0)
        try await equaliser.setBandGain(9, gain: 2.0)
        
        // When - I reset the equaliser
        await equaliser.reset()
        
        // Then - All bands should be at 0.0 dB (flat)
        let bands = await equaliser.getBands()
        for (index, band) in bands.enumerated() {
            XCTAssertEqual(band.gain, 0.0, accuracy: 0.01, "Band \(index) should be flat after reset")
        }
    }
    
    /// BDD: As a user, I want to bypass the equaliser without losing my settings
    func testBypassEqualiserWithoutLosingSettings() async throws {
        // Given - I have configured the equaliser
        try await equaliser.setBandGain(5, gain: 6.0)
        let originalGain = try await equaliser.getBandGain(5)
        
        // When - I disable the equaliser
        await equaliser.setEnabled(false)
        let isEnabled = await equaliser.isEnabled()
        
        // Then - The equaliser should be disabled
        XCTAssertFalse(isEnabled, "Equaliser should be disabled")
        
        // And - My settings should be preserved
        let preservedGain = try await equaliser.getBandGain(5)
        XCTAssertEqual(preservedGain, originalGain, accuracy: 0.01, "Settings should be preserved when disabled")
        
        // When - I re-enable the equaliser
        await equaliser.setEnabled(true)
        
        // Then - The equaliser should be enabled again
        let reEnabled = await equaliser.isEnabled()
        XCTAssertTrue(reEnabled, "Equaliser should be enabled again")
    }
    
    /// BDD: As a user, I want to apply a preset equaliser curve (e.g., "Rock", "Jazz", "Classical")
    func testApplyPresetEqualiserCurve() async throws {
        // Given - I want to apply a "Rock" preset (boosted bass and treble, reduced mids)
        let rockPreset: [(Int, Float)] = [
            (0, 4.0),  // 31Hz: +4dB
            (1, 3.0),  // 62Hz: +3dB
            (2, -2.0), // 125Hz: -2dB
            (3, -3.0), // 250Hz: -3dB
            (4, -2.0), // 500Hz: -2dB
            (5, 1.0),  // 1kHz: +1dB
            (6, 2.0),  // 2kHz: +2dB
            (7, 3.0),  // 4kHz: +3dB
            (8, 4.0),  // 8kHz: +4dB
            (9, 3.0)   // 16kHz: +3dB
        ]
        
        // When - I apply the preset
        for (bandIndex, gain) in rockPreset {
            try await equaliser.setBandGain(bandIndex, gain: gain)
        }
        
        // Then - All bands should match the preset
        let bands = await equaliser.getBands()
        for (index, (_, expectedGain)) in rockPreset.enumerated() {
            XCTAssertEqual(bands[index].gain, expectedGain, accuracy: 0.01, "Band \(index) should match preset")
        }
    }
    
    /// BDD: As a user, I want to fine-tune individual frequency bands
    func testFineTuneIndividualBands() async throws {
        // Given - I want to adjust the 1kHz band
        // When - I set it to a specific gain
        let targetGain: Float = 2.5
        try await equaliser.setBandGain(5, gain: targetGain)
        
        // Then - The band should have the exact gain I set
        let actualGain = try await equaliser.getBandGain(5)
        XCTAssertEqual(actualGain, targetGain, accuracy: 0.01, "Band should have exact gain set")
        
        // When - I adjust it slightly
        let adjustedGain: Float = 2.7
        try await equaliser.setBandGain(5, gain: adjustedGain)
        
        // Then - The band should reflect the new gain
        let newGain = try await equaliser.getBandGain(5)
        XCTAssertEqual(newGain, adjustedGain, accuracy: 0.01, "Band should reflect adjusted gain")
    }
    
    /// BDD: As a user, I want to see all my equaliser band settings at once
    func testViewAllBandSettings() async throws {
        // Given - I have configured multiple bands
        try await equaliser.setBandGain(0, gain: 3.0)
        try await equaliser.setBandGain(3, gain: -2.0)
        try await equaliser.setBandGain(7, gain: 4.0)
        
        // When - I view all bands
        let bands = await equaliser.getBands()
        
        // Then - I should see all 10 bands
        XCTAssertEqual(bands.count, 10, "Should have 10 bands")
        
        // And - The bands I configured should show the correct values
        XCTAssertEqual(bands[0].gain, 3.0, accuracy: 0.01, "Band 0 should show configured gain")
        XCTAssertEqual(bands[3].gain, -2.0, accuracy: 0.01, "Band 3 should show configured gain")
        XCTAssertEqual(bands[7].gain, 4.0, accuracy: 0.01, "Band 7 should show configured gain")
        
        // And - Other bands should be at default (0.0)
        XCTAssertEqual(bands[1].gain, 0.0, accuracy: 0.01, "Unconfigured bands should be flat")
        XCTAssertEqual(bands[2].gain, 0.0, accuracy: 0.01, "Unconfigured bands should be flat")
    }
    
    /// BDD: As a user, I want the equaliser to not modify audio when all bands are flat
    func testFlatEqualiserDoesNotModifyAudio() async throws {
        // Given - I have audio playing and all bands are flat
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9, -0.4, 0.7]
        
        // When - I process the audio through the equaliser
        let processed = try await equaliser.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - The audio should be unchanged
        XCTAssertEqual(processed.count, audioData.count, "Output length should match input")
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(processed[index], value, accuracy: 0.001, "Flat EQ should not modify audio at index \(index)")
        }
    }
    
    /// BDD: As a user, I want to process audio through the equaliser and hear the changes
    func testProcessAudioThroughEqualiser() async throws {
        // Given - I have audio and I've boosted the bass
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        
        try await equaliser.setBandGain(0, gain: 6.0) // Boost bass
        
        // When - I process the audio
        let processed = try await equaliser.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - The audio should be modified
        XCTAssertNotEqual(processed, audioData, "Audio should be modified by equaliser")
        XCTAssertEqual(processed.count, audioData.count, "Output length should match input")
    }
}
