// QueueManagementTests.swift
// Audientia - TDD/BDD Tests for Playback Queue Management
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for playback queue management
/// Following Right-BICEP principles
@MainActor
final class QueueManagementTests: XCTestCase {
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given an empty queue, when I check the queue, then it should be empty
    func testEmptyQueueIsEmpty() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        XCTAssertTrue(engine.queue.isEmpty, "Queue should be empty initially")
        XCTAssertEqual(engine.queue.count, 0, "Queue count should be 0")
    }
    
    /// BDD: Given an engine, when I add a track to the queue, then it should be in the queue
    func testAddTrackToQueue() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let track = MockFactory.makeTrack()
        
        // When
        engine.addToQueue(track)
        
        // Then
        XCTAssertEqual(engine.queue.count, 1, "Queue should contain 1 track")
        XCTAssertEqual(engine.queue.first?.id, track.id, "Queue should contain the added track")
    }
    
    /// BDD: Given a queue with tracks, when I add multiple tracks, then they should be in order
    func testAddMultipleTracksToQueue() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 5)
        
        // When
        for track in tracks {
            engine.addToQueue(track)
        }
        
        // Then
        XCTAssertEqual(engine.queue.count, 5, "Queue should contain 5 tracks")
        for (index, track) in tracks.enumerated() {
            XCTAssertEqual(engine.queue[index].id, track.id, "Track \(index) should match")
        }
    }
    
    /// BDD: Given a queue with tracks, when I clear the queue, then it should be empty
    func testClearQueue() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 3)
        for track in tracks {
            engine.addToQueue(track)
        }
        
        // When
        engine.clearQueue()
        
        // Then
        XCTAssertTrue(engine.queue.isEmpty, "Queue should be empty after clearing")
    }
    
    /// BDD: Given a queue with tracks, when I remove a track, then it should be removed
    func testRemoveTrackFromQueue() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 3)
        for track in tracks {
            engine.addToQueue(track)
        }
        let trackToRemove = tracks[1]
        
        // When
        engine.removeFromQueue(trackToRemove)
        
        // Then
        XCTAssertEqual(engine.queue.count, 2, "Queue should contain 2 tracks")
        XCTAssertFalse(engine.queue.contains { $0.id == trackToRemove.id }, "Removed track should not be in queue")
    }
    
    /// BDD: Given a queue with tracks, when I play, then it should play the first track
    func testPlayStartsFirstTrackInQueue() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 3)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        
        // When
        try await engine.play()
        
        // Then
        XCTAssertEqual(engine.currentTrack?.id, tracks[0].id, "Current track should be first in queue")
        XCTAssertEqual(engine.state, .playing, "Engine should be playing")
    }
    
    /// BDD: Given a playing track, when it finishes, then it should advance to next track
    func testAutoAdvanceToNextTrack() async throws {
        // Given
        let tracks = MockFactory.makeTracks(count: 3)
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        try await engine.play()
        
        // When - Simulate track completion
        // (This will be tested in integration tests with real audio)
        
        // Then
        // Auto-advance logic will be verified
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given an empty queue, when I try to play, then it should throw an error
    func testPlayEmptyQueueThrowsError() async {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        do {
            try await engine.play()
            XCTFail("play() should throw error when queue is empty")
        } catch let error as AudioEngineError {
            XCTAssertEqual(error, .queueEmpty, "Should throw queueEmpty error")
        } catch {
            XCTFail("Should throw AudioEngineError, got: \(error)")
        }
    }
    
    /// BDD: Given a queue with one track, when I remove it, then queue should be empty
    func testRemoveLastTrackFromQueue() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let track = MockFactory.makeTrack()
        engine.addToQueue(track)
        
        // When
        engine.removeFromQueue(track)
        
        // Then
        XCTAssertTrue(engine.queue.isEmpty, "Queue should be empty")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// BDD: Given a queue, when I add then remove a track, then queue should be unchanged
    func testAddRemoveTrackRoundtrip() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let initialTracks = MockFactory.makeTracks(count: 2)
        for track in initialTracks {
            engine.addToQueue(track)
        }
        let initialCount = engine.queue.count
        let trackToAdd = MockFactory.makeTrack()
        
        // When
        engine.addToQueue(trackToAdd)
        engine.removeFromQueue(trackToAdd)
        
        // Then
        XCTAssertEqual(engine.queue.count, initialCount, "Queue count should be unchanged")
    }
    
    // MARK: - [C]ross-Checking Using Other Means
    
    /// BDD: Given a queue, when I check queue state via multiple methods, then they should agree
    func testQueueStateConsistency() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 5)
        for track in tracks {
            engine.addToQueue(track)
        }
        
        // When & Then
        XCTAssertEqual(engine.queue.count, 5, "Queue count should be 5")
        XCTAssertFalse(engine.queue.isEmpty, "Queue should not be empty")
        XCTAssertEqual(engine.queue.count, tracks.count, "Queue count should match added tracks")
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given a queue, when I try to remove a non-existent track, then it should handle gracefully
    func testRemoveNonExistentTrack() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 2)
        for track in tracks {
            engine.addToQueue(track)
        }
        let nonExistentTrack = MockFactory.makeTrack()
        
        // When
        engine.removeFromQueue(nonExistentTrack) // Should not crash
        
        // Then
        XCTAssertEqual(engine.queue.count, 2, "Queue should remain unchanged")
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given a large queue, when I add many tracks, then it should complete quickly
    func testLargeQueuePerformance() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 1000)
        
        // When & Then
        measure {
            for track in tracks {
                engine.addToQueue(track)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// BDD: Given a queue, when I add the same track multiple times, then it should be added multiple times
    func testAddSameTrackMultipleTimes() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let track = MockFactory.makeTrack()
        
        // When
        engine.addToQueue(track)
        engine.addToQueue(track)
        engine.addToQueue(track)
        
        // Then
        XCTAssertEqual(engine.queue.count, 3, "Queue should contain track 3 times")
    }
    
    /// BDD: Given a playing queue, when I reorder tracks, then order should be updated
    func testReorderQueueTracks() {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        let tracks = MockFactory.makeTracks(count: 5)
        for track in tracks {
            engine.addToQueue(track)
        }
        
        // When
        engine.moveTrack(from: 0, to: 4)
        
        // Then
        XCTAssertEqual(engine.queue[4].id, tracks[0].id, "Track should be moved to end")
    }
}
