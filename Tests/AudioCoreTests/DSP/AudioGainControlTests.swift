//
//  AudioGainControlTests.swift
//  AudioCoreTests
//
//  TDD tests for Audio Gain Control
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// TDD tests for AudioGainControl
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class AudioGainControlTests: XCTestCase {
    
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
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that global gain defaults to 0.0 dB
    func testGlobalGainDefaultsToZero() async {
        // Given - A new gain control instance
        // When - Get global gain
        let globalGain = await gainControl.getGlobalGain()
        
        // Then - Should be 0.0 dB
        XCTAssertEqual(globalGain, 0.0, accuracy: 0.001, "Global gain should default to 0.0 dB")
    }
    
    /// Test setting and getting global gain
    func testSetAndGetGlobalGain() async {
        // Given - A gain control instance
        // When - Set global gain to 3.0 dB
        await gainControl.setGlobalGain(3.0)
        let globalGain = await gainControl.getGlobalGain()
        
        // Then - Should return 3.0 dB
        XCTAssertEqual(globalGain, 3.0, accuracy: 0.001, "Global gain should be 3.0 dB")
    }
    
    /// Test setting and getting track-specific gain
    func testSetAndGetTrackGain() async {
        // Given - A track and gain control instance
        let track = MockFactory.makeTrack(title: "Test Track")
        
        // When - Set track gain to -6.0 dB
        await gainControl.setTrackGain(-6.0, for: track)
        let trackGain = await gainControl.getTrackGain(for: track)
        
        // Then - Should return -6.0 dB
        guard let gain = trackGain else {
            XCTFail("Track gain should not be nil")
            return
        }
        XCTAssertEqual(gain, -6.0, accuracy: 0.001, "Track gain should be -6.0 dB")
    }
    
    /// Test that effective gain combines track and global gain
    func testEffectiveGainCombinesTrackAndGlobalGain() async {
        // Given - A track, global gain of 2.0 dB, and track gain of -3.0 dB
        let track = MockFactory.makeTrack(title: "Test Track")
        await gainControl.setGlobalGain(2.0)
        await gainControl.setTrackGain(-3.0, for: track)
        
        // When - Get effective gain
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        // Then - Should be -1.0 dB (2.0 + (-3.0))
        XCTAssertEqual(effectiveGain, -1.0, accuracy: 0.001, "Effective gain should combine track and global gain")
    }
    
    /// Test that effective gain uses global gain when no track gain is set
    func testEffectiveGainUsesGlobalGainWhenNoTrackGain() async {
        // Given - A track and global gain of 5.0 dB
        let track = MockFactory.makeTrack(title: "Test Track")
        await gainControl.setGlobalGain(5.0)
        
        // When - Get effective gain
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        // Then - Should be 5.0 dB (global gain only)
        XCTAssertEqual(effectiveGain, 5.0, accuracy: 0.001, "Effective gain should use global gain when no track gain is set")
    }
    
    /// Test dB to linear conversion
    func testGainDBToLinearConversion() {
        // Given - Various dB values
        // When - Convert to linear
        let zeroDB = gainControl.gainDBToLinear(0.0)
        let minusSixDB = gainControl.gainDBToLinear(-6.0)
        let plusSixDB = gainControl.gainDBToLinear(6.0)
        let minusTwentyDB = gainControl.gainDBToLinear(-20.0)
        let plusTwentyDB = gainControl.gainDBToLinear(20.0)
        
        // Then - Should match expected linear values
        XCTAssertEqual(zeroDB, 1.0, accuracy: 0.001, "0.0 dB should equal 1.0 linear")
        XCTAssertEqual(minusSixDB, 0.5, accuracy: 0.01, "-6.0 dB should equal approximately 0.5 linear")
        XCTAssertEqual(plusSixDB, 2.0, accuracy: 0.01, "+6.0 dB should equal approximately 2.0 linear")
        XCTAssertEqual(minusTwentyDB, 0.1, accuracy: 0.01, "-20.0 dB should equal approximately 0.1 linear")
        XCTAssertEqual(plusTwentyDB, 10.0, accuracy: 0.1, "+20.0 dB should equal approximately 10.0 linear")
    }
    
    /// Test linear to dB conversion
    func testLinearToGainDBConversion() {
        // Given - Various linear values
        // When - Convert to dB
        let oneLinear = gainControl.linearToGainDB(1.0)
        let halfLinear = gainControl.linearToGainDB(0.5)
        let doubleLinear = gainControl.linearToGainDB(2.0)
        let tenthLinear = gainControl.linearToGainDB(0.1)
        let tenLinear = gainControl.linearToGainDB(10.0)
        
        // Then - Should match expected dB values
        XCTAssertEqual(oneLinear, 0.0, accuracy: 0.001, "1.0 linear should equal 0.0 dB")
        XCTAssertEqual(halfLinear, -6.0, accuracy: 0.1, "0.5 linear should equal approximately -6.0 dB")
        XCTAssertEqual(doubleLinear, 6.0, accuracy: 0.1, "2.0 linear should equal approximately 6.0 dB")
        XCTAssertEqual(tenthLinear, -20.0, accuracy: 0.1, "0.1 linear should equal approximately -20.0 dB")
        XCTAssertEqual(tenLinear, 20.0, accuracy: 0.1, "10.0 linear should equal approximately 20.0 dB")
    }
    
    /// Test roundtrip conversion (dB -> linear -> dB)
    func testRoundtripConversion() {
        // Given - Various dB values
        let testValues: [Float] = [-20.0, -6.0, 0.0, 6.0, 20.0, -12.0, 12.0]
        
        // When - Convert dB -> linear -> dB
        for originalDB in testValues {
            let linear = gainControl.gainDBToLinear(originalDB)
            let convertedDB = gainControl.linearToGainDB(linear)
            
            // Then - Should match original (within rounding error)
            XCTAssertEqual(convertedDB, originalDB, accuracy: 0.01, "Roundtrip conversion should preserve value for \(originalDB) dB")
        }
    }
    
    // MARK: - Boundary Conditions
    
    /// Test removing track gain reverts to global gain
    func testRemoveTrackGainRevertsToGlobalGain() async {
        // Given - A track with track gain and global gain
        let track = MockFactory.makeTrack(title: "Test Track")
        await gainControl.setGlobalGain(2.0)
        await gainControl.setTrackGain(-3.0, for: track)
        
        // When - Remove track gain
        await gainControl.removeTrackGain(for: track)
        let trackGain = await gainControl.getTrackGain(for: track)
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        // Then - Track gain should be nil, effective gain should be global gain
        XCTAssertNil(trackGain, "Track gain should be nil after removal")
        XCTAssertEqual(effectiveGain, 2.0, accuracy: 0.001, "Effective gain should revert to global gain")
    }
    
    /// Test extreme gain values
    func testExtremeGainValues() async {
        // Given - Extreme gain values
        let track = MockFactory.makeTrack(title: "Test Track")
        
        // When - Set very high and very low gains
        await gainControl.setGlobalGain(60.0) // +60 dB (very loud)
        await gainControl.setTrackGain(-60.0, for: track) // -60 dB (very quiet)
        
        // Then - Should handle extreme values
        let globalGain = await gainControl.getGlobalGain()
        let trackGain = await gainControl.getTrackGain(for: track)
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        XCTAssertEqual(globalGain, 60.0, accuracy: 0.001, "Should handle very high global gain")
        guard let gain = trackGain else {
            XCTFail("Track gain should not be nil")
            return
        }
        XCTAssertEqual(gain, -60.0, accuracy: 0.001, "Should handle very low track gain")
        XCTAssertEqual(effectiveGain, 0.0, accuracy: 0.001, "Effective gain should combine correctly")
    }
    
    /// Test zero gain
    func testZeroGain() async {
        // Given - A track
        let track = MockFactory.makeTrack(title: "Test Track")
        
        // When - Set both gains to zero
        await gainControl.setGlobalGain(0.0)
        await gainControl.setTrackGain(0.0, for: track)
        
        // Then - Effective gain should be zero
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        XCTAssertEqual(effectiveGain, 0.0, accuracy: 0.001, "Zero gain should result in zero effective gain")
    }
    
    /// Test multiple tracks with different gains
    func testMultipleTracksWithDifferentGains() async {
        // Given - Multiple tracks
        let track1 = MockFactory.makeTrack(id: UUID(), title: "Track 1")
        let track2 = MockFactory.makeTrack(id: UUID(), title: "Track 2")
        let track3 = MockFactory.makeTrack(id: UUID(), title: "Track 3")
        
        // When - Set different gains for each track
        await gainControl.setGlobalGain(2.0)
        await gainControl.setTrackGain(-3.0, for: track1)
        await gainControl.setTrackGain(5.0, for: track2)
        // track3 has no track gain
        
        // Then - Each track should have correct effective gain
        let effective1 = await gainControl.getEffectiveGain(for: track1)
        let effective2 = await gainControl.getEffectiveGain(for: track2)
        let effective3 = await gainControl.getEffectiveGain(for: track3)
        
        XCTAssertEqual(effective1, -1.0, accuracy: 0.001, "Track 1 effective gain should be -1.0 dB")
        XCTAssertEqual(effective2, 7.0, accuracy: 0.001, "Track 2 effective gain should be 7.0 dB")
        XCTAssertEqual(effective3, 2.0, accuracy: 0.001, "Track 3 effective gain should be 2.0 dB (global only)")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that setting gain then removing it restores original state
    func testSetThenRemoveGainRestoresState() async {
        // Given - A track with initial global gain
        let track = MockFactory.makeTrack(title: "Test Track")
        await gainControl.setGlobalGain(1.0)
        let initialEffective = await gainControl.getEffectiveGain(for: track)
        
        // When - Set track gain then remove it
        await gainControl.setTrackGain(-2.0, for: track)
        await gainControl.removeTrackGain(for: track)
        let finalEffective = await gainControl.getEffectiveGain(for: track)
        
        // Then - Should restore to initial state
        XCTAssertEqual(finalEffective, initialEffective, accuracy: 0.001, "Removing track gain should restore original effective gain")
    }
    
    /// Test that changing global gain affects all tracks
    func testChangingGlobalGainAffectsAllTracks() async {
        // Given - Multiple tracks with track-specific gains
        let track1 = MockFactory.makeTrack(id: UUID(), title: "Track 1")
        let track2 = MockFactory.makeTrack(id: UUID(), title: "Track 2")
        
        await gainControl.setGlobalGain(2.0)
        await gainControl.setTrackGain(-3.0, for: track1)
        await gainControl.setTrackGain(1.0, for: track2)
        
        let initialEffective1 = await gainControl.getEffectiveGain(for: track1)
        let initialEffective2 = await gainControl.getEffectiveGain(for: track2)
        
        // When - Change global gain
        await gainControl.setGlobalGain(5.0)
        
        // Then - Both tracks should reflect the change
        let newEffective1 = await gainControl.getEffectiveGain(for: track1)
        let newEffective2 = await gainControl.getEffectiveGain(for: track2)
        
        let delta1 = newEffective1 - initialEffective1
        let delta2 = newEffective2 - initialEffective2
        
        XCTAssertEqual(delta1, 3.0, accuracy: 0.001, "Track 1 effective gain should increase by 3.0 dB")
        XCTAssertEqual(delta2, 3.0, accuracy: 0.001, "Track 2 effective gain should increase by 3.0 dB")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that gain calculations match manual calculations
    func testGainCalculationsMatchManualCalculations() async {
        // Given - Known gain values
        let globalGain: Float = 3.0
        let trackGain: Float = -2.0
        let expectedEffective = globalGain + trackGain // 1.0 dB
        
        let track = MockFactory.makeTrack(title: "Test Track")
        await gainControl.setGlobalGain(globalGain)
        await gainControl.setTrackGain(trackGain, for: track)
        
        // When - Get effective gain
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        
        // Then - Should match manual calculation
        XCTAssertEqual(effectiveGain, expectedEffective, accuracy: 0.001, "Effective gain should match manual calculation")
    }
    
    /// Test that dB to linear conversion matches formula: linear = 10^(dB/20)
    func testDBToLinearMatchesFormula() {
        // Given - Known dB values with their exact linear equivalents
        let testCases: [(Float, Float)] = [
            (0.0, 1.0),      // 0 dB = 1.0 (exact)
            (-6.0, 0.501187),     // -6 dB ≈ 0.501187 (10^(-6/20))
            (6.0, 1.995262),      // 6 dB ≈ 1.995262 (10^(6/20))
            (-20.0, 0.1),    // -20 dB = 0.1 (exact)
            (20.0, 10.0)     // 20 dB = 10.0 (exact)
        ]
        
        // When - Convert using implementation
        for (db, expectedLinear) in testCases {
            let linear = gainControl.gainDBToLinear(db)
            
            // Then - Should match expected (within reasonable tolerance)
            XCTAssertEqual(linear, expectedLinear, accuracy: 0.01, "\(db) dB should convert to approximately \(expectedLinear) linear")
        }
    }
    
    // MARK: - Error Conditions
    
    /// Test that gain control handles NaN values gracefully
    func testHandlesNaNValues() async {
        // Given - NaN gain value
        // When - Set NaN gain
        await gainControl.setGlobalGain(Float.nan)
        
        // Then - Should handle gracefully (implementation may clamp or reject)
        let globalGain = await gainControl.getGlobalGain()
        // Implementation should either reject NaN or clamp it
        XCTAssertFalse(globalGain.isNaN, "Global gain should not be NaN")
    }
    
    /// Test that gain control handles infinity values gracefully
    func testHandlesInfinityValues() async {
        // Given - Infinity gain value
        _ = MockFactory.makeTrack(title: "Test Track")
        
        // When - Set infinity gain
        await gainControl.setGlobalGain(Float.infinity)
        
        // Then - Should handle gracefully (implementation may clamp or reject)
        let globalGain = await gainControl.getGlobalGain()
        XCTAssertFalse(globalGain.isInfinite, "Global gain should not be infinite")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test performance of gain calculations for many tracks
    func testGainCalculationPerformance() async {
        // Given - Many tracks with different gains
        var tracks: [Shared.Track] = []
        for i in 0..<1000 {
            let track = MockFactory.makeTrack(id: UUID(), title: "Track \(i)")
            tracks.append(track)
            await gainControl.setTrackGain(Float(i % 20) - 10.0, for: track) // -10 to +10 dB
        }
        
        // When - Calculate effective gain for all tracks and measure time
        let startTime = Date()
        for track in tracks {
            _ = await gainControl.getEffectiveGain(for: track)
        }
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (e.g., < 1 second for 1000 tracks)
        XCTAssertLessThan(duration, 1.0, "Gain calculation for 1000 tracks should complete within 1 second")
    }
    
    // MARK: - Edge Cases
    
    /// Test that gain control works with tracks that have same ID but different instances
    func testGainControlWithTrackIdentity() async {
        // Given - Two track instances with same ID
        let trackID = UUID()
        let track1 = MockFactory.makeTrack(id: trackID, title: "Track 1")
        let track2 = MockFactory.makeTrack(id: trackID, title: "Track 2")
        
        // When - Set gain for track1
        await gainControl.setTrackGain(-5.0, for: track1)
        
        // Then - track2 should also have the gain (same ID)
        let track2Gain = await gainControl.getTrackGain(for: track2)
        guard let gain2 = track2Gain else {
            XCTFail("Track 2 gain should not be nil")
            return
        }
        XCTAssertEqual(gain2, -5.0, accuracy: 0.001, "Tracks with same ID should share gain")
    }
    
    /// Test that gain control handles very small gain values
    func testVerySmallGainValues() async {
        // Given - Very small gain values
        let track = MockFactory.makeTrack(title: "Test Track")
        
        // When - Set very small gains
        await gainControl.setGlobalGain(0.001)
        await gainControl.setTrackGain(-0.001, for: track)
        
        // Then - Should handle correctly
        let effectiveGain = await gainControl.getEffectiveGain(for: track)
        XCTAssertEqual(effectiveGain, 0.0, accuracy: 0.01, "Very small gains should be handled correctly")
    }
    
    /// Test conversion edge cases (zero, negative linear values)
    func testConversionEdgeCases() {
        // Given - Edge case values
        // When - Convert edge cases
        let zeroLinear = gainControl.linearToGainDB(0.0)
        let negativeLinear = gainControl.linearToGainDB(-1.0)
        
        // Then - Should handle edge cases (zero should be -infinity or very negative, negative should be NaN or handled)
        // Implementation may handle these differently, but should not crash
        XCTAssertTrue(zeroLinear.isInfinite || zeroLinear < -100, "Zero linear should map to -infinity or very negative dB")
        XCTAssertTrue(negativeLinear.isNaN || negativeLinear < 0, "Negative linear should be NaN or negative dB")
    }
}
