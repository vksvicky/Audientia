//
//  CrossfadeTests.swift
//  AudioCoreTests
//
//  TDD tests for crossfade between tracks
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// TDD tests for Crossfade
/// Following Right-BICEP principles
final class CrossfadeTests: XCTestCase {
    
    var crossfade: Crossfade!
    
    override func setUp() {
        super.setUp()
        crossfade = Crossfade()
    }
    
    override func tearDown() {
        crossfade = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given two audio buffers, when I apply crossfade, then output should blend them
    func testApplyCrossfadeBlendsAudio() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let duration: TimeInterval = 0.1 // 100ms crossfade
        let config = CrossfadeConfig(duration: duration, curve: .linear)
        
        // Outgoing track (fading out)
        let outgoingAudio: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6]
        // Incoming track (fading in)
        let incomingAudio: [Float] = [0.1, -0.1, 0.2, -0.2, 0.3, -0.3]
        
        // When
        let crossfaded = try await crossfade.applyCrossfade(
            outgoingAudio: outgoingAudio,
            incomingAudio: incomingAudio,
            sampleRate: sampleRate,
            channels: channels,
            config: config
        )
        
        // Then
        XCTAssertEqual(crossfaded.count, outgoingAudio.count, "Output should have same length as input")
        XCTAssertNotEqual(crossfaded, outgoingAudio, "Crossfaded audio should differ from outgoing")
        XCTAssertNotEqual(crossfaded, incomingAudio, "Crossfaded audio should differ from incoming")
    }
    
    /// BDD: Given audio data, when I apply fade out, then audio should decrease to zero
    func testApplyFadeOut() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let duration: TimeInterval = 0.1
        let audioData: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6, 0.5, -0.5]
        
        // When
        let faded = try await crossfade.applyFadeOut(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            duration: duration,
            curve: .linear
        )
        
        // Then - Last samples should be near zero
        let lastSamples = Array(faded.suffix(channels))
        for sample in lastSamples {
            XCTAssertLessThan(abs(sample), 0.1, "Last samples should be near zero after fade out")
        }
    }
    
    /// BDD: Given audio data, when I apply fade in, then audio should increase from zero
    func testApplyFadeIn() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let duration: TimeInterval = 0.1
        let audioData: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6, 0.5, -0.5]
        
        // When
        let faded = try await crossfade.applyFadeIn(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            duration: duration,
            curve: .linear
        )
        
        // Then - First samples should be near zero
        let firstSamples = Array(faded.prefix(channels))
        for sample in firstSamples {
            XCTAssertLessThan(abs(sample), 0.1, "First samples should be near zero after fade in")
        }
    }
    
    /// BDD: Given crossfade duration and sample rate, when I calculate samples, then I should get correct count
    func testCalculateCrossfadeSamples() {
        // Given
        let duration: TimeInterval = 0.1 // 100ms
        let sampleRate = 44100
        let channels = 2
        
        // When
        let samples = crossfade.calculateCrossfadeSamples(
            duration: duration,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - 0.1 seconds * 44100 Hz = 4410 samples per channel
        let expectedSamples = Int(duration * Double(sampleRate))
        XCTAssertEqual(samples, expectedSamples, "Should calculate correct number of samples")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given empty audio buffers, when I apply crossfade, then it should throw error
    func testApplyCrossfadeWithEmptyBuffersThrowsError() async {
        // Given
        let emptyAudio: [Float] = []
        
        // When & Then
        do {
            _ = try await crossfade.applyCrossfade(
                outgoingAudio: emptyAudio,
                incomingAudio: emptyAudio,
                sampleRate: 44100,
                channels: 2,
                config: CrossfadeConfig(duration: 0.1)
            )
            XCTFail("Should throw error for empty buffers")
        } catch let error as CrossfadeError {
            XCTAssertEqual(error, .invalidAudioData, "Should throw invalidAudioData error")
        } catch {
            XCTFail("Should throw CrossfadeError, got: \(error)")
        }
    }
    
    /// BDD: Given mismatched buffer lengths, when I apply crossfade, then it should throw error
    func testApplyCrossfadeWithMismatchedBuffersThrowsError() async {
        // Given
        let outgoingAudio: [Float] = [0.5, -0.5, 0.4, -0.4]
        let incomingAudio: [Float] = [0.3, -0.3] // Different length
        
        // When & Then
        do {
            _ = try await crossfade.applyCrossfade(
                outgoingAudio: outgoingAudio,
                incomingAudio: incomingAudio,
                sampleRate: 44100,
                channels: 2,
                config: CrossfadeConfig(duration: 0.1)
            )
            XCTFail("Should throw error for mismatched buffers")
        } catch let error as CrossfadeError {
            XCTAssertEqual(error, .bufferMismatch, "Should throw bufferMismatch error")
        } catch {
            XCTFail("Should throw CrossfadeError, got: \(error)")
        }
    }
    
    /// BDD: Given zero duration, when I apply crossfade, then it should throw error
    func testApplyCrossfadeWithZeroDurationThrowsError() async {
        // Given
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4]
        let config = CrossfadeConfig(duration: 0.0)
        
        // When & Then
        do {
            _ = try await crossfade.applyCrossfade(
                outgoingAudio: audioData,
                incomingAudio: audioData,
                sampleRate: 44100,
                channels: 2,
                config: config
            )
            XCTFail("Should throw error for zero duration")
        } catch let error as CrossfadeError {
            XCTAssertEqual(error, .invalidDuration, "Should throw invalidDuration error")
        } catch {
            XCTFail("Should throw CrossfadeError, got: \(error)")
        }
    }
    
    // MARK: - [I]nverse Relationships
    
    /// BDD: Given audio, when I apply fade out then reverse and fade in, then fade operations should work correctly
    func testFadeOutFadeInSymmetry() async throws {
        // Given - Use longer buffer so first samples are not in fade region
        let sampleRate = 44100
        let channels = 2
        let duration: TimeInterval = 0.01 // Shorter fade duration
        let audioData: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6, 0.5, -0.5, 0.4, -0.4, 0.3, -0.3]
        
        // When - Fade out (reduces end to zero)
        let fadedOut = try await crossfade.applyFadeOut(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            duration: duration,
            curve: .linear
        )
        
        // Then - Verify fade out worked (last samples near zero)
        let lastSamples = Array(fadedOut.suffix(channels))
        for sample in lastSamples {
            XCTAssertLessThan(abs(sample), 0.1, "Fade out should reduce last samples to near zero")
        }
        
        // When - Reverse and fade in
        let reversed = Array(fadedOut.reversed())
        let fadedIn = try await crossfade.applyFadeIn(
            audioData: reversed,
            sampleRate: sampleRate,
            channels: channels,
            duration: duration,
            curve: .linear
        )
        
        // Then - Verify fade in worked (first samples near zero)
        let firstSamplesIn = Array(fadedIn.prefix(channels))
        for sample in firstSamplesIn {
            XCTAssertLessThan(abs(sample), 0.1, "Fade in should start from near zero")
        }
        
        // Verify that fade operations are working as expected
        XCTAssertEqual(fadedOut.count, audioData.count, "Fade out should preserve length")
        XCTAssertEqual(fadedIn.count, reversed.count, "Fade in should preserve length")
    }
    
    // MARK: - [C]ross-Checking Using Other Means
    
    /// BDD: Given same audio for both buffers, when I apply crossfade, then output should match input
    func testCrossfadeWithSameAudio() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let config = CrossfadeConfig(duration: 0.1, curve: .linear)
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4, 0.3, -0.3]
        
        // When
        let crossfaded = try await crossfade.applyCrossfade(
            outgoingAudio: audioData,
            incomingAudio: audioData,
            sampleRate: sampleRate,
            channels: channels,
            config: config
        )
        
        // Then - Should match input (outgoing + incoming = 2x, then normalized)
        // For linear crossfade with same audio: result ≈ input
        for (index, value) in audioData.enumerated() {
            XCTAssertEqual(crossfaded[index], value, accuracy: 0.01, "Crossfade with same audio should match input")
        }
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given invalid sample rate, when I apply crossfade, then it should throw error
    func testApplyCrossfadeWithInvalidSampleRateThrowsError() async {
        // Given
        let audioData: [Float] = [0.5, -0.5]
        
        // When & Then
        do {
            _ = try await crossfade.applyCrossfade(
                outgoingAudio: audioData,
                incomingAudio: audioData,
                sampleRate: 0,
                channels: 2,
                config: CrossfadeConfig(duration: 0.1)
            )
            XCTFail("Should throw error for invalid sample rate")
        } catch let error as CrossfadeError {
            XCTAssertEqual(error, .invalidSampleRate, "Should throw invalidSampleRate error")
        } catch {
            XCTFail("Should throw CrossfadeError, got: \(error)")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given audio buffers, when I apply crossfade, then it should complete quickly
    func testApplyCrossfadePerformance() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let durationSeconds: Float = 1.0
        let sampleCount = Int(Float(sampleRate) * durationSeconds * Float(channels))
        let outgoingAudio = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        let incomingAudio = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        let config = CrossfadeConfig(duration: 0.1)
        
        // When & Then
        measure {
            Task {
                _ = try? await crossfade.applyCrossfade(
                    outgoingAudio: outgoingAudio,
                    incomingAudio: incomingAudio,
                    sampleRate: sampleRate,
                    channels: channels,
                    config: config
                )
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// BDD: Given very short crossfade duration, when I apply crossfade, then it should handle correctly
    func testApplyCrossfadeWithVeryShortDuration() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let config = CrossfadeConfig(duration: 0.001) // 1ms
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4]
        
        // When
        let crossfaded = try await crossfade.applyCrossfade(
            outgoingAudio: audioData,
            incomingAudio: audioData,
            sampleRate: sampleRate,
            channels: channels,
            config: config
        )
        
        // Then - Should still produce valid output
        XCTAssertEqual(crossfaded.count, audioData.count, "Should produce output of same length")
    }
    
    /// BDD: Given different fade curves, when I apply crossfade, then all should work
    func testApplyCrossfadeWithDifferentCurves() async throws {
        // Given
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4, 0.3, -0.3]
        let curves: [CrossfadeCurve] = [.linear, .exponential, .logarithmic, .cosine]
        
        // When & Then - All curves should work
        for curve in curves {
            let config = CrossfadeConfig(duration: 0.1, curve: curve)
            let crossfaded = try await crossfade.applyCrossfade(
                outgoingAudio: audioData,
                incomingAudio: audioData,
                sampleRate: sampleRate,
                channels: channels,
                config: config
            )
            XCTAssertEqual(crossfaded.count, audioData.count, "Curve \(curve) should produce valid output")
        }
    }
}
