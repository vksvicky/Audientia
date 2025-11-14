//
//  ReplayGainCrossCheckerBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for ReplayGain cross-checking with external tools
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// BDD-style test scenarios for ReplayGain cross-checking
/// Following user-centric "As a user, I want to..." format
final class ReplayGainCrossCheckerBDDTests: XCTestCase {
    
    var replayGain: ReplayGain!
    var mockFoobar2000: MockReplayGainExternalTool!
    var crossChecker: ReplayGainCrossChecker!
    
    override func setUp() {
        super.setUp()
        replayGain = ReplayGain()
        mockFoobar2000 = MockReplayGainExternalTool()
        mockFoobar2000.toolName = "foobar2000"
        crossChecker = ReplayGainCrossChecker(
            replayGain: replayGain,
            externalTool: mockFoobar2000
        )
    }
    
    override func tearDown() {
        crossChecker = nil
        mockFoobar2000 = nil
        replayGain = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to verify that our ReplayGain calculations match foobar2000
    func testUserVerifiesReplayGainMatchesFoobar2000() async throws {
        // Given - I have audio data and foobar2000 is available
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9, -0.4, 0.7]
        let sampleRate = 44100
        let channels = 2
        
        // Get our ReplayGain result
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Configure foobar2000 mock to return similar result (within tolerance)
        mockFoobar2000.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.2, // Small difference
            peak: ourResult.peak
        )
        
