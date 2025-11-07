//
//  PlaybackEdgeCaseTests.swift
//  AudioCoreTests
//
//  Edge case tests for audio playback: VBR files, gapless playback, sample rate changes
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// Edge case tests for audio playback scenarios
/// Tests: VBR files, gapless playback, sample rate changes
@MainActor
final class PlaybackEdgeCaseTests: XCTestCase {
    
    // MARK: - VBR (Variable Bitrate) Files
    
    /// Edge Case: Given a VBR file, when I load and play it, then it should handle variable bitrate correctly
    func testVBRFilePlayback() async throws {
        // Given - A track that simulates VBR characteristics (variable bitrate)
        // Note: In real implementation, VBR files have varying bitrate throughout
        let track = MockFactory.makeTrack(
            title: "VBR Track",
            duration: 180.0,
            filePath: "/tmp/vbr-track.mp3"
        )
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - Load and play the VBR track
        try await engine.play()
        
        // Then - Engine should handle playback correctly
        // VBR files should play without issues, position tracking should work
        XCTAssertEqual(engine.state, .playing, "VBR file should play correctly")
        
        // Wait a bit and verify position tracking works
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        XCTAssertGreaterThan(
            engine.currentPosition, 0.0,
            "Position should advance even with VBR file"
        )
    }
    
    /// Edge Case: Given a VBR file, when I seek within it, then seek should work correctly
    func testVBRFileSeek() async throws {
        // Given - A VBR track
        let track = MockFactory.makeTrack(
            title: "VBR Track",
            duration: 180.0,
            filePath: "/tmp/vbr-track.mp3"
        )
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Seek to different positions in VBR file
        try await engine.seek(to: 30.0)
        XCTAssertEqual(engine.currentPosition, 30.0, accuracy: 0.1,
                       "Seek should work in VBR file")
        
        try await engine.seek(to: 90.0)
        XCTAssertEqual(engine.currentPosition, 90.0, accuracy: 0.1,
                       "Seek to different position should work in VBR file")
        
        try await engine.seek(to: 150.0)
        XCTAssertEqual(engine.currentPosition, 150.0, accuracy: 0.1,
                       "Seek to later position should work in VBR file")
    }
    
    // MARK: - Gapless Playback
    
    /// Edge Case: Given two tracks in queue, when first track ends, then next should start without gap
    func testGaplessPlaybackBetweenTracks() async throws {
        // Given - Two tracks in queue (simulating gapless album)
        let track1 = MockFactory.makeTrack(
            title: "Track 1",
            duration: 1.0, // Short for testing
            filePath: "/tmp/track1.mp3"
        )
        let track2 = MockFactory.makeTrack(
            title: "Track 2",
            duration: 1.0,
            filePath: "/tmp/track2.mp3"
        )
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue([track1, track2])
        
        // When - Play first track
        try await engine.play()
        XCTAssertEqual(engine.currentTrack?.id, track1.id, "Should be playing first track")
        
        // Wait for first track to complete
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Then - Second track should start automatically (gapless transition)
        // Note: In real implementation, there should be no audible gap
        XCTAssertEqual(
            engine.currentTrack?.id, track2.id,
            "Second track should start automatically after first completes"
        )
        XCTAssertEqual(engine.state, .playing, "Should be playing second track")
    }
    
    /// Edge Case: Given multiple tracks in queue, when playing through them, then transitions should be gapless
    func testGaplessPlaybackMultipleTracks() async throws {
        // Given - Three tracks in queue
        let tracks = (0..<3).map { index in
            MockFactory.makeTrack(
                title: "Track \(index + 1)",
                duration: 0.5, // Very short for testing
                filePath: "/tmp/track\(index + 1).mp3"
            )
        }
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue(tracks)
        
        // When - Play through all tracks
        try await engine.play()
        
        // Wait for all tracks to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then - All tracks should have played in sequence
        // Queue should be empty (all tracks played)
        XCTAssertTrue(engine.queue.isEmpty, "All tracks should have been played")
    }
    
    // MARK: - Sample Rate Changes
    
