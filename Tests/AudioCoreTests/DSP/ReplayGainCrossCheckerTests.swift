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
import XCTest

/// TDD tests for ReplayGain cross-checking
/// Following Right-BICEP principles
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
        
        // Configure mock to return known values
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
        
        // Configure mock with known values
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
        
        // Get our result first
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Configure mock to return same result
        mockExternalTool.mockResult = ourResult
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .default
        )
        
        // Then
        XCTAssertEqual(comparison.trackGainDifference, 0.0, accuracy: 0.01, "Identical results should have zero difference")
        XCTAssertEqual(comparison.peakDifference, 0.0, accuracy: 0.001, "Identical peaks should have zero difference")
        XCTAssertTrue(comparison.isWithinTolerance, "Identical results should be within tolerance")
    }
    
    /// Test comparison with results outside tolerance
    func testComparisonWithResultsOutsideTolerance() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        // Configure mock with very different result (outside default tolerance)
        mockExternalTool.mockResult = ReplayGainResult(trackGain: -10.0, peak: 0.5)
        
        // When
        let comparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .strict // Use strict tolerance
        )
        
        // Then
        XCTAssertFalse(comparison.isWithinTolerance, "Results with large differences should be outside strict tolerance")
    }
    
    /// Test comparison with empty audio data (should propagate error)
    func testComparisonWithEmptyAudioThrowsError() async {
        // Given
        let emptyAudio: [Float] = []
        let sampleRate = 44100
        let channels = 2
        
        // When & Then
        do {
            _ = try await crossChecker.compareReplayGain(
                audioData: emptyAudio,
                sampleRate: sampleRate,
                channels: channels
            )
            XCTFail("Should throw error for empty audio")
        } catch {
            // Expected error
            XCTAssertTrue(error is ReplayGainError, "Should throw ReplayGainError")
        }
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test that comparing same audio twice yields consistent results
    func testComparisonConsistency() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        let sampleRate = 44100
        let channels = 2
        
        mockExternalTool.mockResult = ReplayGainResult(trackGain: -2.5, peak: 0.9)
        
        // When - Compare twice
        let comparison1 = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        let comparison2 = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Results should be consistent
        XCTAssertEqual(comparison1.trackGainDifference, comparison2.trackGainDifference, accuracy: 0.01, "Comparisons should be consistent")
        XCTAssertEqual(comparison1.peakDifference, comparison2.peakDifference, accuracy: 0.001, "Peak differences should be consistent")
    }
    
    // MARK: - [C]ross-Check Using Other Means
    
    /// Test that tolerance settings affect comparison result
    func testToleranceSettingsAffectComparison() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let sampleRate = 44100
        let channels = 2
        
        // Get our result
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Configure mock with slightly different result (within loose but outside strict)
        let slightlyDifferent = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.3, // 0.3 dB difference
            peak: ourResult.peak + 0.02 // 0.02 peak difference
        )
        mockExternalTool.mockResult = slightlyDifferent
        
        // When - Compare with strict tolerance
        let strictComparison = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            tolerance: .strict
        )
        
        // When - Compare with loose tolerance
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
    
    // MARK: - [E]rror Conditions
    
    /// Test that external tool errors are propagated
    func testExternalToolErrorPropagation() async {
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
            XCTFail("Should propagate external tool error")
        } catch {
            // Expected error from external tool
            XCTAssertTrue(mockExternalTool.analyzeCalled, "External tool should have been called")
        }
    }
    
    /// Test that our ReplayGain errors are propagated
    func testOurReplayGainErrorPropagation() async {
        // Given
        let emptyAudio: [Float] = []
        let sampleRate = 44100
        let channels = 2
        
        // When & Then
        do {
            _ = try await crossChecker.compareReplayGain(
                audioData: emptyAudio,
                sampleRate: sampleRate,
                channels: channels
            )
            XCTFail("Should propagate our ReplayGain error")
        } catch let error as ReplayGainError {
            XCTAssertEqual(error, .invalidAudioData, "Should throw invalidAudioData error")
        } catch {
            XCTFail("Should throw ReplayGainError, got: \(error)")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// Test that comparison completes within reasonable time
    func testComparisonPerformance() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let durationSeconds: Float = 0.1 // 100ms of audio
        let sampleCount = Int(Float(sampleRate) * durationSeconds * Float(channels))
        let audioData = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        
        mockExternalTool.mockResult = ReplayGainResult(trackGain: -2.5, peak: 0.9)
        
        // When & Then
        let startTime = Date()
        _ = try await crossChecker.compareReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete within 1 second (SLA: < 1s for comparison)
        XCTAssertLessThan(duration, 1.0, "Comparison should complete within 1 second")
    }
    
    // MARK: - Edge Cases
    
    /// Test album gain comparison with multiple tracks
    func testAlbumGainComparison() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let tracks = [
            [Float]([0.5, -0.3, 0.8, -0.2]),
            [Float]([0.4, -0.4, 0.7, -0.3]),
            [Float]([0.6, -0.2, 0.9, -0.1])
        ]
        
        // Configure mock to return different results for each call
        var callCount = 0
        mockExternalTool.resultProvider = {
            callCount += 1
            return ReplayGainResult(trackGain: Float(-2.0 - Float(callCount) * 0.5), peak: 0.8)
        }
        
        // When
        let comparisons = try await crossChecker.compareAlbumReplayGain(
            tracks: tracks,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        XCTAssertEqual(comparisons.count, tracks.count, "Should return comparison for each track")
        XCTAssertEqual(callCount, tracks.count, "External tool should be called for each track")
    }
    
    /// Test comparison with very quiet audio
    func testComparisonWithQuietAudio() async throws {
        // Given
        let audioData: [Float] = [0.01, -0.01, 0.02, -0.02]
        let sampleRate = 44100
        let channels = 2
        
        // Get our result
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Configure mock with similar result
        mockExternalTool.mockResult = ReplayGainResult(
            trackGain: ourResult.trackGain + 0.2, // Small difference
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
        XCTAssertNotNil(comparison, "Should handle quiet audio")
        // Small differences should be within default tolerance
        if abs(comparison.trackGainDifference) <= 0.5 {
            XCTAssertTrue(comparison.isWithinTolerance, "Small differences should be within default tolerance")
        }
    }
}

// MARK: - Mock External Tool

/// Mock implementation of ReplayGainExternalToolProtocol for testing
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
            // Default mock result
            return ReplayGainResult(trackGain: -2.5, peak: 0.9)
        }
        
        return result
    }
}
