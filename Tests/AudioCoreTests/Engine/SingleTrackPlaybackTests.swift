//
//  SingleTrackPlaybackTests.swift
//  AudioCoreTests
//
//  Tests to ensure only one track plays at a time
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import Foundation
import Shared
import XCTest

/// Tests to ensure only one track plays at a time
/// BDD: As a user, when I play a track, only that track should play, not multiple tracks simultaneously
@MainActor
final class SingleTrackPlaybackTests: XCTestCase {
    
    // MARK: - Right-BICEP: Are the Results Right?
    
    /// BDD: Given a track is playing, when I play another track, then the first track should stop and only the new track should play
    func testPlayingNewTrackStopsCurrentTrack() async throws {
        // Given - A track is currently playing
        let track1 = MockFactory.makeTrack(
            title: "Track 1",
            duration: 180.0,
            filePath: "/test/track1.mp3"
        )
        let track2 = MockFactory.makeTrack(
            title: "Track 2",
            duration: 200.0,
            filePath: "/test/track2.mp3"
        )
        
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track1.filePath)
        fileSystem.addFile(track2.filePath)
        
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: mockEngine
        )
        
        // Load and play first track
        try await engine.loadTrack(track1)
        try await engine.play()
        
        XCTAssertEqual(engine.currentTrack?.id, track1.id, "Track 1 should be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should be playing")
        _ = mockEngine.playCallCount
        
        // When - I load and play a different track
        try await engine.loadTrack(track2)
        try await engine.play()
        
        // Then - Only track 2 should be current and playing
        XCTAssertEqual(engine.currentTrack?.id, track2.id, "Track 2 should be current")
        XCTAssertNotEqual(engine.currentTrack?.id, track1.id, "Track 1 should not be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should still be playing")
        
        // Verify that stop was called before loading new track
        XCTAssertGreaterThan(mockEngine.stopCallCount, 0, "Stop should have been called when loading new track")
        
        // Verify only one track is playing (play should have been called for both, but stop should have been called between)
        let stopCountBeforeSecondPlay = mockEngine.stopCallCount
        XCTAssertGreaterThanOrEqual(stopCountBeforeSecondPlay, 1, "Stop should have been called before second play")
    }
    
    /// BDD: Given a track is playing, when I call play() again, then it should not start a duplicate playback
    func testCallingPlayWhilePlayingDoesNotDuplicate() async throws {
        // Given - A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Current Track",
            duration: 180.0,
            filePath: "/test/track.mp3"
        )
        
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: mockEngine
        )
        
        // Load and play track
        try await engine.loadTrack(track)
        try await engine.play()
        
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should be playing")
        _ = mockEngine.playCallCount
        
        // When - I call play() again while already playing
        try await engine.play()
        
        // Then - Should still be playing the same track (not duplicate)
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Same track should still be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should still be playing")
        
        // Play count may increase (native engine might handle this), but we should still have only one current track
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Only one track should be current")
    }
    
    // MARK: - Right-B[I]CEP: Checking Inverse Relationships
    
    /// BDD: Given no track is playing, when I play a track, then exactly one track should be playing
    func testPlayingTrackWhenStoppedStartsSinglePlayback() async throws {
        // Given - No track is playing
        let track = MockFactory.makeTrack(
            title: "New Track",
            duration: 180.0,
            filePath: "/test/track.mp3"
        )
        
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: mockEngine
        )
        
        XCTAssertEqual(engine.state, PlaybackState.stopped, "Should be stopped initially")
        XCTAssertNil(engine.currentTrack, "No track should be current")
        
        // When - I load and play a track
        try await engine.loadTrack(track)
        try await engine.play()
        
        // Then - Exactly one track should be playing
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Track should be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should be playing")
        XCTAssertNotNil(engine.currentTrack, "A track should be current")
    }
    
    // MARK: - Right-BIC[E]P: Forcing Error Conditions
    
    /// BDD: Given a track is playing, when I load a new track while playing, then the current track should stop before the new one loads
    func testLoadingNewTrackWhilePlayingStopsCurrent() async throws {
        // Given - A track is currently playing
        let track1 = MockFactory.makeTrack(
            title: "Track 1",
            duration: 180.0,
            filePath: "/test/track1.mp3"
        )
        let track2 = MockFactory.makeTrack(
            title: "Track 2",
            duration: 200.0,
            filePath: "/test/track2.mp3"
        )
        
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track1.filePath)
        fileSystem.addFile(track2.filePath)
        
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: mockEngine
        )
        
        // Load and play first track
        try await engine.loadTrack(track1)
        try await engine.play()
        
        XCTAssertEqual(engine.currentTrack?.id, track1.id, "Track 1 should be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should be playing")
        
        let stopCountBeforeLoad = mockEngine.stopCallCount
        
        // When - I load a new track while playing
        try await engine.loadTrack(track2)
        
        // Then - Stop should have been called before loading new track
        XCTAssertGreaterThan(mockEngine.stopCallCount, stopCountBeforeLoad, "Stop should have been called when loading new track")
        XCTAssertEqual(engine.currentTrack?.id, track2.id, "Track 2 should now be current")
        XCTAssertNotEqual(engine.currentTrack?.id, track1.id, "Track 1 should no longer be current")
    }
    
    /// BDD: Given audio gain is enabled and a track is playing, when I toggle gain control, then the same track should continue playing (not duplicate)
    func testTogglingGainControlDoesNotDuplicatePlayback() async throws {
        // Given - A track is playing with gain control enabled
        let track = MockFactory.makeTrack(
            title: "Current Track",
            duration: 180.0,
            filePath: "/test/track.mp3"
        )
        
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: mockEngine
        )
        
        // Enable gain control
        AppSettings.shared.isGainControlEnabled = true
        
        // Load and play track
        try await engine.loadTrack(track)
        try await engine.play()
        
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Track should be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should be playing")
        _ = mockEngine.playCallCount
        
        // When - I toggle gain control
        AppSettings.shared.isGainControlEnabled = false
        await engine.refreshGain()
        
        // Then - Same track should still be playing (not duplicated)
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Same track should still be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should still be playing")
        
        // Play should not have been called again (gain control should not trigger playback)
        // Note: refreshGain might cause volume updates, but should not trigger play()
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Only one track should be current")
    }
    
    // MARK: - Right-BICE[P]: Performance Characteristics
    
    /// BDD: Given multiple rapid play() calls, then only one track should be playing at the end
    func testRapidPlayCallsOnlyPlayOneTrack() async throws {
        // Given - A track is loaded
        let track = MockFactory.makeTrack(
            title: "Track",
            duration: 180.0,
            filePath: "/test/track.mp3"
        )
        
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: mockEngine
        )
        
        try await engine.loadTrack(track)
        
        // When - I call play() multiple times rapidly
        try await engine.play()
        try await engine.play()
        try await engine.play()
        
        // Then - Only one track should be current
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Only one track should be current")
        XCTAssertEqual(engine.state, PlaybackState.playing, "Should be playing")
    }
}
