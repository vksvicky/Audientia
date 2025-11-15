//
//  ReplayGainCrossCheckerTests.swift
//  AudioCoreTests
//
//  TDD tests for ReplayGain cross-checking with external tools
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// Mock implementation of external ReplayGain tool for testing
@MainActor
final class MockReplayGainExternalTool: ReplayGainExternalToolProtocol {
    var toolName: String = "MockTool"
    
    var mockResult: ReplayGainResult?
    var shouldFail = false
    var analyzeCalled = false
    
    var resultProvider: (() -> ReplayGainResult)?
    
    func analyzeReplayGain(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> ReplayGainResult {
        analyzeCalled = true
        
        if shouldFail {
            throw ReplayGainError.analysisFailed("Mock external tool failure")
        }
        
        if let provider = resultProvider {
            return provider()
        }
        
        guard let result = mockResult else {
            return ReplayGainResult(trackGain: -2.5, peak: 0.9)
        }
        
        return result
    }
}

/// TDD tests for ReplayGain cross-checking
/// Following Right-BICEP principles
@MainActor
final class ReplayGainCrossCheckerTests: XCTestCase {
    
    var replayGain: ReplayGain!
    var mockExternalTool: MockReplayGainExternalTool!
    var crossChecker: ReplayGainCrossChecker!
    
    override func setUp() {
        super.setUp()
        replayGain = ReplayGain()
        mockExternalTool = MockReplayGainExternalTool()
        crossChecker = ReplayGainCrossChecker(
            replayGain: replayGain,
            externalTool: mockExternalTool
        )
    }
    
    override func tearDown() {
        crossChecker = nil
        mockExternalTool = nil
        replayGain = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// Test that cross-checking returns comparison result
    func testCrossCheckReturnsComparisonResult() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        let sampleRate = 44100
        let channels = 2
        
        mockExternalTool.mockResult = ReplayGainResult(trackGain: -2.5, peak: 0.9)
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        XCTAssertNotNil(comparison, "Should return comparison result")
        XCTAssertNotNil(comparison.ourResult, "Should have our result")
        XCTAssertNotNil(comparison.externalResult, "Should have external result")
        XCTAssertEqual(comparison.externalResult.trackGain, -2.5, accuracy: 0.01, "External result should match mock")
        XCTAssertEqual(comparison.externalResult.peak, 0.9, accuracy: 0.01, "External peak should match mock")
    }
    
    /// Test that comparison calculates differences correctly
    func testComparisonCalculatesDifferences() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        mockExternalTool.mockResult = ReplayGainResult(trackGain: -2.0, peak: 0.8)
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        let expectedDifference = comparison.ourResult.trackGain - comparison.externalResult.trackGain
        XCTAssertEqual(comparison.trackGainDifference, expectedDifference, accuracy: 0.01, "Track gain difference should be calculated correctly")
        
