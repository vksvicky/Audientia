//
//  PlaybackProgressBDDTests.swift
//  AudioCoreTests
//
//  BDD-style tests for user scenarios: "As a user, I want to play a track and see progress update"
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for user-facing playback progress scenarios
/// Implements: "As a user, I want to play a track and see progress update"
@MainActor
final class PlaybackProgressBDDTests: XCTestCase {
    
    // MARK: - User Scenario: Play Track and See Progress Update
    
    /// BDD: As a user, when I play a track, then I should see the progress update over time
    func testUserPlaysTrackAndSeesProgressUpdate() async throws {
        // Given - User has a track loaded
        let track = MockFactory.makeTrack(title: "Test Song", duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - User plays the track
        try await engine.play()
        
        // Then - Progress should start at 0
        XCTAssertEqual(engine.progress, 0.0, accuracy: 0.01, "Progress should start at 0")
        XCTAssertEqual(engine.currentPosition, 0.0, accuracy: 0.01, "Position should start at 0")
        
        // Wait a short time for position tracking to update
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then - Progress should have advanced
        XCTAssertGreaterThan(engine.currentPosition, 0.0, "Position should advance during playback")
        XCTAssertGreaterThan(engine.progress, 0.0, "Progress should advance during playback")
        XCTAssertLessThanOrEqual(engine.progress, 1.0, "Progress should not exceed 1.0")
    }
    
    /// BDD: As a user, when I pause a playing track, then progress should stop updating
    func testUserPausesTrackAndProgressStops() async throws {
        // Given - User has a playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // Wait for position to advance
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        let positionBeforePause = engine.currentPosition
        XCTAssertGreaterThan(positionBeforePause, 0.0, "Position should have advanced")
        
        // When - User pauses the track
        engine.pause()
        
        // Wait a bit more
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then - Position should remain the same (not advancing)
        XCTAssertEqual(
            engine.currentPosition, positionBeforePause, accuracy: 0.1,
            "Position should not advance when paused"
        )
    }
    
    /// BDD: As a user, when I resume a paused track, then progress should continue updating
    func testUserResumesTrackAndProgressContinues() async throws {
        // Given - User has a paused track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        engine.pause()
        let positionAtPause = engine.currentPosition
        
        // When - User resumes the track
        try await engine.resume()
        
        // Wait for position to advance
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then - Position should have advanced from pause position
        XCTAssertGreaterThan(engine.currentPosition, positionAtPause,
                             "Position should advance after resume")
    }
    
    /// BDD: As a user, when I seek to a position, then progress should update immediately
    func testUserSeeksAndProgressUpdatesImmediately() async throws {
        // Given - User has a playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - User seeks to 50% of the track
        try await engine.seek(to: 90.0)
        
        // Then - Progress should be approximately 0.5 (50%)
        XCTAssertEqual(engine.progress, 0.5, accuracy: 0.01, "Progress should be 50% after seeking to 90s")
        XCTAssertEqual(engine.currentPosition, 90.0, accuracy: 0.1, "Position should be 90 seconds")
    }
    
    /// BDD: As a user, when I play a track to completion, then progress should reach 100%
    func testUserPlaysTrackToCompletionAndProgressReaches100() async throws {
        // Given - User has a short track (1 second for testing)
        let track = MockFactory.makeTrack(title: "Short Track", duration: 1.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - User plays the track
        try await engine.play()
        
        // Wait for track to complete (with some buffer)
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Then - Progress should be at or near 100%
        XCTAssertGreaterThanOrEqual(engine.progress, 0.95, accuracy: 0.05,
                                    "Progress should be near 100% when track completes")
    }
    
    /// BDD: As a user, when I check progress on a stopped track, then it should show 0%
    func testUserChecksProgressOnStoppedTrackShowsZero() async throws {
        // Given - User has a loaded but stopped track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        // Track is loaded but not playing
        
        // When & Then - Progress should be 0%
        XCTAssertEqual(engine.progress, 0.0, accuracy: 0.01, "Progress should be 0% when stopped")
        XCTAssertEqual(engine.currentPosition, 0.0, accuracy: 0.01, "Position should be 0 when stopped")
    }
    
    /// BDD: As a user, when I play a track and check progress multiple times, then it should consistently increase
    func testUserChecksProgressMultipleTimesAndItIncreases() async throws {
        // Given - User has a playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - User checks progress multiple times
        var previousProgress = engine.progress
        var previousPosition = engine.currentPosition
        
        for _ in 0..<5 {
            try await Task.sleep(nanoseconds: 200_000_000) // 200ms between checks
            
            // Then - Progress should increase each time
            XCTAssertGreaterThanOrEqual(
                engine.progress, previousProgress,
                "Progress should increase or stay the same"
            )
            XCTAssertGreaterThanOrEqual(
                engine.currentPosition, previousPosition,
                "Position should increase or stay the same"
            )
            
            previousProgress = engine.progress
            previousPosition = engine.currentPosition
        }
    }
    
    /// BDD: As a user, when I seek while playing, then progress should update immediately and playback continues
    func testUserSeeksWhilePlayingAndProgressUpdates() async throws {
        // Given - User has a playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // Wait for some playback
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        let positionBeforeSeek = engine.currentPosition
        XCTAssertGreaterThan(positionBeforeSeek, 0.0, "Position should have advanced")
        
        // When - User seeks forward while playing
        try await engine.seek(to: 60.0)
        
        // Then - Progress should update immediately and playback continues
        XCTAssertEqual(
            engine.currentPosition, 60.0, accuracy: 0.1,
            "Position should update immediately after seek"
        )
        XCTAssertEqual(
            engine.progress, 60.0 / 180.0, accuracy: 0.01,
            "Progress should be 33.3% after seeking to 60s"
        )
        XCTAssertEqual(engine.state, .playing, "Playback should continue after seek")
    }
    
    /// BDD: As a user, when I seek backward while playing, then progress should update and playback continues
    func testUserSeeksBackwardWhilePlaying() async throws {
        // Given - User has a playing track at position 90s
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 90.0)
        
        // When - User seeks backward to 30s
        try await engine.seek(to: 30.0)
        
        // Then - Progress should update to earlier position
        XCTAssertEqual(
            engine.currentPosition, 30.0, accuracy: 0.1,
            "Position should update to 30s"
        )
        XCTAssertEqual(
            engine.progress, 30.0 / 180.0, accuracy: 0.01,
            "Progress should be 16.7% after seeking to 30s"
        )
        XCTAssertEqual(engine.state, .playing, "Playback should continue after backward seek")
    }
    
    /// BDD: As a user, when I check progress during track loading, then it should show 0% until loaded
    func testUserChecksProgressDuringLoading() async throws {
        // Given - User is loading a track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = AudioEngineTestHelpers.createMockEngine(withTracks: [track])
        
        // When - Track is being loaded (async operation)
        let loadTask = Task {
            try await engine.loadTrack(track)
        }
        
        // Then - Progress should be 0% during loading
        // Note: In real implementation, we might show a loading state
        XCTAssertEqual(
            engine.progress, 0.0, accuracy: 0.01,
            "Progress should be 0% during loading"
        )
        
        // Wait for load to complete
        try await loadTask.value
        
        // Then - After loading, progress should still be 0% (not playing yet)
        XCTAssertEqual(
            engine.progress, 0.0, accuracy: 0.01,
            "Progress should be 0% after loading but before playing"
        )
    }
    
    /// BDD: As a user, when I play a track, then progress should update smoothly without jumps
    func testUserPlaysTrackAndProgressUpdatesSmoothly() async throws {
        // Given - User has a playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - User monitors progress over time
        var previousProgress = engine.progress
        var progressDeltas: [Double] = []
        
        for _ in 0..<5 {
            try await Task.sleep(nanoseconds: 200_000_000) // 200ms between checks
            let currentProgress = engine.progress
            let delta = currentProgress - previousProgress
            
            // Then - Progress should increase smoothly (no negative deltas, no large jumps)
            XCTAssertGreaterThanOrEqual(
                delta, 0.0,
                "Progress should not decrease (smooth update)"
            )
            XCTAssertLessThanOrEqual(
                delta, 0.1,
                "Progress should not jump more than 10% in 200ms"
            )
            
            progressDeltas.append(delta)
            previousProgress = currentProgress
        }
        
        // Verify smooth progression (deltas should be relatively consistent)
        let avgDelta = progressDeltas.reduce(0, +) / Double(progressDeltas.count)
        XCTAssertGreaterThan(avgDelta, 0.0, "Average progress delta should be positive")
    }
}
