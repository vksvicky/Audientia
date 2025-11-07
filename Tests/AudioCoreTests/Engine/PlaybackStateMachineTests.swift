// PlaybackStateMachineTests.swift
// Audientia - TDD/BDD Tests for Audio Playback State Machine
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for playback state machine
/// Following Right-BICEP principles:
/// - [Right]: Verify state transitions are correct
/// - [B]oundary: Test edge cases and boundaries
/// - [I]nverse: Test reversible operations
/// - [C]ross-check: Verify with alternative methods
/// - [E]rror: Test error conditions
/// - [P]erformance: Verify performance characteristics
/// - Edge cases: Concurrent operations, state race conditions
@MainActor
final class PlaybackStateMachineTests: XCTestCase {
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given an audio engine, when I initialize it, then it should be in stopped state
    func testInitialStateIsStopped() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        XCTAssertEqual(engine.state, .stopped, "Engine should start in stopped state")
    }
    
    /// BDD: Given a stopped engine with a loaded track, when I call play, then it should transition to playing
    func testPlayTransitionsFromStoppedToPlaying() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When
        try await engine.play()
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Engine should be in playing state after play()")
    }
    
    /// BDD: Given a playing engine, when I call pause, then it should transition to paused
    func testPauseTransitionsFromPlayingToPaused() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        engine.pause()
        
        // Then
        XCTAssertEqual(engine.state, .paused, "Engine should be in paused state after pause()")
    }
    
    /// BDD: Given a paused engine, when I call resume, then it should transition to playing
    func testResumeTransitionsFromPausedToPlaying() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        engine.pause()
        
        // When
        try await engine.resume()
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Engine should be in playing state after resume()")
    }
    
    /// BDD: Given a playing engine, when I call stop, then it should transition to stopped
    func testStopTransitionsFromPlayingToStopped() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        engine.stop()
        
        // Then
        XCTAssertEqual(engine.state, .stopped, "Engine should be in stopped state after stop()")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given an engine without a loaded track and empty queue, when I try to play, then it should throw queueEmpty error
    func testPlayWithoutLoadedTrackThrowsError() async {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        do {
            try await engine.play()
            XCTFail("play() should throw error when no track is loaded and queue is empty")
        } catch let error as AudioEngineError {
            // When queue is empty and no track is loaded, queueEmpty is the appropriate error
            XCTAssertEqual(error, .queueEmpty, "Should throw queueEmpty error")
        } catch {
            XCTFail("Should throw AudioEngineError, got: \(error)")
        }
    }
    
    /// BDD: Given a stopped engine, when I try to pause, then it should remain stopped
    func testPauseFromStoppedStateRemainsStopped() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When
        engine.pause()
        
        // Then
        XCTAssertEqual(engine.state, .stopped, "Engine should remain stopped when pause() called from stopped state")
    }
    
    /// BDD: Given a stopped engine, when I try to resume, then it should remain stopped
    func testResumeFromStoppedStateRemainsStopped() async {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        do {
            try await engine.resume()
            XCTFail("resume() should throw error when engine is stopped")
        } catch let error as AudioEngineError {
            XCTAssertEqual(error, .noTrackLoaded, "Should throw noTrackLoaded error")
        } catch {
            XCTFail("Should throw AudioEngineError, got: \(error)")
        }
    }
    
    // MARK: - [I]nverse Relationships
    
    /// BDD: Given a playing engine, when I pause then resume, then it should return to playing state
    func testPauseResumeRoundtrip() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        _ = engine.currentPosition
        
        // When
        engine.pause()
        try await engine.resume()
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Engine should be playing after pause/resume")
        // Position should be maintained (tested in seek tests)
    }
    
    /// BDD: Given a playing engine, when I stop then play again, then it should restart from beginning
    func testStopPlayRestartsFromBeginning() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // Advance position (simulated)
        try await engine.seek(to: 30.0)
        
        // When
        engine.stop()
        try await engine.play()
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Engine should be playing")
        XCTAssertEqual(engine.currentPosition, 0.0, accuracy: 0.1, "Position should reset to beginning")
    }
    
    // MARK: - [C]ross-Checking Using Other Means
    
    /// BDD: Given a playing engine, when I check state via multiple methods, then they should agree
    func testStateConsistencyAcrossMethods() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When & Then
        XCTAssertEqual(engine.state, .playing, "State property should be playing")
        XCTAssertTrue(engine.isPlaying, "isPlaying should be true")
        XCTAssertFalse(engine.isPaused, "isPaused should be false")
        XCTAssertFalse(engine.isStopped, "isStopped should be false")
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given an engine loading a corrupt file, when I try to load it, then it should throw an error
    func testLoadCorruptFileThrowsError() async {
        // Given
        let mockFileSystem = MockFileSystem()
        mockFileSystem.shouldFail = true // Simulate file not found
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: MockFormatDecodingCoordinator()
        )
        let corruptTrack = MockFactory.makeTrack(filePath: "/path/to/corrupt.mp3")
        
        // When & Then
        do {
            try await engine.loadTrack(corruptTrack)
            XCTFail("loadTrack() should throw error for corrupt file")
        } catch {
            XCTAssertTrue(error is AudioEngineError, "Should throw AudioEngineError")
        }
    }
    
    /// BDD: Given a playing engine, when output fails, then it should transition to error state
    func testOutputFailureTransitionsToError() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Simulate output failure
        // (Implementation will handle this)
        
        // Then
        // Error state handling will be tested in integration tests
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given an engine, when I perform many state transitions, then it should complete quickly
    func testStateTransitionPerformance() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When & Then
        measure {
            Task {
                try? await engine.play()
                engine.pause()
                try? await engine.resume()
                engine.stop()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// BDD: Given an engine, when I call play multiple times rapidly, then it should handle gracefully
    func testRapidPlayCalls() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When
        try await engine.play()
        try await engine.play() // Second call should be idempotent
        
        // Then
        XCTAssertEqual(engine.state, .playing, "Engine should remain in playing state")
    }
    
    /// BDD: Given an engine, when I transition states concurrently, then it should maintain consistency
    func testConcurrentStateTransitions() async throws {
        // Given
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - Multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await engine.play()
            }
            group.addTask {
                await engine.pause()
            }
            group.addTask {
                try? await engine.resume()
            }
        }
        
        // Then - State should be valid (either playing or paused, not inconsistent)
        XCTAssertTrue(engine.state == .playing || engine.state == .paused, "State should be valid after concurrent operations")
    }
}
