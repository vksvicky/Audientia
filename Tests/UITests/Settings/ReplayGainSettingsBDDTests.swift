//
//  ReplayGainSettingsBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for ReplayGain Settings
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import AudioCore
@testable import Shared

/// BDD Scenarios for ReplayGain Settings
@MainActor
final class ReplayGainSettingsBDDTests: XCTestCase {
    
    private var mockReplayGain: MockReplayGain!
    
    override func setUp() {
        super.setUp()
        mockReplayGain = MockReplayGain()
    }
    
    override func tearDown() {
        mockReplayGain = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Analyze Track ReplayGain
    
    /// BDD: As a user, when I analyze a track for ReplayGain, then I should see the track gain value
    func testUserAnalyzesTrackReplayGain() async throws {
        // Given - Audio data for a track
        let audioData: [Float] = Array(repeating: 0.5, count: 1000)
        let sampleRate = 44100
        let channels = 2
        
        // When - User analyzes track ReplayGain
        let result = try await mockReplayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Should return ReplayGain result
        XCTAssertNotNil(result, "Should return ReplayGain result")
        XCTAssertTrue(mockReplayGain.analyzeCalled, "analyzeReplayGain should have been called")
        XCTAssertNotNil(result.trackGain, "Should have track gain")
        XCTAssertNotNil(result.peak, "Should have peak value")
    }
    
    // MARK: - BDD Scenario 2: Apply Track Gain
    
    /// BDD: As a user, when I apply track ReplayGain, then the track should play at consistent volume
    func testUserAppliesTrackGain() async throws {
        // Given - Audio data and ReplayGain result
        let audioData: [Float] = [0.5, 0.3, 0.7, 0.2]
        let replayGain = ReplayGainResult(trackGain: -3.0, albumGain: -3.5, peak: 0.95)
        
        // When - User applies track gain
        let processed = try await mockReplayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGain,
            mode: ReplayGainMode.track
        )
        
        // Then - Audio should be processed
        XCTAssertEqual(processed.count, audioData.count, "Should have same number of samples")
        XCTAssertTrue(mockReplayGain.applyCalled, "apply should have been called")
    }
    
    // MARK: - BDD Scenario 3: Apply Album Gain
    
    /// BDD: As a user, when I apply album ReplayGain, then all tracks in the album should play at consistent volume
    func testUserAppliesAlbumGain() async throws {
        // Given - Audio data and ReplayGain result with album gain
        let audioData: [Float] = [0.5, 0.3, 0.7, 0.2]
        let replayGain = ReplayGainResult(trackGain: -3.0, albumGain: -3.5, peak: 0.95)
        
        // When - User applies album gain
        let processed = try await mockReplayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGain,
            mode: ReplayGainMode.album
        )
        
        // Then - Audio should be processed with album gain
        XCTAssertEqual(processed.count, audioData.count, "Should have same number of samples")
        XCTAssertTrue(mockReplayGain.applyCalled, "apply should have been called")
    }
    
    // MARK: - BDD Scenario 4: Peak Limiting
    
    /// BDD: As a user, when ReplayGain is applied, then audio should not exceed the peak limit
    func testPeakLimiting() async throws {
        // Given - Audio data that would exceed peak
        let audioData: [Float] = [1.0, 0.8, 0.9] // High levels
        let replayGain = ReplayGainResult(trackGain: 3.0, albumGain: nil, peak: 0.95)
        
        // When - User applies ReplayGain with gain boost
        let processed = try await mockReplayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGain,
            mode: ReplayGainMode.track
        )
        
        // Then - Audio should be limited to peak
        for sample in processed {
            XCTAssertLessThanOrEqual(abs(sample), replayGain.peak + 0.01, "Samples should not exceed peak (with tolerance)")
        }
    }
    
    // MARK: - Boundary Condition Tests
    
    /// Test with very quiet audio
    func testVeryQuietAudio() async throws {
        // Given - Very quiet audio data
        let audioData: [Float] = Array(repeating: 0.01, count: 100)
        
        // When - User analyzes ReplayGain
        let result = try await mockReplayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // Then - Should handle quiet audio gracefully
        XCTAssertNotNil(result, "Should return result for quiet audio")
    }
    
    /// Test with very loud audio
    func testVeryLoudAudio() async throws {
        // Given - Very loud audio data
        let audioData: [Float] = Array(repeating: 0.99, count: 100)
        
        // When - User analyzes ReplayGain
        let result = try await mockReplayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // Then - Should handle loud audio gracefully
        XCTAssertNotNil(result, "Should return result for loud audio")
    }
    
    // MARK: - Error Condition Tests
    
    /// Test handling of analysis errors
    func testAnalysisError() async {
        // Given - ReplayGain is configured to fail analysis
        mockReplayGain.shouldFailAnalyze = true
        
        // When - User tries to analyze
        do {
            let audioData: [Float] = [0.5, 0.3, 0.7]
            _ = try await mockReplayGain.analyzeReplayGain(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2
            )
            XCTFail("Should throw error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(mockReplayGain.analyzeCalled, "analyzeReplayGain should have been called")
        }
    }
    
    /// Test handling of application errors
    func testApplicationError() async {
        // Given - ReplayGain is configured to fail application
        mockReplayGain.shouldFailApply = true
        
        // When - User tries to apply ReplayGain
        do {
            let audioData: [Float] = [0.5, 0.3, 0.7]
            let replayGain = ReplayGainResult(trackGain: -3.0, albumGain: nil, peak: 0.95)
            _ = try await mockReplayGain.applyReplayGain(
                audioData: audioData,
                replayGain: replayGain,
                mode: ReplayGainMode.track
            )
            XCTFail("Should throw error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(mockReplayGain.applyCalled, "apply should have been called")
        }
    }
    
    // MARK: - Cross-Check Tests
    
    /// Test that track gain and album gain are different when both are present
    func testTrackVsAlbumGain() async throws {
        // Given - ReplayGain result with both track and album gain
        let audioData: [Float] = Array(repeating: 0.5, count: 100)
        let result = try await mockReplayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // When - Applying track gain vs album gain
        let trackProcessed = try await mockReplayGain.applyReplayGain(
            audioData: audioData,
            replayGain: result,
            mode: ReplayGainMode.track
        )
        
        let albumProcessed = try await mockReplayGain.applyReplayGain(
            audioData: audioData,
            replayGain: result,
            mode: ReplayGainMode.album
        )
        
        // Then - Results should be different if album gain differs
        if let albumGain = result.albumGain, albumGain != result.trackGain {
            // If album gain is different, processed audio should differ
            XCTAssertNotEqual(trackProcessed, albumProcessed, "Track and album gain should produce different results")
        }
    }
}
