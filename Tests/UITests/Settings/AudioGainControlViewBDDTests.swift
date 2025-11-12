//
//  AudioGainControlViewBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for Audio Gain Control View
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import AudioCore
@testable import Shared

/// BDD Scenarios for Audio Gain Control View
@MainActor
final class AudioGainControlViewBDDTests: XCTestCase {
    
    private var mockGainControl: MockAudioGainControl!
    
    override func setUp() {
        super.setUp()
        mockGainControl = MockAudioGainControl()
    }
    
    override func tearDown() {
        mockGainControl = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Adjust Global Gain
    
    /// BDD: As a user, when I adjust the global gain slider, then all tracks should play at the adjusted volume
    func testUserAdjustsGlobalGain() async {
        // Given - Global gain is at 0 dB
        let initialGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(initialGain, 0.0, accuracy: 0.1, "Global gain should start at 0 dB")
        
        // When - User increases global gain to +3 dB
        await mockGainControl.setGlobalGain(3.0)
        let updatedGain = await mockGainControl.getGlobalGain()
        
        // Then - Global gain should be +3 dB
        XCTAssertEqual(updatedGain, 3.0, accuracy: 0.1, "Global gain should be +3 dB")
        XCTAssertTrue(mockGainControl.setGlobalGainCalled, "setGlobalGain should have been called")
    }
    
    // MARK: - BDD Scenario 2: Adjust Track-Specific Gain
    
    /// BDD: As a user, when I adjust gain for a specific track, then only that track should be affected
    func testUserAdjustsTrackGain() async {
        // Given - A track with no specific gain
        let track = makeTrack(title: "Test Track")
        let initialTrackGain = await mockGainControl.getTrackGain(for: track)
        XCTAssertNil(initialTrackGain, "Track should have no specific gain initially")
        
        // When - User sets track gain to +2 dB
        await mockGainControl.setTrackGain(2.0, for: track)
        let trackGain = await mockGainControl.getTrackGain(for: track)
        
        // Then - Track should have +2 dB gain
        XCTAssertNotNil(trackGain, "Track gain should not be nil")
        if let gain = trackGain {
            XCTAssertEqual(gain, 2.0, accuracy: 0.1, "Track gain should be +2 dB")
        }
        XCTAssertTrue(mockGainControl.setTrackGainCalled, "setTrackGain should have been called")
    }
    
    // MARK: - BDD Scenario 3: Effective Gain Calculation
    
    /// BDD: As a user, when I have both global and track gain set, then the effective gain should be the sum
    func testEffectiveGainCalculation() async {
        // Given - Global gain is +2 dB and track gain is +3 dB
        await mockGainControl.setGlobalGain(2.0)
        let track = makeTrack(title: "Test Track")
        await mockGainControl.setTrackGain(3.0, for: track)
        
        // When - User views effective gain
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        
        // Then - Effective gain should be +5 dB (2 + 3)
        XCTAssertEqual(effectiveGain, 5.0, accuracy: 0.1, "Effective gain should be sum of global and track gain")
    }
    
    // MARK: - BDD Scenario 4: Remove Track Gain
    
    /// BDD: As a user, when I remove track-specific gain, then the track should use only global gain
    func testUserRemovesTrackGain() async {
        // Given - Track has specific gain of +3 dB
        let track = makeTrack(title: "Test Track")
        await mockGainControl.setTrackGain(3.0, for: track)
        let initialGain = await mockGainControl.getTrackGain(for: track)
        XCTAssertNotNil(initialGain, "Track should have gain")
        if let gain = initialGain {
            XCTAssertEqual(gain, 3.0, accuracy: 0.1, "Track should have +3 dB gain")
        }
        
        // When - User removes track gain
        await mockGainControl.removeTrackGain(for: track)
        let removedGain = await mockGainControl.getTrackGain(for: track)
        
        // Then - Track gain should be nil
        XCTAssertNil(removedGain, "Track gain should be removed")
        XCTAssertTrue(mockGainControl.removeTrackGainCalled, "removeTrackGain should have been called")
    }
    
    // MARK: - BDD Scenario 5: Multiple Tracks with Different Gains
    
    /// BDD: As a user, when I set different gains for different tracks, then each track should maintain its own gain
    func testMultipleTracksWithDifferentGains() async {
        // Given - Two different tracks
        let track1 = makeTrack(id: UUID(), title: "Track 1")
        let track2 = makeTrack(id: UUID(), title: "Track 2")
        
        // When - User sets different gains for each track
        await mockGainControl.setTrackGain(2.0, for: track1)
        await mockGainControl.setTrackGain(-1.0, for: track2)
        
        // Then - Each track should have its own gain
        let gain1 = await mockGainControl.getTrackGain(for: track1)
        let gain2 = await mockGainControl.getTrackGain(for: track2)
        XCTAssertNotNil(gain1, "Track 1 should have gain")
        XCTAssertNotNil(gain2, "Track 2 should have gain")
        if let g1 = gain1, let g2 = gain2 {
            XCTAssertEqual(g1, 2.0, accuracy: 0.1, "Track 1 should have +2 dB")
            XCTAssertEqual(g2, -1.0, accuracy: 0.1, "Track 2 should have -1 dB")
        }
    }
    
    // MARK: - Boundary Condition Tests
    
    /// Test with extreme gain values
    func testExtremeGainValues() async {
        // When - User sets maximum gain (+20 dB)
        await mockGainControl.setGlobalGain(20.0)
        let maxGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(maxGain, 20.0, accuracy: 0.1, "Should accept +20 dB")
        
        // When - User sets minimum gain (-20 dB)
        await mockGainControl.setGlobalGain(-20.0)
        let minGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(minGain, -20.0, accuracy: 0.1, "Should accept -20 dB")
    }
    
    // MARK: - Inverse Relationship Tests
    
    /// Test gain roundtrip: set then get
    func testGainRoundtrip() async {
        // Given - A track
        let track = makeTrack(title: "Test Track")
        
        // When - User sets gain then gets it back
        await mockGainControl.setTrackGain(5.0, for: track)
        let retrievedGain = await mockGainControl.getTrackGain(for: track)
        
        // Then - Retrieved gain should match set gain
        XCTAssertNotNil(retrievedGain, "Retrieved gain should not be nil")
        if let gain = retrievedGain {
            XCTAssertEqual(gain, 5.0, accuracy: 0.1, "Retrieved gain should match set gain")
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeTrack(
        id: UUID = UUID(),
        title: String = "Test Track"
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
}
