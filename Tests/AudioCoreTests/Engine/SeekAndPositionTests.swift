// SeekAndPositionTests.swift
// Audientia - TDD/BDD Tests for Seek and Position Tracking
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import AudioCore
@testable import Shared
import XCTest

// Import MockFactory from test infrastructure
// Note: MockFactory is defined in Tests/AudioCoreTests/TestInfrastructure/MockFactories.swift

/// BDD-style test suite for seek and position tracking
/// Following Right-BICEP principles
@MainActor
final class SeekAndPositionTests: XCTestCase {
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given a loaded track, when I check position before playing, then it should be 0
    func testInitialPositionIsZero() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When & Then
        XCTAssertEqual(engine.currentPosition, 0.0, accuracy: 0.01, "Initial position should be 0")
    }
    
    /// BDD: Given a playing track, when I seek to a position, then position should update
    func testSeekUpdatesPosition() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 30.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 30.0, accuracy: 0.1, "Position should be 30.0 seconds")
    }
    
    /// BDD: Given a playing track, when I seek to the end, then position should be at duration
    func testSeekToEnd() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 180.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 180.0, accuracy: 0.1, "Position should be at end")
    }
    
    /// BDD: Given a playing track, when I check duration, then it should match track duration
    func testDurationMatchesTrack() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 240.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When & Then
        XCTAssertEqual(engine.duration, 240.0, accuracy: 0.01, "Duration should match track duration")
    }
    
    /// BDD: Given a playing track, when I seek forward, then position should advance
    func testSeekForward() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 30.0)
        
        // When
        try await engine.seek(by: 15.0) // Seek forward 15 seconds
        
        // Then
        XCTAssertEqual(engine.currentPosition, 45.0, accuracy: 0.1, "Position should advance by 15 seconds")
    }
    
    /// BDD: Given a playing track, when I seek backward, then position should go back
    func testSeekBackward() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 60.0)
        
        // When
        try await engine.seek(by: -20.0) // Seek backward 20 seconds
        
        // Then
        XCTAssertEqual(engine.currentPosition, 40.0, accuracy: 0.1, "Position should go back by 20 seconds")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given a track, when I seek to negative position, then it should clamp to 0
    func testSeekToNegativePositionClampsToZero() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: -10.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 0.0, accuracy: 0.01, "Position should clamp to 0")
    }
    
    /// BDD: Given a track, when I seek beyond duration, then it should clamp to duration
    func testSeekBeyondDurationClampsToEnd() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 200.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 180.0, accuracy: 0.1, "Position should clamp to duration")
    }
    
    /// BDD: Given a very short track (1 second), when I seek, then it should handle correctly
    func testSeekInVeryShortTrack() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 1.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 0.5)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 0.5, accuracy: 0.01, "Position should be 0.5 seconds")
    }
    
    /// BDD: Given a very long track (3 hours), when I seek, then it should handle correctly
    func testSeekInVeryLongTrack() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 10800.0) // 3 hours
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 5400.0) // 1.5 hours
        
        // Then
        XCTAssertEqual(engine.currentPosition, 5400.0, accuracy: 1.0, "Position should be 1.5 hours")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// BDD: Given a playing track, when I seek forward then backward to original position, then position should match
    func testSeekForwardBackwardRoundtrip() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        let initialPosition = 30.0
        try await engine.seek(to: initialPosition)
        
        // When
        try await engine.seek(by: 20.0)
        try await engine.seek(by: -20.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, initialPosition, accuracy: 0.1, "Position should return to original")
    }
    
    // MARK: - [C]ross-Checking Using Other Means
    
    /// BDD: Given a playing track, when I check position via multiple methods, then they should agree
    func testPositionConsistencyAcrossMethods() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        try await engine.seek(to: 45.0)
        
        // When & Then
        XCTAssertEqual(engine.currentPosition, 45.0, accuracy: 0.1, "currentPosition should be 45.0")
        XCTAssertEqual(engine.progress, 45.0 / 180.0, accuracy: 0.01, "progress should be 0.25")
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given an engine without a loaded track, when I try to seek, then it should throw an error
    func testSeekWithoutLoadedTrackThrowsError() async {
        // Given
        let engine = AudioEngineTestHelpers.createMockEngine()
        
        // When & Then
        do {
            try await engine.seek(to: 30.0)
            XCTFail("seek() should throw error when no track is loaded")
        } catch let error as AudioEngineError {
            XCTAssertEqual(error, .noTrackLoaded, "Should throw noTrackLoaded error")
        } catch {
            XCTFail("Should throw AudioEngineError, got: \(error)")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given a playing track, when I perform many seeks, then it should complete quickly
    func testSeekPerformance() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When & Then
        measure {
            Task {
                for position in stride(from: 0.0, through: 180.0, by: 10.0) {
                    try? await engine.seek(to: position)
                }
            }
        }
    }
    
    /// BDD: Given a playing track, when I seek, then it should complete within 10ms (SLA)
    func testSeekAccuracyWithinSLA() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        let startTime = Date()
        try await engine.seek(to: 30.0)
        let seekTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(seekTime, 0.1, "Seek should complete within 100ms (SLA)")
    }
    
    // MARK: - Edge Cases
    
    /// BDD: Given a playing track, when I seek to exact duration, then it should handle correctly
    func testSeekToExactDuration() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(to: 180.0)
        
        // Then
        XCTAssertEqual(engine.currentPosition, 180.0, accuracy: 0.1, "Position should be at exact duration")
    }
    
    /// BDD: Given a playing track, when I seek with very small increments, then it should handle correctly
    func testSeekWithSmallIncrements() async throws {
        // Given
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When
        try await engine.seek(by: 0.001) // 1 millisecond
        
        // Then
        XCTAssertGreaterThan(engine.currentPosition, 0.0, "Position should advance")
    }
}
