//
//  ReplayGainBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for ReplayGain analysis and application
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// BDD-style test scenarios for ReplayGain
/// Following user-centric "As a user, I want to..." format
final class ReplayGainBDDTests: XCTestCase {
    
    var replayGain: ReplayGain!
    
    override func setUp() {
        super.setUp()
        replayGain = ReplayGain()
    }
    
    override func tearDown() {
        replayGain = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want my music library to play at consistent volume levels
    func testNormalizeLibraryVolumeLevels() async throws {
        // Given - I have tracks with different volume levels
        let sampleRate = 44100
        let channels = 2
        
        // Track 1: Quiet audio
        let quietAudio: [Float] = [0.1, -0.1, 0.15, -0.15, 0.12, 0.1]
        let quietResult = try await replayGain.analyzeReplayGain(
            audioData: quietAudio,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Track 2: Loud audio
        let loudAudio: [Float] = [0.9, -0.9, 0.95, -0.95, 0.98, -0.98]
        let loudResult = try await replayGain.analyzeReplayGain(
            audioData: loudAudio,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // When - I apply ReplayGain to both tracks
        let normalizedQuiet = try await replayGain.applyReplayGain(
            audioData: quietAudio,
            replayGain: quietResult,
            mode: .track
        )
        let normalizedLoud = try await replayGain.applyReplayGain(
            audioData: loudAudio,
            replayGain: loudResult,
            mode: .track
        )
        
        // Then - Both tracks should have similar volume levels
        let quietPeak = normalizedQuiet.map { abs($0) }.max() ?? 0.0
        let loudPeak = normalizedLoud.map { abs($0) }.max() ?? 0.0
        
        // Peaks should be closer together after normalization
        let peakDifference = abs(quietPeak - loudPeak)
        XCTAssertLessThan(peakDifference, 0.3, "Normalized tracks should have similar peak levels")
    }
    
    /// BDD: As a user, I want to analyze a track and get its ReplayGain value
    func testAnalyzeTrackReplayGain() async throws {
        // Given - I have a track playing
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9, -0.4, 0.7]
        
        // When - I analyze the track for ReplayGain
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - I should get track gain and peak values
        XCTAssertNotNil(result, "Should get ReplayGain result")
        XCTAssertFalse(result.trackGain.isNaN, "Track gain should be valid")
        XCTAssertGreaterThanOrEqual(result.peak, 0.0, "Peak should be >= 0")
        XCTAssertLessThanOrEqual(result.peak, 1.0, "Peak should be <= 1.0")
    }
    
    /// BDD: As a user, I want to apply ReplayGain to normalize a track's volume
    func testApplyReplayGainToTrack() async throws {
        // Given - I have a track and its ReplayGain analysis
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.8, -0.8, 0.9, -0.9, 0.95, -0.95]
        
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // When - I apply ReplayGain to the track
        let normalized = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: result,
            mode: .track
        )
        
        // Then - The track should be normalized
        XCTAssertNotEqual(normalized, audioData, "Audio should be modified by ReplayGain")
        XCTAssertEqual(normalized.count, audioData.count, "Output length should match input")
        
        // And - The peak should be reduced (for loud tracks)
        let originalPeak = audioData.map { abs($0) }.max() ?? 0.0
        let normalizedPeak = normalized.map { abs($0) }.max() ?? 0.0
        if originalPeak > 0.8 {
            XCTAssertLessThan(normalizedPeak, originalPeak, "Loud tracks should have reduced peak after normalization")
        }
    }
    
    /// BDD: As a user, I want to normalize an entire album using album gain
    func testNormalizeAlbumWithAlbumGain() async throws {
        // Given - I have an album with multiple tracks
        let sampleRate = 44100
        let channels = 2
        
        let track1Audio: [Float] = [0.5, -0.3, 0.8, -0.2]
        let track2Audio: [Float] = [0.6, -0.4, 0.7, -0.3]
        let track3Audio: [Float] = [0.4, -0.2, 0.9, -0.1]
        
        // When - I analyze each track
        let track1Result = try await replayGain.analyzeReplayGain(
            audioData: track1Audio,
            sampleRate: sampleRate,
            channels: channels
        )
        let track2Result = try await replayGain.analyzeReplayGain(
            audioData: track2Audio,
            sampleRate: sampleRate,
            channels: channels
        )
        let track3Result = try await replayGain.analyzeReplayGain(
            audioData: track3Audio,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // And - I calculate album gain
        let albumGain = try await replayGain.calculateAlbumGain(from: [track1Result, track2Result, track3Result])
        
        // Then - I can apply album gain to all tracks
        let albumResult1 = ReplayGainResult(
            trackGain: track1Result.trackGain,
            albumGain: albumGain,
            peak: track1Result.peak
        )
        let normalized1 = try await replayGain.applyReplayGain(
            audioData: track1Audio,
            replayGain: albumResult1,
            mode: .album
        )
        
        // Album gain should be applied
        XCTAssertNotEqual(normalized1, track1Audio, "Album gain should modify audio")
    }
    
    /// BDD: As a user, I want to disable ReplayGain if I prefer original volume levels
    func testDisableReplayGain() async throws {
        // Given - I have a track with ReplayGain analysis
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // When - I apply ReplayGain with mode "off"
        let processed = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: result,
            mode: .off
        )
        
        // Then - The audio should be unchanged
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(processed[index], value, accuracy: 0.001, "Off mode should not modify audio")
        }
    }
    
    /// BDD: As a user, I want to see the peak amplitude of my tracks
    func testViewPeakAmplitude() async throws {
        // Given - I have a track
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.7, -0.5, 0.9, -0.3, 0.8, -0.6]
        
        // When - I analyze ReplayGain
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - I should see the peak amplitude
        let expectedPeak = audioData.map { abs($0) }.max() ?? 0.0
        XCTAssertEqual(result.peak, expectedPeak, accuracy: 0.01, "Peak should match maximum absolute value")
    }
    
    /// BDD: As a user, I want quiet tracks to be boosted and loud tracks to be reduced
    func testNormalizeQuietAndLoudTracks() async throws {
        // Given - I have a quiet track and a loud track
        let sampleRate = 44100
        let channels = 2
        
        let quietAudio: [Float] = [0.05, -0.05, 0.08, -0.08, 0.06, 0.05]
        let loudAudio: [Float] = [0.95, -0.95, 0.98, -0.98, 0.99, -0.99]
        
        // When - I analyze both
        let quietResult = try await replayGain.analyzeReplayGain(
            audioData: quietAudio,
            sampleRate: sampleRate,
            channels: channels
        )
        let loudResult = try await replayGain.analyzeReplayGain(
            audioData: loudAudio,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Quiet track should have positive gain (boost)
        XCTAssertGreaterThan(quietResult.trackGain, 0.0, "Quiet tracks should have positive gain")
        
        // And - Loud track should have negative gain (reduction)
        XCTAssertLessThan(loudResult.trackGain, 0.0, "Loud tracks should have negative gain")
    }
    
    /// BDD: As a user, I want to prevent clipping when applying ReplayGain
    func testPreventClippingWhenApplyingReplayGain() async throws {
        // Given - I have a track with high peak
        let audioData: [Float] = [0.95, -0.95, 0.98, -0.98]
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // When - I apply ReplayGain
        let processed = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: result,
            mode: .track
        )
        
        // Then - No samples should exceed 1.0 or -1.0
        for sample in processed {
            XCTAssertLessThanOrEqual(abs(sample), 1.0, "No sample should exceed 1.0 after ReplayGain")
        }
    }
}
