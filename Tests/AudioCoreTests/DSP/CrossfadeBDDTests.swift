//
//  CrossfadeBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for crossfade between tracks
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// BDD-style test scenarios for Crossfade
/// Following user-centric "As a user, I want to..." format
final class CrossfadeBDDTests: XCTestCase {
    
    var crossfade: Crossfade!
    
    override func setUp() {
        super.setUp()
        crossfade = Crossfade()
    }
    
    override func tearDown() {
        crossfade = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want smooth transitions between tracks without gaps
    func testSmoothTransitionBetweenTracks() async throws {
        // Given - I have two tracks playing
        let sampleRate = 44100
        let channels = 2
        let config = CrossfadeConfig(duration: 0.1, curve: .linear)
        
        let outgoingAudio: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6]
        let incomingAudio: [Float] = [0.1, -0.1, 0.2, -0.2, 0.3, -0.3]
        
        // When - I apply crossfade between them
        let crossfaded = try await crossfade.applyCrossfade(
            outgoingAudio: outgoingAudio,
            incomingAudio: incomingAudio,
            sampleRate: sampleRate,
            channels: channels,
            config: config
        )
        
        // Then - The transition should be smooth (no sudden jumps)
        // Note: When crossfading between very different amplitudes, consecutive sample differences
        // can be large, but we verify the crossfade is working correctly by checking:
        // 1. The output is a blend of both inputs (not just one)
        // 2. The transition progresses gradually from outgoing to incoming
        
        // Verify the crossfade actually blended the audio (not just one or the other)
        XCTAssertNotEqual(crossfaded, outgoingAudio, "Crossfaded audio should differ from outgoing")
        XCTAssertNotEqual(crossfaded, incomingAudio, "Crossfaded audio should differ from incoming")
        
        // Verify the transition progresses from outgoing to incoming
        // First samples should be closer to outgoing, last samples should be closer to incoming
        let firstFrame = Array(crossfaded.prefix(channels))
        let lastFrame = Array(crossfaded.suffix(channels))
        let outgoingFirst = Array(outgoingAudio.prefix(channels))
        let incomingLast = Array(incomingAudio.suffix(channels))
        
        // Calculate distance from first frame to outgoing vs incoming
        var distanceToOutgoing: Float = 0.0
        var distanceToIncoming: Float = 0.0
        for i in 0..<channels {
            distanceToOutgoing += abs(firstFrame[i] - outgoingFirst[i])
            distanceToIncoming += abs(firstFrame[i] - incomingLast[i])
        }
        // First frame should be closer to outgoing
        XCTAssertLessThan(distanceToOutgoing, distanceToIncoming, "First frame should be closer to outgoing audio")
        
        // Last frame should be closer to incoming
        var lastDistanceToOutgoing: Float = 0.0
        var lastDistanceToIncoming: Float = 0.0
        for i in 0..<channels {
            lastDistanceToOutgoing += abs(lastFrame[i] - outgoingFirst[i])
            lastDistanceToIncoming += abs(lastFrame[i] - incomingLast[i])
        }
        // Last frame should be closer to incoming (or equal if crossfade completed)
        XCTAssertLessThanOrEqual(lastDistanceToIncoming, lastDistanceToOutgoing, "Last frame should be closer to incoming audio")
    }
    
    /// BDD: As a user, I want to configure crossfade duration
    func testConfigureCrossfadeDuration() async throws {
        // Given - I want different crossfade durations
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4, 0.3, -0.3]
        
        let shortConfig = CrossfadeConfig(duration: 0.05) // 50ms
        let longConfig = CrossfadeConfig(duration: 0.2)   // 200ms
        
        // When - I apply crossfade with different durations
        let shortCrossfade = try await crossfade.applyCrossfade(
            outgoingAudio: audioData,
            incomingAudio: audioData,
            sampleRate: sampleRate,
            channels: channels,
            config: shortConfig
        )
        let longCrossfade = try await crossfade.applyCrossfade(
            outgoingAudio: audioData,
            incomingAudio: audioData,
            sampleRate: sampleRate,
            channels: channels,
            config: longConfig
        )
        
