//
//  AudioGainControlBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for Audio Gain Control
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD tests for Audio Gain Control
/// User-centric scenarios following "As a user, I want to..." format
@MainActor
final class AudioGainControlBDDTests: XCTestCase {
    
    var gainControl: AudioGainControl!
    private let globalGainKey = "audientia.settings.globalGain"
    
    override func setUp() async throws {
        try await super.setUp()
        // Clear persisted global gain to ensure tests start with clean state
        UserDefaults.standard.removeObject(forKey: globalGainKey)
        gainControl = AudioGainControl()
    }
    
    override func tearDown() async throws {
        gainControl = nil
        // Clean up persisted global gain after test
        UserDefaults.standard.removeObject(forKey: globalGainKey)
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Adjust Gain for Specific Track
    
    /// BDD: As a user, I want to adjust the gain for a specific track so that it plays at my preferred volume
    func testUserAdjustsGainForSpecificTrack() async {
        // Given - I have a track playing
        let track = MockFactory.makeTrack(title: "My Favorite Song")
        
        // When - I adjust the gain to +3 dB for this track
        await gainControl.setTrackGain(3.0, for: track)
        
        // Then - The track should have a gain of +3 dB
        let trackGain = await gainControl.getTrackGain(for: track)
        XCTAssertNotNil(trackGain, "Track should have a gain setting")
        if let gain = trackGain {
            XCTAssertEqual(gain, 3.0, accuracy: 0.001, "Track gain should be +3 dB")
        }
    }
    
    /// BDD: As a user, I want to reduce the gain for a quiet track so it doesn't play too loudly
    func testUserReducesGainForQuietTrack() async {
        // Given - I have a track that's too quiet
        let track: Shared.Track = MockFactory.makeTrack(title: "Quiet Song")
        
        // When - I reduce the gain by -6 dB
        await gainControl.setTrackGain(-6.0, for: track)
        
        // Then - The track should have reduced gain
        let trackGain = await gainControl.getTrackGain(for: track)
        XCTAssertNotNil(trackGain, "Track should have a gain setting")
        if let gain = trackGain {
            XCTAssertEqual(gain, -6.0, accuracy: 0.001, "Track gain should be -6 dB")
        }
    }
    
    /// BDD: As a user, I want to remove track-specific gain so the track uses the global gain setting
    func testUserRemovesTrackSpecificGain() async {
        // Given - I have a track with a specific gain setting
        let track: Shared.Track = MockFactory.makeTrack(title: "Custom Gain Song")
        await gainControl.setGlobalGain(2.0)
        await gainControl.setTrackGain(-3.0, for: track)
        
        // When - I remove the track-specific gain
        await gainControl.removeTrackGain(for: track)
        
        // Then - The track should use the global gain
        let trackGain = await gainControl.getTrackGain(for: track)
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        XCTAssertNil(trackGain, "Track should not have a specific gain setting")
        XCTAssertEqual(effectiveGain, 2.0, accuracy: 0.001, "Effective gain should match global gain")
    }
    
    // MARK: - User Scenario: Adjust Global Gain
    
    /// BDD: As a user, I want to adjust the global gain so all tracks play at my preferred volume
    func testUserAdjustsGlobalGain() async {
        // Given - I have multiple tracks in my library
        let track1: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Song 1")
        let track2: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Song 2")
        
        // When - I set the global gain to +2 dB
        await gainControl.setGlobalGain(2.0)
        
        // Then - All tracks should use this global gain
        let globalGain = await gainControl.getGlobalGain()
        let effectiveGain1 = await gainControl.getEffectiveGain(for: track1)
        let effectiveGain2 = await gainControl.getEffectiveGain(for: track2)
        
        XCTAssertEqual(globalGain, 2.0, accuracy: 0.001, "Global gain should be +2 dB")
        XCTAssertEqual(effectiveGain1, 2.0, accuracy: 0.001, "Track 1 should use global gain")
        XCTAssertEqual(effectiveGain2, 2.0, accuracy: 0.001, "Track 2 should use global gain")
    }
    
    /// BDD: As a user, I want to combine track-specific and global gain so I can fine-tune individual tracks
    func testUserCombinesTrackAndGlobalGain() async {
        // Given - I have a track and both global and track-specific gain settings
        let track: Shared.Track = MockFactory.makeTrack(title: "Fine-Tuned Song")
        await gainControl.setGlobalGain(2.0)
        await gainControl.setTrackGain(-3.0, for: track)
        
        // When - I check the effective gain
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        // Then - The effective gain should combine both settings
        XCTAssertEqual(effectiveGain, -1.0, accuracy: 0.001, "Effective gain should be -1.0 dB (2.0 + (-3.0))")
    }
    
    // MARK: - User Scenario: Convert Between dB and Linear
    
    /// BDD: As a user, I want to understand how gain values relate to volume changes
    func testUserUnderstandsGainToVolumeRelationship() {
        // Given - I know that +6 dB doubles the volume
        // When - I convert +6 dB to linear
        let linear = gainControl.gainDBToLinear(6.0)
        
        // Then - I should see it's approximately 2.0 (double)
        XCTAssertEqual(linear, 2.0, accuracy: 0.1, "+6 dB should approximately double the volume")
    }
    
    /// BDD: As a user, I want to understand that -6 dB halves the volume
    func testUserUnderstandsNegativeGainReducesVolume() {
        // Given - I know that -6 dB halves the volume
        // When - I convert -6 dB to linear
        let linear = gainControl.gainDBToLinear(-6.0)
        
        // Then - I should see it's approximately 0.5 (half)
        XCTAssertEqual(linear, 0.5, accuracy: 0.1, "-6 dB should approximately halve the volume")
    }
    
    /// BDD: As a user, I want to know that 0 dB means no change in volume
    func testUserUnderstandsZeroGainMeansNoChange() {
        // Given - I set gain to 0 dB
        // When - I convert 0 dB to linear
        let linear = gainControl.gainDBToLinear(0.0)
        
        // Then - I should see it's 1.0 (no change)
        XCTAssertEqual(linear, 1.0, accuracy: 0.001, "0 dB should mean no volume change (1.0)")
    }
    
    // MARK: - User Scenario: Multiple Tracks with Different Gains
    
    /// BDD: As a user, I want to set different gains for different tracks so each plays at its optimal volume
    func testUserSetsDifferentGainsForDifferentTracks() async {
        // Given - I have multiple tracks that need different gain adjustments
        let quietTrack: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Quiet Track")
        let loudTrack: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Loud Track")
        let normalTrack: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Normal Track")
        
        // When - I set different gains for each
        await gainControl.setTrackGain(6.0, for: quietTrack)   // Boost quiet track
        await gainControl.setTrackGain(-6.0, for: loudTrack)   // Reduce loud track
        // Normal track uses default (no track-specific gain)
        
        // Then - Each track should have its own gain setting
        let quietGain = await gainControl.getTrackGain(for: quietTrack)
        let loudGain = await gainControl.getTrackGain(for: loudTrack)
        let normalGain = await gainControl.getTrackGain(for: normalTrack)
        
        XCTAssertNotNil(quietGain, "Quiet track should have gain")
        if let gain = quietGain {
            XCTAssertEqual(gain, 6.0, accuracy: 0.001, "Quiet track should have +6 dB gain")
        }
        
        XCTAssertNotNil(loudGain, "Loud track should have gain")
        if let gain = loudGain {
            XCTAssertEqual(gain, -6.0, accuracy: 0.001, "Loud track should have -6 dB gain")
        }
        
        XCTAssertNil(normalGain, "Normal track should not have track-specific gain")
    }
    
    // MARK: - User Scenario: Reset to Default
    
    /// BDD: As a user, I want to reset all gain settings so I can start fresh
    func testUserResetsAllGainSettings() async {
        // Given - I have tracks with various gain settings
        let track1: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Track 1")
        let track2: Shared.Track = MockFactory.makeTrack(id: UUID(), title: "Track 2")
        
        await gainControl.setGlobalGain(5.0)
        await gainControl.setTrackGain(3.0, for: track1)
        await gainControl.setTrackGain(-2.0, for: track2)
        
        // When - I reset global gain to 0 dB and remove track-specific gains
        await gainControl.setGlobalGain(0.0)
        await gainControl.removeTrackGain(for: track1)
        await gainControl.removeTrackGain(for: track2)
        
        // Then - All tracks should have 0 dB effective gain
        let globalGain = await gainControl.getGlobalGain()
        let effectiveGain1 = await gainControl.getEffectiveGain(for: track1)
        let effectiveGain2 = await gainControl.getEffectiveGain(for: track2)
        
        XCTAssertEqual(globalGain, 0.0, accuracy: 0.001, "Global gain should be reset to 0 dB")
        XCTAssertEqual(effectiveGain1, 0.0, accuracy: 0.001, "Track 1 effective gain should be 0 dB")
        XCTAssertEqual(effectiveGain2, 0.0, accuracy: 0.001, "Track 2 effective gain should be 0 dB")
    }
    
    // MARK: - User Scenario: Fine-Tune Volume
    
    /// BDD: As a user, I want to fine-tune volume using small gain adjustments
    func testUserFineTunesVolumeWithSmallAdjustments() async {
        // Given - I have a track that's almost at the right volume
        let track: Shared.Track = MockFactory.makeTrack(title: "Almost Perfect Song")
        
        // When - I make small gain adjustments
        await gainControl.setTrackGain(1.0, for: track)
        var effectiveGain = await gainControl.getEffectiveGain(for: track)
        XCTAssertEqual(effectiveGain, 1.0, accuracy: 0.001, "Initial adjustment should be +1 dB")
        
        await gainControl.setTrackGain(1.5, for: track)
        effectiveGain = await gainControl.getEffectiveGain(for: track)
        XCTAssertEqual(effectiveGain, 1.5, accuracy: 0.001, "Fine-tuned adjustment should be +1.5 dB")
        
        await gainControl.setTrackGain(1.2, for: track)
        effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        // Then - I can precisely control the volume
        XCTAssertEqual(effectiveGain, 1.2, accuracy: 0.001, "Final fine-tuned adjustment should be +1.2 dB")
    }
}
