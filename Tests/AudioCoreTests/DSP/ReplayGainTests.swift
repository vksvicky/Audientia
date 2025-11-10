//
//  ReplayGainTests.swift
//  AudioCoreTests
//
//  TDD tests for ReplayGain analysis and application
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// TDD tests for ReplayGain
/// Following Right-BICEP principles
final class ReplayGainTests: XCTestCase {
    
    var replayGain: ReplayGain!
    
    override func setUp() {
        super.setUp()
        replayGain = ReplayGain()
    }
    
    override func tearDown() {
        replayGain = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given audio data, when I analyze ReplayGain, then I should get track gain and peak values
    func testAnalyzeReplayGainReturnsResult() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9, -0.4, 0.7]
        
        // When
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then
        XCTAssertNotNil(result, "Should return ReplayGain result")
        XCTAssertFalse(result.trackGain.isNaN, "Track gain should not be NaN")
        XCTAssertFalse(result.trackGain.isInfinite, "Track gain should not be infinite")
        XCTAssertGreaterThanOrEqual(result.peak, 0.0, "Peak should be >= 0")
        XCTAssertLessThanOrEqual(result.peak, 1.0, "Peak should be <= 1.0")
    }
    
    /// BDD: Given audio data, when I apply ReplayGain, then audio should be modified
    func testApplyReplayGainModifiesAudio() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let replayGainResult = ReplayGainResult(trackGain: -3.0, peak: 0.8)
        
        // When
        let processed = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGainResult,
            mode: .track
        )
        
        // Then
        XCTAssertEqual(processed.count, audioData.count, "Output should have same length as input")
        // Audio should be modified (gain applied)
        XCTAssertNotEqual(processed, audioData, "Audio should be modified by ReplayGain")
    }
    
    /// BDD: Given audio data with ReplayGain applied, when gain is 0.0 dB, then audio should be unchanged
    func testApplyZeroGainDoesNotModifyAudio() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let replayGainResult = ReplayGainResult(trackGain: 0.0, peak: 0.8)
        
        // When
        let processed = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGainResult,
            mode: .track
        )
        
        // Then
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(processed[index], value, accuracy: 0.001, "Zero gain should not modify audio at index \(index)")
        }
    }
    
    /// BDD: Given multiple track ReplayGain results, when I calculate album gain, then I should get average gain
    func testCalculateAlbumGain() async throws {
        // Given
        let trackResults = [
            ReplayGainResult(trackGain: -2.0, peak: 0.8),
            ReplayGainResult(trackGain: -3.0, peak: 0.9),
            ReplayGainResult(trackGain: -1.5, peak: 0.7)
        ]
        
        // When
        let albumGain = try await replayGain.calculateAlbumGain(from: trackResults)
        
        // Then
        // Album gain should be average of track gains: (-2.0 + -3.0 + -1.5) / 3 = -2.167
        XCTAssertEqual(albumGain, -2.167, accuracy: 0.1, "Album gain should be average of track gains")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given empty audio data, when I analyze ReplayGain, then it should throw error
    func testAnalyzeEmptyAudioThrowsError() async {
        // Given
        let emptyAudio: [Float] = []
        
        // When & Then
        do {
            _ = try await replayGain.analyzeReplayGain(
                audioData: emptyAudio,
                sampleRate: 44100,
                channels: 2
            )
            XCTFail("Should throw error for empty audio")
        } catch let error as ReplayGainError {
            XCTAssertEqual(error, .invalidAudioData, "Should throw invalidAudioData error")
        } catch {
            XCTFail("Should throw ReplayGainError, got: \(error)")
        }
    }
    
    /// BDD: Given audio with invalid sample rate, when I analyze ReplayGain, then it should throw error
    func testAnalyzeWithInvalidSampleRateThrowsError() async {
        // Given
        let audioData: [Float] = [0.5, -0.3]
        
        // When & Then
        do {
            _ = try await replayGain.analyzeReplayGain(
                audioData: audioData,
                sampleRate: 0,
                channels: 2
            )
            XCTFail("Should throw error for invalid sample rate")
        } catch let error as ReplayGainError {
            XCTAssertEqual(error, .invalidSampleRate, "Should throw invalidSampleRate error")
        } catch {
            XCTFail("Should throw ReplayGainError, got: \(error)")
        }
    }
    
    /// BDD: Given audio with very low peak, when I analyze ReplayGain, then gain should be positive
    func testAnalyzeLowPeakAudio() async throws {
        // Given - Very quiet audio
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.01, -0.01, 0.02, -0.02, 0.01, 0.01]
        
        // When
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Low peak should result in positive gain (to boost quiet audio)
        XCTAssertGreaterThan(result.trackGain, 0.0, "Low peak audio should have positive gain")
        XCTAssertLessThan(result.peak, 0.1, "Peak should be low for quiet audio")
    }
    
    /// BDD: Given audio with very high peak, when I analyze ReplayGain, then gain should be negative
    func testAnalyzeHighPeakAudio() async throws {
        // Given - Very loud audio (near clipping)
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.95, -0.95, 0.98, -0.98, 0.99, -0.99]
        
        // When
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - High peak should result in negative gain (to reduce loud audio)
        XCTAssertLessThan(result.trackGain, 0.0, "High peak audio should have negative gain")
        XCTAssertGreaterThan(result.peak, 0.9, "Peak should be high for loud audio")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// BDD: Given audio, when I analyze then apply ReplayGain, then result should be normalized
    func testAnalyzeThenApplyRoundtrip() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        
        // When - Analyze
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // When - Apply
        let processed = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: result,
            mode: .track
        )
        
        // Then - Processed audio should be normalized (peak closer to target)
        let processedPeak = processed.map { abs($0) }.max() ?? 0.0
        // After applying ReplayGain, the peak should be closer to a target level (typically around -0.1 to -0.3 dB)
        XCTAssertLessThan(processedPeak, 1.0, "Processed peak should not exceed 1.0")
    }
    
    // MARK: - [C]ross-Checking Using Other Means
    
    /// BDD: Given audio data, when I analyze ReplayGain multiple times, then results should be consistent
    func testAnalyzeReplayGainConsistency() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2, 0.1, 0.9]
        
        // When - Analyze twice
        let result1 = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        let result2 = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Results should be consistent
        XCTAssertEqual(result1.trackGain, result2.trackGain, accuracy: 0.01, "Track gain should be consistent")
        XCTAssertEqual(result1.peak, result2.peak, accuracy: 0.001, "Peak should be consistent")
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given ReplayGain result, when I apply with album mode but no album gain, then it should throw error
    func testApplyAlbumGainWithoutAlbumGainThrowsError() async {
        // Given
        let audioData: [Float] = [0.5, -0.3]
        let replayGainResult = ReplayGainResult(trackGain: -2.0, albumGain: nil, peak: 0.8)
        
        // When & Then
        do {
            _ = try await replayGain.applyReplayGain(
                audioData: audioData,
                replayGain: replayGainResult,
                mode: .album
            )
            XCTFail("Should throw error when album gain not available")
        } catch let error as ReplayGainError {
            XCTAssertEqual(error, .noAlbumGainAvailable, "Should throw noAlbumGainAvailable error")
        } catch {
            XCTFail("Should throw ReplayGainError, got: \(error)")
        }
    }
    
    /// BDD: Given empty track results, when I calculate album gain, then it should throw error
    func testCalculateAlbumGainWithEmptyResultsThrowsError() async {
        // Given
        let emptyResults: [ReplayGainResult] = []
        
        // When & Then
        do {
            _ = try await replayGain.calculateAlbumGain(from: emptyResults)
            XCTFail("Should throw error for empty track results")
        } catch let error as ReplayGainError {
            XCTAssertEqual(error, .invalidTrackResults, "Should throw invalidTrackResults error")
        } catch {
            XCTFail("Should throw ReplayGainError, got: \(error)")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given audio data, when I analyze ReplayGain, then it should complete quickly
    func testAnalyzeReplayGainPerformance() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let durationSeconds: Float = 1.0
        let sampleCount = Int(Float(sampleRate) * durationSeconds * Float(channels))
        let audioData = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        
        // When & Then
        measure {
            Task {
                _ = try? await replayGain.analyzeReplayGain(
                    audioData: audioData,
                    sampleRate: sampleRate,
                    channels: channels
                )
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// BDD: Given audio with all zeros (silence), when I analyze ReplayGain, then it should handle gracefully
    func testAnalyzeSilentAudio() async throws {
        // Given - Silent audio
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = Array(repeating: 0.0, count: 100)
        
        // When
        let result = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Should handle silence gracefully
        XCTAssertEqual(result.peak, 0.0, accuracy: 0.001, "Peak should be 0 for silence")
        // Gain might be 0 or a default value for silence
    }
    
    /// BDD: Given ReplayGain result, when I apply with off mode, then audio should be unchanged
    func testApplyReplayGainOffModeDoesNotModify() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let replayGainResult = ReplayGainResult(trackGain: -3.0, peak: 0.8)
        
        // When
        let processed = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGainResult,
            mode: .off
        )
        
        // Then - Should be unchanged
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(processed[index], value, accuracy: 0.001, "Off mode should not modify audio")
        }
    }
    
    /// BDD: Given ReplayGain result with album gain, when I apply with album mode, then it should use album gain
    func testApplyAlbumGainMode() async throws {
        // Given
        let audioData: [Float] = [0.5, -0.3, 0.8, -0.2]
        let replayGainResult = ReplayGainResult(trackGain: -2.0, albumGain: -3.0, peak: 0.8)
        
        // When
        let processedTrack = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGainResult,
            mode: .track
        )
        let processedAlbum = try await replayGain.applyReplayGain(
            audioData: audioData,
            replayGain: replayGainResult,
            mode: .album
        )
        
        // Then - Album mode should use different gain than track mode
        XCTAssertNotEqual(processedTrack, processedAlbum, "Album mode should use different gain than track mode")
    }
}