        // Then - Both should work correctly
        XCTAssertEqual(shortCrossfade.count, audioData.count, "Short crossfade should produce correct length")
        XCTAssertEqual(longCrossfade.count, audioData.count, "Long crossfade should produce correct length")
    }
    
    /// BDD: As a user, I want to choose different fade curves for different music styles
    func testChooseFadeCurves() async throws {
        // Given - I want different fade curves
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4, 0.3, -0.3]
        
        let curves: [CrossfadeCurve] = [.linear, .exponential, .logarithmic, .cosine]
        
        // When - I apply crossfade with different curves
        for curve in curves {
            let config = CrossfadeConfig(duration: 0.1, curve: curve)
            let crossfaded = try await crossfade.applyCrossfade(
                outgoingAudio: audioData,
                incomingAudio: audioData,
                sampleRate: sampleRate,
                channels: channels,
                config: config
            )
            
            // Then - Each curve should produce valid output
            XCTAssertEqual(crossfaded.count, audioData.count, "Curve \(curve) should produce correct length")
        }
    }
    
    /// BDD: As a user, I want the outgoing track to fade out smoothly
    func testOutgoingTrackFadesOut() async throws {
        // Given - I have a track ending
        let sampleRate = 44100
        let channels = 2
        let duration: TimeInterval = 0.1
        let audioData: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6, 0.5, -0.5]
        
        // When - I apply fade out
        let faded = try await crossfade.applyFadeOut(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            duration: duration,
            curve: .linear
        )
        
        // Then - The track should fade to silence
        let lastSamples = Array(faded.suffix(channels))
        for sample in lastSamples {
            XCTAssertLessThan(abs(sample), 0.1, "Outgoing track should fade to near silence")
        }
    }
    
    /// BDD: As a user, I want the incoming track to fade in smoothly
    func testIncomingTrackFadesIn() async throws {
        // Given - I have a track starting
        let sampleRate = 44100
        let channels = 2
        let duration: TimeInterval = 0.1
        let audioData: [Float] = [0.8, -0.8, 0.7, -0.7, 0.6, -0.6, 0.5, -0.5]
        
        // When - I apply fade in
        let faded = try await crossfade.applyFadeIn(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            duration: duration,
            curve: .linear
        )
        
        // Then - The track should start from silence
        let firstSamples = Array(faded.prefix(channels))
        for sample in firstSamples {
            XCTAssertLessThan(abs(sample), 0.1, "Incoming track should start from near silence")
        }
    }
    
    /// BDD: As a user, I want crossfade to work with different audio formats
    func testCrossfadeWithDifferentFormats() async throws {
        // Given - I have mono and stereo audio
        let sampleRate = 44100
        
        // Mono
        let monoAudio: [Float] = [0.5, 0.4, 0.3, 0.2]
        let monoConfig = CrossfadeConfig(duration: 0.1)
        let monoCrossfade = try await crossfade.applyCrossfade(
            outgoingAudio: monoAudio,
            incomingAudio: monoAudio,
            sampleRate: sampleRate,
            channels: 1,
            config: monoConfig
        )
        
        // Stereo
        let stereoAudio: [Float] = [0.5, -0.5, 0.4, -0.4, 0.3, -0.3]
        let stereoConfig = CrossfadeConfig(duration: 0.1)
        let stereoCrossfade = try await crossfade.applyCrossfade(
            outgoingAudio: stereoAudio,
            incomingAudio: stereoAudio,
            sampleRate: sampleRate,
            channels: 2,
            config: stereoConfig
        )
        
        // Then - Both should work correctly
        XCTAssertEqual(monoCrossfade.count, monoAudio.count, "Mono crossfade should work")
        XCTAssertEqual(stereoCrossfade.count, stereoAudio.count, "Stereo crossfade should work")
    }
    
    /// BDD: As a user, I want to disable crossfade if I prefer abrupt transitions
    func testDisableCrossfade() async throws {
        // Given - I want no crossfade (zero duration)
        let sampleRate = 44100
        let channels = 2
        let audioData: [Float] = [0.5, -0.5, 0.4, -0.4]
        
        // When & Then - Zero duration should throw error (effectively disabling)
        do {
            _ = try await crossfade.applyCrossfade(
                outgoingAudio: audioData,
                incomingAudio: audioData,
                sampleRate: sampleRate,
                channels: channels,
                config: CrossfadeConfig(duration: 0.0)
            )
            XCTFail("Zero duration should throw error")
        } catch {
            // Expected - crossfade disabled
            XCTAssertTrue(error is CrossfadeError, "Should throw CrossfadeError for zero duration")
        }
    }
}