        let expectedPeakDifference = abs(comparison.ourResult.peak - comparison.externalResult.peak)
        XCTAssertEqual(comparison.peakDifference, expectedPeakDifference, accuracy: 0.001, "Peak difference should be calculated correctly")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// Test comparison with identical results (should be within tolerance)
    func testComparisonWithIdenticalResults() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        mockExternalTool.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain,
            peak: ourResult.peak
        )
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .default
        )
        
        // Then
        XCTAssertEqual(comparison.trackGainDifference, 0.0, accuracy: 0.01, "Track gain difference should be 0")
        XCTAssertEqual(comparison.peakDifference, 0.0, accuracy: 0.001, "Peak difference should be 0")
        XCTAssertTrue(comparison.isWithinTolerance, "Identical results should be within tolerance")
    }
    
    /// Test comparison with results outside tolerance
    func testComparisonWithResultsOutsideTolerance() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        mockExternalTool.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 2.0, // Large difference
            peak: ourResult.peak + 0.1 // Large peak difference
        )
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .strict
        )
        
        // Then
        XCTAssertFalse(comparison.isWithinTolerance, "Large differences should be outside strict tolerance")
        XCTAssertGreaterThan(abs(comparison.trackGainDifference), 0.1, "Track gain difference should be significant")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test that comparing A vs B gives opposite difference sign as B vs A
    func testComparisonIsSymmetric() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        mockExternalTool.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.3,
            peak: ourResult.peak
        )
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        // Our result - External result = -0.3
        // If we swapped, External - Our = +0.3 (opposite sign)
        XCTAssertEqual(comparison.trackGainDifference, -0.3, accuracy: 0.01, "Difference should be our - external")
    }
    
    // MARK: - [C]ross-Checking
    
    /// Test that tolerance check is correct
    func testToleranceCheckIsCorrect() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Within default tolerance (0.5 dB)
        mockExternalTool.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.3,
            peak: ourResult.peak + 0.005
        )
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .default
        )
        
        // Then
        XCTAssertTrue(comparison.isWithinTolerance, "Should be within default tolerance")
        XCTAssertLessThanOrEqual(abs(comparison.trackGainDifference), 0.5, "Gain difference should be <= 0.5 dB")
        XCTAssertLessThanOrEqual(comparison.peakDifference, 0.01, "Peak difference should be <= 0.01")
    }
    
    // MARK: - [E]rror Conditions
    
    /// Test that external tool failure is handled
    func testExternalToolFailureIsHandled() async {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        mockExternalTool.shouldFail = true
        
        // When & Then
        do {
            _ = try await crossChecker.compareReplayGain(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels
            )
            XCTFail("Should throw error when external tool fails")
        } catch {
            XCTAssertTrue(error is ReplayGainError, "Should throw ReplayGainError")
        }
    }
    
    /// Test that our ReplayGain failure is handled
    func testOurReplayGainFailureIsHandled() async {
        // Given - Invalid audio data
        let audioData: [Float] = []
        let sampleRate = 44100
        let channels = 2
        
        // When & Then
        do {
            _ = try await crossChecker.compareReplayGain(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels
            )
            XCTFail("Should throw error when our ReplayGain fails")
        } catch {
            XCTAssertTrue(error is ReplayGainError, "Should throw ReplayGainError")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// Test that cross-checking completes quickly
    func testCrossCheckingPerformance() async throws {
        // Given
        let audioData = (0..<10000).map { Float.random(in: -1.0...1.0) }
        let sampleRate = 44100
        let channels = 2
        
        mockExternalTool.mockResult = ReplayGainResult(trackGain: -2.5, peak: 0.9)
        
        // When
        let startTime = Date()
        _ = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete quickly (< 1 second for 10k samples)
        XCTAssertLessThan(duration, 1.0, "Cross-checking should complete quickly")
    }
    
    // MARK: - Edge Cases
    
    /// Test album-level comparison
    func testAlbumLevelComparison() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let albumTracks = [
            [Float]([0.5, -0.3, 0.8, -0.2, 0.1, 0.9]),
            [Float]([0.4, -0.4, 0.7, -0.3, 0.2, 0.8]),
            [Float]([0.6, -0.2, 0.9, -0.1, 0.15, 0.95])
        ]
        
        var trackIndex = 0
        mockExternalTool.resultProvider = {
            trackIndex += 1
            return ReplayGainResult(trackGain: Float(-2.0 - Float(trackIndex) * 0.1), peak: 0.9)
        }
        
        // When
        let comparisons = try await crossChecker.compareAlbumReplayGain(
            tracks: albumTracks,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        XCTAssertEqual(comparisons.count, albumTracks.count, "Should compare all tracks")
        XCTAssertTrue(mockExternalTool.analyzeCalled, "External tool should be called")
    }
    
    /// Test with different tolerance levels
    func testDifferentToleranceLevels() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Small difference (0.2 dB)
        mockExternalTool.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.2,
            peak: ourResult.peak
        )
        
        // When - Test with strict tolerance
        let strictComparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .strict
        )
        
        // When - Test with loose tolerance
        let looseComparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .loose
        )
        
        // Then
        XCTAssertFalse(strictComparison.isWithinTolerance, "Should be outside strict tolerance")
        XCTAssertTrue(looseComparison.isWithinTolerance, "Should be within loose tolerance")
    }
}
