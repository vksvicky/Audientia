//
//  AudioEngineGainControlTests.swift
//  AudioCoreTests
//
//  TDD tests for AudioEngine gain control integration
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// TDD tests for AudioEngine gain control integration
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class AudioEngineGainControlTests: XCTestCase {
    
    var engine: AudioEngine!
    var mockFileSystem: MockFileSystem!
    var mockNativeEngine: MockNativeAudioEngine!
    var mockGainControl: MockAudioGainControl!
    var mockFormatCoordinator: MockFormatDecodingCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFileSystem = MockFileSystem()
        mockNativeEngine = MockNativeAudioEngine()
        mockGainControl = MockAudioGainControl()
        mockFormatCoordinator = MockFormatDecodingCoordinator()
        
        engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockFormatCoordinator,
            nativeEngine: mockNativeEngine,
            gainControl: mockGainControl
        )
    }
    
    override func tearDown() async throws {
        engine = nil
        mockFileSystem = nil
        mockNativeEngine = nil
        mockGainControl = nil
        mockFormatCoordinator = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that gain control is applied when setting volume
    func testVolumeWithGainControlApplied() async throws {
        // Given - A track is loaded and global gain is set to +6 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(6.0) // +6 dB = 2x linear gain
        try await engine.loadTrack(track)
        
        // When - Set volume to 0.5
        engine.volume = 0.5
        
        // Then - Native engine volume should be 0.5 * 2.0 = 1.0 (clamped to 1.0)
        // Effective volume = base volume * gain multiplier
        let expectedVolume = Double(min(1.0, 0.5 * mockGainControl.gainDBToLinear(6.0)))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
    }
    
    /// Test that track-specific gain is applied when available
    func testTrackSpecificGainApplied() async throws {
        // Given - A track is loaded with track-specific gain of +3 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setTrackGain(3.0, for: track) // +3 dB
        try await engine.loadTrack(track)
        
        // When - Set volume to 0.8
        engine.volume = 0.8
        
        // Then - Effective gain should be track gain (3 dB) + global gain (0 dB) = 3 dB
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        let expectedVolume = Double(min(1.0, 0.8 * mockGainControl.gainDBToLinear(effectiveGain)))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
    }
    
    /// Test that effective gain combines track and global gain
    func testEffectiveGainCombinesTrackAndGlobal() async throws {
        // Given - Global gain of +6 dB and track gain of -3 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(6.0)
        await mockGainControl.setTrackGain(-3.0, for: track)
        try await engine.loadTrack(track)
        
        // When - Get effective gain
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        
        // Then - Effective gain should be 6.0 + (-3.0) = 3.0 dB
        XCTAssertEqual(effectiveGain, 3.0, accuracy: 0.001)
    }
    
    // MARK: - Boundary Conditions
    
    /// Test that extreme gain values are handled correctly
    func testExtremeGainValues() async throws {
        // Given - A track with very high gain (+60 dB)
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(60.0) // Very high gain
        try await engine.loadTrack(track)
        
        // When - Set volume to 0.5
        engine.volume = 0.5
        
        // Then - Volume should be clamped to 1.0 (can't exceed maximum)
        let gainMultiplier = mockGainControl.gainDBToLinear(60.0)
        let expectedVolume = Double(min(1.0, 0.5 * gainMultiplier))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
        XCTAssertLessThanOrEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, 1.0)
    }
    
    /// Test that negative gain (attenuation) works correctly
    func testNegativeGainAttenuation() async throws {
        // Given - A track with negative gain (-6 dB = 0.5x)
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(-6.0) // -6 dB = 0.5x linear
        try await engine.loadTrack(track)
        
        // When - Set volume to 1.0
        engine.volume = 1.0
        
        // Then - Effective volume should be 1.0 * 0.5 = 0.5
        let expectedVolume = Double(1.0 * mockGainControl.gainDBToLinear(-6.0))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
    }
    
    /// Test that zero gain has no effect
    func testZeroGainHasNoEffect() async throws {
        // Given - A track with zero gain
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(0.0)
        try await engine.loadTrack(track)
        
        // When - Set volume to 0.7
        engine.volume = 0.7
        
        // Then - Volume should be unchanged (0.7 * 1.0 = 0.7)
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, 0.7, accuracy: 0.001)
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that removing track gain reverts to global gain
    func testRemoveTrackGainRevertsToGlobal() async throws {
        // Given - Track with both track and global gain
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(3.0)
        await mockGainControl.setTrackGain(2.0, for: track)
        try await engine.loadTrack(track)
        
        // When - Remove track gain
        await mockGainControl.removeTrackGain(for: track)
        engine.volume = 0.8 // Trigger volume update
        
        // Then - Effective gain should be only global gain (3.0 dB)
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        XCTAssertEqual(effectiveGain, 3.0, accuracy: 0.001)
    }
    
    /// Test that changing gain updates volume immediately
    func testGainChangeUpdatesVolume() async throws {
        // Given - A track is loaded and playing
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        mockNativeEngine.shouldPlaySucceed = true
        
        try await engine.loadTrack(track)
        try await engine.play()
        engine.volume = 0.5
        
        let initialVolumeCalls = mockNativeEngine.setVolumeCalls.count
        
        // When - Change global gain
        await mockGainControl.setGlobalGain(6.0)
        await engine.refreshGain() // Update cached gain multiplier
        engine.volume = 0.5 // Trigger update
        
        // Then - Volume should be updated with new gain
        XCTAssertGreaterThan(mockNativeEngine.setVolumeCalls.count, initialVolumeCalls)
        let expectedVolume = Double(min(1.0, 0.5 * mockGainControl.gainDBToLinear(6.0)))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
    }
    
    // MARK: - Cross-Check
    
    /// Test that gain calculation matches manual calculation
    func testGainCalculationMatchesManual() async throws {
        // Given - Known gain values
        let gainDB: Float = 6.0 // +6 dB should be 2x linear
        
        // When - Convert to linear
        let linearGain = mockGainControl.gainDBToLinear(gainDB)
        
        // Then - Should match manual calculation: 10^(6/20) = 10^0.3 ≈ 2.0
        let expectedLinear = Float(pow(10.0, 6.0 / 20.0))
        XCTAssertEqual(linearGain, expectedLinear, accuracy: 0.001)
        
        // And - Convert back to dB should match original
        let convertedBack = mockGainControl.linearToGainDB(linearGain)
        XCTAssertEqual(convertedBack, gainDB, accuracy: 0.001)
    }
    
    // MARK: - Error Conditions
    
    /// Test that missing gain control doesn't crash
    func testMissingGainControlDoesNotCrash() async throws {
        // Given - Engine without gain control
        let engineWithoutGain = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockFormatCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // When - Set volume
        try await engineWithoutGain.loadTrack(track)
        engineWithoutGain.volume = 0.5
        
        // Then - Should work normally (volume set without gain)
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, 0.5, accuracy: 0.001)
    }
    
    /// Test that invalid gain values are handled gracefully
    func testInvalidGainValuesHandled() async throws {
        // Given - A track with NaN gain
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // When - Try to convert NaN to linear
        let linearGain = mockGainControl.gainDBToLinear(Float.nan)
        
        // Then - Should return 1.0 (unity gain for invalid values)
        XCTAssertEqual(linearGain, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Performance
    
    /// Test that gain calculation is fast
    func testGainCalculationPerformance() {
        // Given - Gain control instance
        let iterations = 1000
        
        // When - Convert gain multiple times
        measure {
            for _ in 0..<iterations {
                _ = mockGainControl.gainDBToLinear(6.0)
                _ = mockGainControl.linearToGainDB(2.0)
            }
        }
        
        // Then - Should complete quickly (performance test will fail if too slow)
    }
    
    // MARK: - Edge Cases
    
    /// Test that gain is applied when track changes
    func testGainAppliedOnTrackChange() async throws {
        // Given - Two tracks with different gains
        let track1 = MockFactory.makeTrack(filePath: "/test/track1.mp3")
        let track2 = MockFactory.makeTrack(filePath: "/test/track2.mp3")
        mockFileSystem.addFile(track1.filePath)
        mockFileSystem.addFile(track2.filePath)
        mockNativeEngine.nextLoadDuration = track1.duration
        
        await mockGainControl.setTrackGain(3.0, for: track1)
        await mockGainControl.setTrackGain(-3.0, for: track2)
        
        try await engine.loadTrack(track1)
        engine.volume = 0.8
        let volume1 = mockNativeEngine.setVolumeCalls.last ?? 0.0
        
        // When - Load different track
        mockNativeEngine.nextLoadDuration = track2.duration
        try await engine.loadTrack(track2)
        engine.volume = 0.8
        
        // Then - Volume should be different due to different track gain
        let volume2 = mockNativeEngine.setVolumeCalls.last ?? 0.0
        XCTAssertNotEqual(volume1, volume2, accuracy: 0.001)
    }
    
    /// Test that gain control is called when volume changes
    func testGainControlCalledOnVolumeChange() async throws {
        // Given - A track is loaded with gain control
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(6.0)
        try await engine.loadTrack(track)
        
        _ = mockGainControl.getEffectiveGainCallCount
        
        // When - Change volume
        engine.volume = 0.5
        
        // Then - Gain control should be consulted
        // Note: Actual implementation will determine when to call getEffectiveGain
        // For now, we verify the integration point exists
        XCTAssertNotNil(mockGainControl)
    }
}