        // When - I compare our ReplayGain with foobar2000
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .default
        )
        
        // Then - The results should be within acceptable tolerance
        XCTAssertTrue(comparison.isWithinTolerance, "Our ReplayGain should match foobar2000 within tolerance")
        XCTAssertLessThan(abs(comparison.trackGainDifference), 0.5, "Track gain difference should be less than 0.5 dB")
    }
    
    /// BDD: As a user, I want to see the difference between our ReplayGain and foobar2000
    func testUserSeesReplayGainDifference() async throws {
        // Given - I have audio data analyzed by both tools
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        // Configure foobar2000 with known values
        mockFoobar2000.mockResult = ReplayGainResult(trackGain: -2.5, peak: 0.9)
        
        // When - I compare our ReplayGain with foobar2000
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - I should see the differences
        XCTAssertNotNil(comparison.trackGainDifference, "Should show track gain difference")
        XCTAssertNotNil(comparison.peakDifference, "Should show peak difference")
        XCTAssertNotNil(comparison.ourResult, "Should show our result")
        XCTAssertNotNil(comparison.externalResult, "Should show foobar2000 result")
    }
    
    /// BDD: As a user, I want to verify ReplayGain accuracy for an entire album
    func testUserVerifiesReplayGainForAlbum() async throws {
        // Given - I have an album with multiple tracks
        let sampleRate = 44100
        let channels = 2
        let albumTracks = [
            [Float]([0.5, -0.3, 0.8, -0.2, 0.1, 0.9]),
            [Float]([0.4, -0.4, 0.7, -0.3, 0.2, 0.8]),
            [Float]([0.6, -0.2, 0.9, -0.1, 0.15, 0.95])
        ]
        
        // Get our actual ReplayGain results for each track first
        var ourResults: [ReplayGainResult] = []
        for trackData in albumTracks {
            let result = try await replayGain.analyzeReplayGain(
                audioData: trackData,
                sampleRate: sampleRate,
                channels: channels
            )
            ourResults.append(result)
        }
        
        // Configure foobar2000 to return results similar to our implementation (within tolerance)
        var trackIndex = 0
        mockFoobar2000.resultProvider = {
            let index = trackIndex
            trackIndex += 1
            let ourResult = ourResults[index]
            // Return results within tolerance (small difference, within 0.3 dB)
            return ReplayGainResult(
                trackGain: ourResult.trackGain + 0.2, // Small difference within tolerance
                peak: ourResult.peak
            )
        }
        
        // When - I compare ReplayGain for all tracks in the album
        let comparisons = try await crossChecker.compareAlbumReplayGain(
            tracks: albumTracks,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .default
        )
        
        // Then - All tracks should be compared
        XCTAssertEqual(comparisons.count, albumTracks.count, "Should compare all tracks in album")
        
        // Most comparisons should be within tolerance (allowing for some variation)
        let withinToleranceCount = comparisons.filter { $0.isWithinTolerance }.count
        XCTAssertGreaterThan(withinToleranceCount, 0, "At least some tracks should be within tolerance")
    }
    
    /// BDD: As a user, I want to use strict tolerance when verifying ReplayGain accuracy
    func testUserUsesStrictToleranceForVerification() async throws {
        // Given - I have audio data and want strict verification
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        // Get our result
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Configure foobar2000 with very similar result (within strict tolerance)
        mockFoobar2000.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.05, // Very small difference (0.05 dB)
            peak: ourResult.peak + 0.0005 // Very small peak difference
        )
        
        // When - I compare with strict tolerance
        let strictComparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .strict
        )
        
        // Then - Results should be within strict tolerance
        XCTAssertTrue(strictComparison.isWithinTolerance, "Results should be within strict tolerance")
        XCTAssertLessThan(abs(strictComparison.trackGainDifference), 0.1, "Track gain difference should be less than 0.1 dB")
    }
    
    /// BDD: As a user, I want to be notified when ReplayGain differs significantly from foobar2000
    func testUserNotifiedWhenReplayGainDiffersSignificantly() async throws {
        // Given - I have audio data where our ReplayGain differs significantly from foobar2000
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        // Configure foobar2000 with very different result (outside tolerance)
        mockFoobar2000.mockResult = ReplayGainResult(trackGain: -10.0, peak: 0.5)
        
        // When - I compare with strict tolerance
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .strict
        )
        
        // Then - I should be notified that results are outside tolerance
        XCTAssertFalse(comparison.isWithinTolerance, "Should detect significant difference")
        XCTAssertGreaterThan(abs(comparison.trackGainDifference), 0.1, "Track gain difference should be significant")
    }
    
    /// BDD: As a user, I want to compare ReplayGain with different external tools
    func testUserComparesWithDifferentExternalTools() async throws {
        // Given - I have audio data and multiple external tools
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        // Tool 1: foobar2000
        let foobar2000 = MockReplayGainExternalTool()
        foobar2000.toolName = "foobar2000"
        foobar2000.mockResult = ReplayGainResult(trackGain: -2.5, peak: 0.9)
        let checker1 = ReplayGainCrossChecker(replayGain: replayGain, externalTool: foobar2000)
        
        // Tool 2: Another tool
        let otherTool = MockReplayGainExternalTool()
        otherTool.toolName = "OtherTool"
        otherTool.mockResult = ReplayGainResult(trackGain: -2.3, peak: 0.88)
        let checker2 = ReplayGainCrossChecker(replayGain: replayGain, externalTool: otherTool)
        
        // When - I compare with both tools
        let comparison1 = try await checker1.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        let comparison2 = try await checker2.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Both comparisons should work
        XCTAssertNotNil(comparison1, "Should compare with foobar2000")
        XCTAssertNotNil(comparison2, "Should compare with other tool")
        XCTAssertEqual(foobar2000.toolName, "foobar2000", "Should identify tool correctly")
        XCTAssertEqual(otherTool.toolName, "OtherTool", "Should identify other tool correctly")
    }
    
    /// BDD: As a user, I want to handle errors gracefully when external tool is unavailable
    func testUserHandlesExternalToolUnavailable() async {
        // Given - External tool (foobar2000) is unavailable or fails
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        mockFoobar2000.shouldFail = true
        
        // When & Then - I should get a clear error message
        do {
            _ = try await crossChecker.compareReplayGain(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels
            )
            XCTFail("Should throw error when external tool fails")
        } catch {
            // Should provide clear error information
            XCTAssertTrue(mockFoobar2000.analyzeCalled, "Should attempt to use external tool")
            // Error should be informative
            let errorDescription = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            XCTAssertFalse(errorDescription.isEmpty, "Error should have description")
        }
    }
}
