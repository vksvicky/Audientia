//
//  EQInterfaceBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for Equalizer Interface
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import AudioCore
@testable import Shared

/// BDD Scenarios for EQ Interface
/// Following "Given-When-Then" pattern for user stories
@MainActor
final class EQInterfaceBDDTests: XCTestCase {
    
    private var mockEqualizer: MockAudioEqualizer!
    
    override func setUp() {
        super.setUp()
        mockEqualizer = MockAudioEqualizer()
    }
    
    override func tearDown() {
        mockEqualizer = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: View Equalizer
    
    /// BDD: As a user, when I open the equalizer settings, then I should see all 10 frequency bands
    func testUserViewsEqualizerBands() async {
        // Given - Equalizer is initialized
        let bands = await mockEqualizer.getBands()
        
        // When - User views the equalizer interface
        // (In a real test, we would instantiate the view)
        
        // Then - All 10 bands should be available
        XCTAssertEqual(bands.count, 10, "Equalizer should have 10 bands")
        XCTAssertEqual(bands[0].frequency, 31.0, accuracy: 0.1, "First band should be 31 Hz")
        XCTAssertEqual(bands[9].frequency, 16000.0, accuracy: 0.1, "Last band should be 16 kHz")
    }
    
    // MARK: - BDD Scenario 2: Adjust Bass
    
    /// BDD: As a user, when I increase the bass slider, then the low frequencies should be boosted
    func testUserAdjustsBass() async throws {
        // Given - Equalizer is at flat settings
        let initialBands = await mockEqualizer.getBands()
        XCTAssertEqual(initialBands[0].gain, 0.0, "Bass should start at 0 dB")
        
        // When - User increases bass (first band) to +6 dB
        try await mockEqualizer.setBandGain(0, gain: 6.0)
        let updatedBands = await mockEqualizer.getBands()
        
        // Then - Bass band should be at +6 dB
        XCTAssertEqual(updatedBands[0].gain, 6.0, accuracy: 0.1, "Bass should be boosted to +6 dB")
        XCTAssertTrue(mockEqualizer.setBandGainCalled, "setBandGain should have been called")
    }
    
    // MARK: - BDD Scenario 3: Apply Preset
    
    /// BDD: As a user, when I select a bass boost preset, then the low frequency bands should be adjusted
    func testUserAppliesBassBoostPreset() async throws {
        // Given - Equalizer is at flat settings
        let initialBands = await mockEqualizer.getBands()
        XCTAssertEqual(initialBands[0].gain, 0.0, "Should start flat")
        
        // When - User applies bass boost preset
        // Bass boost: [6.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        try await mockEqualizer.setBandGain(0, gain: 6.0)
        try await mockEqualizer.setBandGain(1, gain: 4.0)
        try await mockEqualizer.setBandGain(2, gain: 2.0)
        let updatedBands = await mockEqualizer.getBands()
        
        // Then - Low frequency bands should be boosted
        XCTAssertEqual(updatedBands[0].gain, 6.0, accuracy: 0.1, "First band should be +6 dB")
        XCTAssertEqual(updatedBands[1].gain, 4.0, accuracy: 0.1, "Second band should be +4 dB")
        XCTAssertEqual(updatedBands[2].gain, 2.0, accuracy: 0.1, "Third band should be +2 dB")
        XCTAssertEqual(updatedBands[3].gain, 0.0, accuracy: 0.1, "Fourth band should remain flat")
    }
    
    // MARK: - BDD Scenario 4: Reset to Flat
    
    /// BDD: As a user, when I reset the equalizer, then all bands should return to 0 dB
    func testUserResetsEqualizer() async throws {
        // Given - Equalizer has some adjustments
        try await mockEqualizer.setBandGain(0, gain: 6.0)
        try await mockEqualizer.setBandGain(5, gain: -3.0)
        let adjustedBands = await mockEqualizer.getBands()
        XCTAssertNotEqual(adjustedBands[0].gain, 0.0, "Bass should be adjusted")
        
        // When - User resets the equalizer
        await mockEqualizer.reset()
        let resetBands = await mockEqualizer.getBands()
        
        // Then - All bands should be at 0 dB
        for (index, band) in resetBands.enumerated() {
            XCTAssertEqual(band.gain, 0.0, accuracy: 0.1, "Band \(index) should be reset to 0 dB")
        }
        XCTAssertTrue(mockEqualizer.resetCalled, "reset should have been called")
    }
    
    // MARK: - BDD Scenario 5: Enable/Disable Equalizer
    
    /// BDD: As a user, when I toggle the equalizer off, then audio should bypass the equalizer
    func testUserTogglesEqualizer() async {
        // Given - Equalizer is enabled
        let initialEnabled = await mockEqualizer.isEnabled()
        XCTAssertTrue(initialEnabled, "Equalizer should start enabled")
        
        // When - User disables the equalizer
        await mockEqualizer.setEnabled(false)
        let disabled = await mockEqualizer.isEnabled()
        
        // Then - Equalizer should be disabled
        XCTAssertFalse(disabled, "Equalizer should be disabled")
        XCTAssertTrue(mockEqualizer.setEnabledCalled, "setEnabled should have been called")
        
        // When - User enables it again
        await mockEqualizer.setEnabled(true)
        let reEnabled = await mockEqualizer.isEnabled()
        
        // Then - Equalizer should be enabled again
        XCTAssertTrue(reEnabled, "Equalizer should be enabled again")
    }
    
    // MARK: - BDD Scenario 6: Adjust Multiple Bands
    
    /// BDD: As a user, when I adjust multiple frequency bands, then each band should maintain its setting
    func testUserAdjustsMultipleBands() async throws {
        // Given - Equalizer is at flat settings
        _ = await mockEqualizer.getBands()
        
        // When - User adjusts multiple bands
        try await mockEqualizer.setBandGain(0, gain: 4.0)  // Bass
        try await mockEqualizer.setBandGain(5, gain: 2.0)  // Mid
        try await mockEqualizer.setBandGain(9, gain: 3.0)  // Treble
        let updatedBands = await mockEqualizer.getBands()
        
        // Then - Each band should maintain its setting
        XCTAssertEqual(updatedBands[0].gain, 4.0, accuracy: 0.1, "Bass should be +4 dB")
        XCTAssertEqual(updatedBands[5].gain, 2.0, accuracy: 0.1, "Mid should be +2 dB")
        XCTAssertEqual(updatedBands[9].gain, 3.0, accuracy: 0.1, "Treble should be +3 dB")
        
        // Other bands should remain unchanged
        XCTAssertEqual(updatedBands[1].gain, 0.0, accuracy: 0.1, "Unchanged band should remain flat")
    }
    
    // MARK: - Boundary Condition Tests
    
    /// Test with extreme gain values
    func testExtremeGainValues() async throws {
        // Given - Equalizer is at flat settings
        
        // When - User sets maximum gain (+20 dB)
        try await mockEqualizer.setBandGain(0, gain: 20.0)
        let maxBands = await mockEqualizer.getBands()
        XCTAssertEqual(maxBands[0].gain, 20.0, accuracy: 0.1, "Should accept +20 dB")
        
        // When - User sets minimum gain (-20 dB)
        try await mockEqualizer.setBandGain(0, gain: -20.0)
        let minBands = await mockEqualizer.getBands()
        XCTAssertEqual(minBands[0].gain, -20.0, accuracy: 0.1, "Should accept -20 dB")
    }
    
    /// Test with invalid band index
    func testInvalidBandIndex() async {
        // Given - Equalizer has 10 bands (indices 0-9)
        
        // When - User tries to access invalid band index
        do {
            try await mockEqualizer.setBandGain(10, gain: 5.0)
            XCTFail("Should throw error for invalid band index")
        } catch {
            // Then - Should throw appropriate error
            if let eqError = error as? AudioEqualizerError {
                switch eqError {
                case .invalidBandIndex(let index):
                    XCTAssertEqual(index, 10, "Error should indicate invalid index")
                default:
                    XCTFail("Wrong error type")
                }
            } else {
                XCTFail("Should throw AudioEqualizerError")
            }
        }
    }
    
    // MARK: - Error Condition Tests
    
    /// Test handling of processing errors
    func testProcessingError() async {
        // Given - Equalizer is configured to fail processing
        mockEqualizer.shouldFailProcess = true
        
        // When - User tries to process audio
        do {
            let audioData: [Float] = [0.1, 0.2, 0.3]
            _ = try await mockEqualizer.process(audioData: audioData, sampleRate: 44100, channels: 2)
            XCTFail("Should throw error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(mockEqualizer.processCalled, "process should have been called")
        }
    }
}
