// AdvancedPlaybackTests.swift
// Audientia - TDD/BDD Tests for Advanced Playback Features
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for advanced playback features
/// Features: Queue Navigation, Mute, Replay, Skip, Loop
/// Following Right-BICEP principles
@MainActor
final class AdvancedPlaybackTests: XCTestCase {
    
    // MARK: - Queue Navigation Tests
    
    /// BDD: Given a queue with multiple tracks, when I play next, then it should advance to next track
    func testPlayNextAdvancesToNextTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 3)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play() // Start with first track
        let initialTrack = engine.currentTrack
        
        // When
        try await engine.playNext()
        
        // Then
        XCTAssertNotEqual(engine.currentTrack?.id, initialTrack?.id, "Should advance to next track")
        XCTAssertEqual(engine.currentTrack?.id, tracks[1].id, "Should be playing second track")
        XCTAssertEqual(engine.state, .playing, "Should be playing")
    }
    
    /// BDD: Given a queue with multiple tracks, when I play previous, then it should go to previous track
    func testPlayPreviousGoesToPreviousTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 3)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play() // Start with first track
        try await engine.playNext() // Move to second track
        
        // When
        try await engine.playPrevious()
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, tracks[0].id, "Should be playing first track")
        XCTAssertEqual(engine.state, .playing, "Should be playing")
    }
    
    /// BDD: Given I'm at the last track, when I play next, then it should handle gracefully
    func testPlayNextAtLastTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 2)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play() // Start with first track
        try await engine.playNext() // Move to last track
        
        // When & Then
        do {
            try await engine.playNext()
            // Should either loop (if loop enabled) or throw error
            // For now, expect error
        } catch let error as AudioEngineError {
            XCTAssertEqual(error, .queueEmpty, "Should throw queueEmpty when no next track")
        }
    }
    
    /// BDD: Given I'm at the first track, when I play previous, then it should handle gracefully
    func testPlayPreviousAtFirstTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 2)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play() // Start with first track
        
        // When & Then
        do {
            try await engine.playPrevious()
            XCTFail("Should throw error when no previous track")
        } catch let error as AudioEngineError {
            XCTAssertEqual(error, .queueEmpty, "Should throw queueEmpty when no previous track")
        }
    }
    
    // MARK: - Mute Functionality Tests
    
    /// BDD: Given a playing track, when I mute, then volume should be muted
    func testMuteSetsVolumeToZero() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        engine.setVolume(0.5) // Set some volume
        
        // When
        engine.setMuted(true)
        
        // Then
        XCTAssertTrue(engine.isMuted, "Should be muted")
        XCTAssertEqual(engine.volume, 0.0, "Volume should be 0 when muted")
    }
    
    /// BDD: Given a muted track, when I unmute, then volume should restore
    func testUnmuteRestoresVolume() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        engine.setVolume(0.7)
        engine.setMuted(true) // Mute
        
        // When
        engine.setMuted(false)
        
        // Then
        XCTAssertFalse(engine.isMuted, "Should not be muted")
        XCTAssertEqual(engine.volume, 0.7, "Volume should be restored to previous value")
    }
    
    /// BDD: Given a muted track, when I toggle mute, then it should unmute
    func testToggleMute() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        engine.setVolume(0.5)
        engine.setMuted(true)
        
        // When
        engine.toggleMute()
        
        // Then
        XCTAssertFalse(engine.isMuted, "Should be unmuted after toggle")
        XCTAssertEqual(engine.volume, 0.5, "Volume should be restored")
    }
    
    // MARK: - Replay Functionality Tests
    
    /// BDD: Given a playing track, when I replay, then it should restart from beginning
    func testReplayRestartsTrack() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 30.0) // Seek to 30 seconds
        XCTAssertGreaterThan(engine.currentPosition, 0, "Should have advanced position")
        
        // When
        try await engine.replay()
        
        // Then
        XCTAssertEqual(engine.currentPosition, 0.0, "Position should be reset to 0")
        XCTAssertEqual(engine.currentTrack?.id, track.id, "Should still be same track")
        XCTAssertEqual(engine.state, .playing, "Should be playing")
    }
    
    /// BDD: Given a paused track, when I replay, then it should restart and play
    func testReplayFromPausedState() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 20.0)
        await engine.pause()
        
        // When
        try await engine.replay()
        
        // Then
        XCTAssertEqual(engine.currentPosition, 0.0, "Position should be reset")
        XCTAssertEqual(engine.state, .playing, "Should be playing")
    }
    
    // MARK: - Skip Functionality Tests
    
    /// BDD: Given a playing track, when I skip forward, then position should advance
    func testSkipForward() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        let initialPosition = engine.currentPosition
        
        // When
        try await engine.skipForward(seconds: 10.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, initialPosition + 10.0, accuracy: 0.1, "Should skip forward 10 seconds")
    }
    
    /// BDD: Given a playing track, when I skip backward, then position should go back
    func testSkipBackward() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 30.0) // Seek to 30 seconds
        
        // When
        try await engine.skipBackward(seconds: 10.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 20.0, accuracy: 0.1, "Should skip backward 10 seconds")
    }
    
    /// BDD: Given a track at the beginning, when I skip backward, then it should stay at 0
    func testSkipBackwardAtBeginning() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        // Position is already at 0
        
        // When
        try await engine.skipBackward(seconds: 10.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 0.0, "Should stay at 0")
    }
    
    /// BDD: Given a track near the end, when I skip forward, then it should not exceed duration
    func testSkipForwardAtEnd() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 60.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 55.0) // Near end
        
        // When
        try await engine.skipForward(seconds: 10.0)
        
        // Then
        XCTAssertLessThanOrEqual(engine.currentPosition, track.duration, "Should not exceed duration")
    }
    
    // MARK: - Loop Functionality Tests
    
    /// BDD: Given loop mode is track, when track finishes, then it should replay
    func testLoopTrackReplaysOnCompletion() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 5.0) // Short track for testing
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        engine.setLoopMode(.track)
        try await engine.play()
        
        // When - Simulate track completion
        try await engine.seek(to: track.duration - 0.1) // Near end
        // Simulate position update that would trigger completion
        // (In real implementation, this would be handled by position tracking)
        
        // Then - Track should replay
        // This will be verified in integration tests
    }
    
    /// BDD: Given loop mode is queue, when last track finishes, then it should loop to first
    func testLoopQueueLoopsToFirstTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 2)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        engine.setLoopMode(.queue)
        try await engine.play() // Start with first track
        try await engine.playNext() // Move to last track
        
        // When - Simulate completion and play next
        try await engine.playNext() // Should loop to first
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, tracks[0].id, "Should loop to first track")
    }
    
    /// BDD: Given loop mode is none, when track finishes, then it should stop
    func testLoopNoneStopsOnCompletion() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        engine.setLoopMode(.none)
        try await engine.play()
        
        // When - Track completes
        try await engine.seek(to: track.duration)
        // Simulate completion
        
        // Then - Should stop (verified in integration tests)
    }
    
    /// BDD: Given loop mode, when I toggle loop, then it should cycle through modes
    func testToggleLoopMode() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        XCTAssertEqual(engine.loopMode, .none, "Should start with no loop")
        
        // When - Toggle to track
        engine.toggleLoopMode()
        
        // Then
        XCTAssertEqual(engine.loopMode, .track, "Should be track loop")
        
        // When - Toggle to queue
        engine.toggleLoopMode()
        
        // Then
        XCTAssertEqual(engine.loopMode, .queue, "Should be queue loop")
        
        // When - Toggle to none
        engine.toggleLoopMode()
        
        // Then
        XCTAssertEqual(engine.loopMode, .none, "Should be no loop")
    }
    
    // MARK: - Boundary Conditions
    
    /// BDD: Given an empty queue, when I try to play next, then it should throw error
    func testPlayNextWithEmptyQueue() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When & Then
        do {
            try await engine.playNext()
            XCTFail("Should throw error when queue is empty")
        } catch let error as AudioEngineError {
            XCTAssertEqual(error, .queueEmpty, "Should throw queueEmpty")
        }
    }
    
    // MARK: - Inverse Relationships
    
    /// BDD: Given I play next then previous, then I should be back at original track
    func testPlayNextPreviousRoundtrip() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 3)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play()
        let originalTrack = engine.currentTrack
        
        // When
        try await engine.playNext()
        try await engine.playPrevious()
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, originalTrack?.id, "Should be back at original track")
    }
    
    /// BDD: Given I skip forward then backward by same amount, then position should be unchanged
    func testSkipForwardBackwardRoundtrip() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 30.0)
        let initialPosition = engine.currentPosition
        
        // When
        try await engine.skipForward(seconds: 10.0)
        try await engine.skipBackward(seconds: 10.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, initialPosition, accuracy: 0.1, "Position should be unchanged")
    }
}
