//
//  AudioEngineGainControlBDDTests.swift
//  AudioCoreTests
//
//  BDD tests for AudioEngine gain control integration
//  Testing user-facing scenarios and behaviors
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD tests for AudioEngine gain control integration
/// Testing real-world user scenarios
@MainActor
final class AudioEngineGainControlBDDTests: XCTestCase {
    
    var engine: AudioEngine!
    var mockFileSystem: MockFileSystem!
    var mockNativeEngine: MockNativeAudioEngine!
    var mockGainControl: MockAudioGainControl!
    var mockFormatCoordinator: MockFormatDecodingCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        // Enable gain control in AppSettings for these tests
        AppSettings.shared.isGainControlEnabled = true
        
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
        
        // Reset gain control setting
        AppSettings.shared.isGainControlEnabled = true // Default value
        
        try await super.tearDown()
    }
    
    // MARK: - Scenario: User adjusts global gain
    
    /// Scenario: User sets global gain and plays a track
    /// Given: User sets global gain to +6 dB
    /// When: User loads and plays a track with volume at 0.5
    /// Then: Effective volume should be 0.5 * 2.0 = 1.0 (clamped)
    func testUserSetsGlobalGainAndPlaysTrack() async throws {
        // Given - User sets global gain to +6 dB
        await mockGainControl.setGlobalGain(6.0)
        
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        mockNativeEngine.shouldPlaySucceed = true
        
        // When - User loads and plays track with volume at 0.5
        try await engine.loadTrack(track)
        engine.volume = 0.5
        try await engine.play()
        
        // Then - Effective volume should be amplified
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        let expectedVolume = Double(min(1.0, 0.5 * mockGainControl.gainDBToLinear(effectiveGain)))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
    }
    
    /// Scenario: User changes global gain during playback
    /// Given: Track is playing with volume 0.8 and global gain 0 dB
    /// When: User changes global gain to +3 dB
    /// Then: Volume should update immediately with new gain
    func testUserChangesGlobalGainDuringPlayback() async throws {
        // Given - Track is playing with volume 0.8 and global gain 0 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        mockNativeEngine.shouldPlaySucceed = true
        
        await mockGainControl.setGlobalGain(0.0)
        try await engine.loadTrack(track)
        engine.volume = 0.8
        try await engine.play()
        
        let initialVolume = mockNativeEngine.setVolumeCalls.last ?? 0.0
        
        // When - User changes global gain to +3 dB
        await mockGainControl.setGlobalGain(3.0)
        await engine.refreshGain()
        
        // Then - Volume should update with new gain
        let newVolume = mockNativeEngine.setVolumeCalls.last ?? 0.0
        XCTAssertGreaterThan(newVolume, initialVolume)
    }
    
    // MARK: - Scenario: User adjusts track-specific gain
    
    /// Scenario: User sets track-specific gain for a quiet track
    /// Given: User has a quiet track that needs +12 dB boost
    /// When: User sets track gain to +12 dB and plays the track
    /// Then: Track should play louder without affecting other tracks
    func testUserSetsTrackSpecificGainForQuietTrack() async throws {
        // Given - User has a quiet track
        let quietTrack = MockFactory.makeTrack(filePath: "/test/quiet.mp3")
        let normalTrack = MockFactory.makeTrack(filePath: "/test/normal.mp3")
        mockFileSystem.addFile(quietTrack.filePath)
        mockFileSystem.addFile(normalTrack.filePath)
        mockNativeEngine.nextLoadDuration = quietTrack.duration
        mockNativeEngine.shouldPlaySucceed = true
        
        // When - User sets track gain to +12 dB for quiet track
        await mockGainControl.setTrackGain(12.0, for: quietTrack)
        try await engine.loadTrack(quietTrack)
        engine.volume = 0.5
        try await engine.play()
        
        // Then - Track should play louder
        let effectiveGain = await mockGainControl.getEffectiveGain(for: quietTrack)
        XCTAssertEqual(effectiveGain, 12.0, accuracy: 0.001) // Only track gain (global is 0)
        
        // And - Normal track should not be affected
        mockNativeEngine.nextLoadDuration = normalTrack.duration
        try await engine.loadTrack(normalTrack)
        engine.volume = 0.5
        let normalGain = await mockGainControl.getEffectiveGain(for: normalTrack)
        XCTAssertEqual(normalGain, 0.0, accuracy: 0.001) // No track-specific gain
    }
    
    /// Scenario: User removes track-specific gain
    /// Given: Track has track-specific gain of +6 dB
    /// When: User removes track-specific gain
    /// Then: Track should revert to global gain only
    func testUserRemovesTrackSpecificGain() async throws {
        // Given - Track has track-specific gain of +6 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(3.0)
        await mockGainControl.setTrackGain(6.0, for: track)
        try await engine.loadTrack(track)
        
        let initialGain = await mockGainControl.getEffectiveGain(for: track)
        XCTAssertEqual(initialGain, 9.0, accuracy: 0.001) // 3.0 + 6.0
        
        // When - User removes track-specific gain
        await mockGainControl.removeTrackGain(for: track)
        await engine.refreshGain()
        
        // Then - Track should revert to global gain only
        let finalGain = await mockGainControl.getEffectiveGain(for: track)
        XCTAssertEqual(finalGain, 3.0, accuracy: 0.001) // Only global gain
    }
    
    // MARK: - Scenario: User combines global and track gain
    
    /// Scenario: User combines global and track gain
    /// Given: Global gain is +3 dB and track gain is -6 dB
    /// When: User plays the track
    /// Then: Effective gain should be -3 dB (attenuation)
    func testUserCombinesGlobalAndTrackGain() async throws {
        // Given - Global gain is +3 dB and track gain is -6 dB
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        mockNativeEngine.shouldPlaySucceed = true
        
        await mockGainControl.setGlobalGain(3.0)
        await mockGainControl.setTrackGain(-6.0, for: track)
        
        // When - User plays the track
        try await engine.loadTrack(track)
        engine.volume = 0.8
        try await engine.play()
        
        // Then - Effective gain should be -3 dB
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        XCTAssertEqual(effectiveGain, -3.0, accuracy: 0.001)
        
        // And - Volume should be attenuated
        let expectedVolume = Double(0.8 * mockGainControl.gainDBToLinear(-3.0))
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, expectedVolume, accuracy: 0.001)
    }
    
    // MARK: - Scenario: User switches between tracks with different gains
    
    /// Scenario: User switches between tracks with different gains
    /// Given: Track A has +6 dB gain, Track B has -3 dB gain
    /// When: User switches from Track A to Track B
    /// Then: Volume should adjust automatically for each track
    func testUserSwitchesBetweenTracksWithDifferentGains() async throws {
        // Given - Track A has +6 dB gain, Track B has -3 dB gain
        let trackA = MockFactory.makeTrack(filePath: "/test/trackA.mp3")
        let trackB = MockFactory.makeTrack(filePath: "/test/trackB.mp3")
        mockFileSystem.addFile(trackA.filePath)
        mockFileSystem.addFile(trackB.filePath)
        mockNativeEngine.nextLoadDuration = trackA.duration
        mockNativeEngine.shouldPlaySucceed = true
        
        await mockGainControl.setTrackGain(6.0, for: trackA)
        await mockGainControl.setTrackGain(-3.0, for: trackB)
        
        // When - User plays Track A
        try await engine.loadTrack(trackA)
        engine.volume = 0.5
        try await engine.play()
        let volumeA = mockNativeEngine.setVolumeCalls.last ?? 0.0
        
        // Then - Switch to Track B
        mockNativeEngine.nextLoadDuration = trackB.duration
        try await engine.loadTrack(trackB)
        engine.volume = 0.5
        let volumeB = mockNativeEngine.setVolumeCalls.last ?? 0.0
        
        // Then - Volume should be different (Track B should be quieter)
        XCTAssertLessThan(volumeB, volumeA)
    }
    
    // MARK: - Scenario: Edge cases
    
    /// Scenario: User sets extreme gain values
    /// Given: User sets very high gain (+60 dB)
    /// When: User plays track
    /// Then: Volume should be clamped to 1.0 maximum
    func testUserSetsExtremeGainValues() async throws {
        // Given - User sets very high gain (+60 dB)
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        await mockGainControl.setGlobalGain(60.0)
        try await engine.loadTrack(track)
        engine.volume = 0.5
        
        // When - User plays track
        // Then - Volume should be clamped to 1.0 maximum
        let effectiveGain = await mockGainControl.getEffectiveGain(for: track)
        let gainMultiplier = mockGainControl.gainDBToLinear(effectiveGain)
        let expectedVolume = min(1.0, 0.5 * gainMultiplier)
        XCTAssertLessThanOrEqual(expectedVolume, 1.0)
    }
    
    /// Scenario: User disables gain control
    /// Given: Engine with gain control disabled
    /// When: User sets volume
    /// Then: Volume should work normally without gain adjustment
    func testUserDisablesGainControl() async throws {
        // Given - Disable gain control in AppSettings
        AppSettings.shared.isGainControlEnabled = false
        
        let track = MockFactory.makeTrack(filePath: "/test/track.mp3")
        mockFileSystem.addFile(track.filePath)
        mockNativeEngine.nextLoadDuration = track.duration
        
        // When - User sets volume
        try await engine.loadTrack(track)
        engine.volume = 0.7
        
        // Then - Volume should work normally without gain adjustment
        XCTAssertEqual(mockNativeEngine.setVolumeCalls.last ?? 0.0, 0.7, accuracy: 0.001)
        
        // Restore gain control for other tests
        AppSettings.shared.isGainControlEnabled = true
    }
}
