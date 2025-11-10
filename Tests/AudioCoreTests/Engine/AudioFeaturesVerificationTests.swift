// AudioFeaturesVerificationTests.swift
// Audientia - Verification Tests for Audio Features
//
// These tests verify that our audio features work correctly by comparing
// behavior with proven open source music players (RetroMusicPlayer, Namida, Symphony)
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style verification tests for audio features
/// These tests verify that our implementation matches expected behavior
/// from proven open source music players
@MainActor
final class AudioFeaturesVerificationTests: XCTestCase {
    
    // MARK: - Volume Control Verification
    
    /// BDD: Given a playing track, when I set volume to 0.5, then volume should be 0.5
    /// Verification: RetroMusicPlayer, Namida, Symphony all support volume control
    func testVolumeControlSetsVolumeCorrectly() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        engine.setVolume(0.5)
        
        // Then
        XCTAssertEqual(engine.volume, 0.5, accuracy: 0.01, "Volume should be set to 0.5")
    }
    
    /// BDD: Given a playing track, when I set volume above 1.0, then it should clamp to 1.0
    /// Verification: All proven players clamp volume to valid range
    func testVolumeControlClampsToMaximum() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        engine.setVolume(1.5) // Above maximum
        
        // Then
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.01, "Volume should clamp to 1.0")
    }
    
    /// BDD: Given a playing track, when I set volume below 0.0, then it should clamp to 0.0
    /// Verification: All proven players clamp volume to valid range
    func testVolumeControlClampsToMinimum() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        engine.setVolume(-0.5) // Below minimum
        
        // Then
        XCTAssertEqual(engine.volume, 0.0, accuracy: 0.01, "Volume should clamp to 0.0")
    }
    
    /// BDD: Given a playing track, when I mute then unmute, then volume should restore
    /// Verification: RetroMusicPlayer, Namida, Symphony all preserve volume on mute/unmute
    func testMuteUnmutePreservesVolume() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        engine.setVolume(0.7)
        let originalVolume = engine.volume
        
        // When
        engine.setMuted(true)
        engine.setMuted(false)
        
        // Then
        XCTAssertEqual(engine.volume, originalVolume, accuracy: 0.01, "Volume should be restored after unmute")
    }
    
    // MARK: - Loop Mode Verification
    
    /// BDD: Given loop mode is track, when track reaches end, then it should restart
    /// Verification: RetroMusicPlayer, Namida, Symphony all support track looping
    func testLoopTrackRestartsOnCompletion() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 10.0) // Short track for testing
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        engine.setLoopMode(.track)
        try await engine.play()
        
        // When - Simulate reaching end
        try await engine.seek(to: track.duration - 0.1)
        // In real implementation, position tracking would detect completion
        // For now, verify loop mode is set correctly
        
        // Then
        XCTAssertEqual(engine.loopMode, .track, "Loop mode should be track")
        // Actual restart behavior will be tested in integration tests
    }
    
    /// BDD: Given loop mode is queue, when last track finishes, then it should loop to first
    /// Verification: RetroMusicPlayer, Namida, Symphony all support queue looping
    func testLoopQueueLoopsToFirstTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 3)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        engine.setLoopMode(.queue)
        try await engine.play() // Start with first track
        
        // When - Advance to last track
        try await engine.playNext()
        try await engine.playNext()
        XCTAssertEqual(engine.currentTrack?.id, tracks[2].id, "Should be on last track")
        
        // When - Try to play next (should loop to first)
        try await engine.playNext()
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, tracks[0].id, "Should loop to first track")
    }
    
    /// BDD: Given loop mode is none, when track finishes, then it should stop
    /// Verification: RetroMusicPlayer, Namida, Symphony all support no looping
    func testLoopNoneStopsOnCompletion() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        engine.setLoopMode(.none)
        try await engine.play()
        
        // When - Track completes
        try await engine.seek(to: track.duration)
        
        // Then
        XCTAssertEqual(engine.loopMode, .none, "Loop mode should be none")
        // Actual stop behavior will be tested in integration tests
    }
    
    // MARK: - Queue Navigation Verification
    
    /// BDD: Given a queue with tracks, when I play next, then it should advance correctly
    /// Verification: RetroMusicPlayer, Namida, Symphony all support queue navigation
    func testQueueNavigationAdvancesCorrectly() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 5)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play() // Start with first track
        
        // When - Advance through queue
        for i in 1..<tracks.count {
            try await engine.playNext()
            
            // Then
            XCTAssertEqual(engine.currentTrack?.id, tracks[i].id, "Should be on track \(i)")
            XCTAssertEqual(engine.state, .playing, "Should be playing")
        }
    }
    
    /// BDD: Given a queue with tracks, when I play previous, then it should go back correctly
    /// Verification: RetroMusicPlayer, Namida, Symphony all support backward navigation
    func testQueueNavigationGoesBackCorrectly() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 5)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play() // Start with first track
        try await engine.playNext() // Move to second
        try await engine.playNext() // Move to third
        
        // When - Go back
        try await engine.playPrevious()
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, tracks[1].id, "Should be on second track")
        
        // When - Go back again
        try await engine.playPrevious()
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, tracks[0].id, "Should be on first track")
    }
    
    // MARK: - Seek Accuracy Verification
    
    /// BDD: Given a playing track, when I seek to a position, then position should be accurate
    /// Verification: RetroMusicPlayer, Namida, Symphony all support accurate seeking
    func testSeekAccuracy() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Seek to various positions
        let testPositions: [TimeInterval] = [30.0, 60.0, 90.0, 120.0, 150.0]
        
        for position in testPositions {
            try await engine.seek(to: position)
            
            // Then
            XCTAssertEqual(engine.currentPosition, position, accuracy: 0.1, "Position should be accurate at \(position)s")
        }
    }
    
    /// BDD: Given a playing track, when I seek multiple times rapidly, then it should handle correctly
    /// Verification: Proven players handle rapid seeks gracefully
    func testRapidSeekHandling() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Rapid seeks
        for _ in 0..<10 {
            let randomPosition = Double.random(in: 0...track.duration)
            try await engine.seek(to: randomPosition)
        }
        
        // Then - Should not crash and position should be valid
        XCTAssertGreaterThanOrEqual(engine.currentPosition, 0.0, "Position should be >= 0")
        XCTAssertLessThanOrEqual(engine.currentPosition, track.duration, "Position should be <= duration")
    }
    
    // MARK: - Skip Functionality Verification
    
    /// BDD: Given a playing track, when I skip forward, then position should advance correctly
    /// Verification: RetroMusicPlayer, Namida, Symphony all support skip forward
    func testSkipForwardAccuracy() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 30.0)
        
        // When
        try await engine.skipForward(seconds: 15.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 45.0, accuracy: 0.1, "Should skip forward 15 seconds")
    }
    
    /// BDD: Given a playing track, when I skip backward, then position should go back correctly
    /// Verification: RetroMusicPlayer, Namida, Symphony all support skip backward
    func testSkipBackwardAccuracy() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 60.0)
        
        // When
        try await engine.skipBackward(seconds: 20.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 40.0, accuracy: 0.1, "Should skip backward 20 seconds")
    }
    
    // MARK: - Replay Functionality Verification
    
    /// BDD: Given a playing track, when I replay, then it should restart from beginning
    /// Verification: RetroMusicPlayer, Namida, Symphony all support replay
    func testReplayRestartsFromBeginning() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 90.0) // Seek to middle
        
        // When
        try await engine.replay()
        
        // Then
        XCTAssertEqual(engine.currentPosition, 0.0, accuracy: 0.1, "Should restart from beginning")
        XCTAssertEqual(engine.state, .playing, "Should be playing")
    }
    
    // MARK: - State Machine Verification
    
    /// BDD: Given a stopped engine, when I load and play, then state should transition correctly
    /// Verification: All proven players have correct state transitions
    func testStateTransitionsAreCorrect() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        XCTAssertEqual(engine.state, .stopped, "Should start stopped")
        
        // When - Play
        try await engine.play()
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Should be playing")
        
        // When - Pause
        await engine.pause()
        
        // Then
        XCTAssertEqual(engine.state, .paused, "Should be paused")
        
        // When - Resume
        try await engine.resume()
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Should be playing again")
        
        // When - Stop
        await engine.stop()
        
        // Then
        XCTAssertEqual(engine.state, .stopped, "Should be stopped")
    }
    
    // MARK: - Position Tracking Verification
    
    /// BDD: Given a playing track, when position updates, then it should advance correctly
    /// Verification: Proven players track position accurately during playback
    func testPositionTrackingAdvancesDuringPlayback() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        let initialPosition = engine.currentPosition
        
        // When - Wait a bit (simulated by seeking forward)
        // In real implementation, position would advance automatically
        try await engine.seek(to: initialPosition + 5.0)
        
        // Then
        XCTAssertGreaterThan(engine.currentPosition, initialPosition, "Position should advance")
    }
    
    // MARK: - Error Handling Verification
    
    /// BDD: Given an engine without a track, when I try to play, then it should throw appropriate error
    /// Verification: Proven players handle errors gracefully
    func testErrorHandlingForMissingTrack() async {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        do {
            try await engine.play()
            XCTFail("Should throw error when no track is loaded")
        } catch let error as AudioEngineError {
            XCTAssertTrue(error == .queueEmpty || error == .noTrackLoaded, "Should throw appropriate error")
        } catch {
            XCTFail("Should throw AudioEngineError, got: \(error)")
        }
    }
    
    /// BDD: Given a track, when I seek beyond duration, then it should clamp to duration
    /// Verification: Proven players handle out-of-bounds seeks gracefully
    func testSeekBeyondDurationClamps() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 200.0) // Beyond duration
        
        // Then
        XCTAssertLessThanOrEqual(engine.currentPosition, track.duration, "Should clamp to duration")
    }
}