    /// Edge Case: Given tracks with different sample rates, when playing them sequentially, then engine should handle rate changes
    func testSampleRateChangeBetweenTracks() async throws {
        // Given - Two tracks with different sample rates (simulated via format detection)
        let track1 = MockFactory.makeTrack(
            title: "44.1kHz Track",
            duration: 180.0,
            filePath: "/tmp/track-44khz.flac"
        )
        let track2 = MockFactory.makeTrack(
            title: "96kHz Track",
            duration: 180.0,
            filePath: "/tmp/track-96khz.flac"
        )
        
        // Create mock format coordinator that returns different sample rates
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format1 = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 1000,
            duration: 180.0
        )
        let format2 = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 96_000,
            channelCount: 2,
            bitRate: 2000,
            duration: 180.0
        )
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track1, track2],
            formatCoordinator: mockCoordinator
        )
        engine.addToQueue(track1)
        engine.addToQueue(track2)
        
        // When - Load first track with 44.1kHz
        mockCoordinator.result = format1
        try await engine.loadTrack(track1)
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 44_100,
                       "First track should have 44.1kHz sample rate")
        
        // Play and then load second track with 96kHz
        try await engine.play()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        mockCoordinator.result = format2
        try await engine.loadTrack(track2)
        
        // Then - Engine should handle sample rate change
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 96_000,
                       "Second track should have 96kHz sample rate")
        XCTAssertEqual(engine.state, .stopped, "Engine should handle sample rate change")
    }
    
    /// Edge Case: Given a track with unusual sample rate, when playing it, then engine should handle it correctly
    func testUnusualSampleRatePlayback() async throws {
        // Given - Track with unusual sample rate (e.g., 48kHz, 88.2kHz)
        let track = MockFactory.makeTrack(
            title: "48kHz Track",
            duration: 180.0,
            filePath: "/tmp/track-48khz.wav"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format = DecodedAudioFormat(
            codec: "WAV",
            sampleRate: 48_000, // Unusual but valid sample rate
            channelCount: 2,
            bitRate: 1536,
            duration: 180.0
        )
        mockCoordinator.result = format
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator
        )
        
        // When - Load and play track with unusual sample rate
        try await engine.loadTrack(track)
        try await engine.play()
        
        // Then - Engine should handle unusual sample rate
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 48_000,
                       "Engine should detect 48kHz sample rate")
        XCTAssertEqual(engine.state, .playing, "Engine should play track with unusual sample rate")
    }
    
    /// Edge Case: Given tracks with same sample rate but different formats, when playing them, then transitions should be smooth
    func testFormatChangeSameSampleRate() async throws {
        // Given - Two tracks with same sample rate but different formats
        let track1 = MockFactory.makeTrack(
            title: "MP3 Track",
            duration: 180.0,
            filePath: "/tmp/track1.mp3"
        )
        let track2 = MockFactory.makeTrack(
            title: "FLAC Track",
            duration: 180.0,
            filePath: "/tmp/track2.flac"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format1 = DecodedAudioFormat(
            codec: "MP3",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 320,
            duration: 180.0
        )
        let format2 = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 1000,
            duration: 180.0
        )
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track1, track2],
            formatCoordinator: mockCoordinator
        )
        engine.addToQueue(track1)
        engine.addToQueue(track2)
        
        // When - Load and play first track (MP3)
        mockCoordinator.result = format1
        try await engine.loadTrack(track1)
        try await engine.play()
        
        // Then switch to second track (FLAC) with same sample rate
        mockCoordinator.result = format2
        try await engine.loadTrack(track2)
        
        // Then - Engine should handle format change smoothly
        XCTAssertEqual(engine.detectedFormat?.codec, "FLAC",
                       "Engine should detect FLAC format")
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 44_100,
                       "Sample rate should remain 44.1kHz")
    }
    
    // MARK: - Combined Edge Cases
    
    /// Edge Case: Given a VBR file with gapless transition, when playing through tracks, then it should handle both correctly
    func testVBRFileWithGaplessTransition() async throws {
        // Given - Two VBR tracks in queue (simulating gapless album with VBR encoding)
        let track1 = MockFactory.makeTrack(
            title: "VBR Track 1",
            duration: 1.0,
            filePath: "/tmp/vbr-track1.mp3"
        )
        let track2 = MockFactory.makeTrack(
            title: "VBR Track 2",
            duration: 1.0,
            filePath: "/tmp/vbr-track2.mp3"
        )
        let engine = AudioEngineTestHelpers.createMockEngineWithQueue([track1, track2])
        
        // When - Play through VBR tracks
        try await engine.play()
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Then - Second track should start automatically (gapless)
        XCTAssertEqual(
            engine.currentTrack?.id, track2.id,
            "Second VBR track should start automatically"
        )
        XCTAssertEqual(engine.state, .playing, "Should be playing second track")
    }
}
