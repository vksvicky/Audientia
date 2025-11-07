//
//  PlaybackAdvancedEdgeCaseTests.swift
//  AudioCoreTests
//
//  Advanced edge case tests for audio playback: High sample rates, channel configs, bit depth, zero duration, seeking, format transitions
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// Advanced edge case tests for audio playback scenarios
/// Tests: High sample rates, channel configurations, bit depth, zero duration, seeking, format transitions
@MainActor
final class PlaybackAdvancedEdgeCaseTests: XCTestCase {
    
    // MARK: - High Sample Rate Edge Cases
    
    /// Edge Case: Given a track with very high sample rate (192kHz), when playing it, then engine should handle it correctly
    func testVeryHighSampleRatePlayback() async throws {
        // Given - Track with very high sample rate
        let track = MockFactory.makeTrack(
            title: "192kHz Track",
            duration: 180.0,
            filePath: "/tmp/track-192khz.flac"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 192_000, // Very high sample rate
            channelCount: 2,
            bitRate: 5000,
            duration: 180.0
        )
        mockCoordinator.result = format
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator
        )
        
        // When - Load and play track with very high sample rate
        try await engine.loadTrack(track)
        try await engine.play()
        
        // Then - Engine should handle very high sample rate
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 192_000,
                       "Engine should detect 192kHz sample rate")
        XCTAssertEqual(engine.state, .playing, "Engine should play track with very high sample rate")
    }
    
    /// Edge Case: Given a track with 384kHz sample rate, when playing it, then engine should handle it correctly
    func testExtremeHighSampleRatePlayback() async throws {
        // Given - Track with extreme high sample rate
        let track = MockFactory.makeTrack(
            title: "384kHz Track",
            duration: 180.0,
            filePath: "/tmp/track-384khz.flac"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 384_000, // Extreme high sample rate
            channelCount: 2,
            bitRate: 10000,
            duration: 180.0
        )
        mockCoordinator.result = format
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator
        )
        
        // When - Load and play track with extreme high sample rate
        try await engine.loadTrack(track)
        try await engine.play()
        
        // Then - Engine should handle extreme high sample rate
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 384_000,
                       "Engine should detect 384kHz sample rate")
    }
    
    // MARK: - Channel Configuration Edge Cases
    
    /// Edge Case: Given tracks with different channel configurations, when playing them sequentially, then engine should handle transitions
    func testChannelConfigurationChange() async throws {
        // Given - Two tracks with different channel configurations
        let track1 = MockFactory.makeTrack(
            title: "Mono Track",
            duration: 180.0,
            filePath: "/tmp/track-mono.wav"
        )
        let track2 = MockFactory.makeTrack(
            title: "Stereo Track",
            duration: 180.0,
            filePath: "/tmp/track-stereo.wav"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format1 = DecodedAudioFormat(
            codec: "WAV",
            sampleRate: 44_100,
            channelCount: 1, // Mono
            bitRate: 705,
            duration: 180.0
        )
        let format2 = DecodedAudioFormat(
            codec: "WAV",
            sampleRate: 44_100,
            channelCount: 2, // Stereo
            bitRate: 1411,
            duration: 180.0
        )
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track1, track2],
            formatCoordinator: mockCoordinator
        )
        engine.addToQueue(track1)
        engine.addToQueue(track2)
        
        // When - Load and play mono track
        mockCoordinator.result = format1
        try await engine.loadTrack(track1)
        try await engine.play()
        XCTAssertEqual(engine.detectedFormat?.channelCount, 1,
                       "First track should be mono")
        
        // Then switch to stereo track
        mockCoordinator.result = format2
        try await engine.loadTrack(track2)
        XCTAssertEqual(engine.detectedFormat?.channelCount, 2,
                       "Second track should be stereo")
    }
    
    /// Edge Case: Given a track with multichannel configuration (5.1), when playing it, then engine should handle it correctly
    func testMultichannelPlayback() async throws {
        // Given - Track with multichannel configuration
        let track = MockFactory.makeTrack(
            title: "5.1 Track",
            duration: 180.0,
            filePath: "/tmp/track-51.flac"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let format = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 48_000,
            channelCount: 6, // 5.1 surround
            bitRate: 3000,
            duration: 180.0
        )
        mockCoordinator.result = format
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator
        )
        
        // When - Load and play multichannel track
        try await engine.loadTrack(track)
        try await engine.play()
        
        // Then - Engine should handle multichannel configuration
        XCTAssertEqual(engine.detectedFormat?.channelCount, 6,
                       "Engine should detect 6-channel configuration")
        XCTAssertEqual(engine.state, .playing, "Engine should play multichannel track")
    }
    
    // MARK: - Bit Depth Edge Cases
    
    /// Edge Case: Given tracks with different bit depths, when playing them sequentially, then engine should handle transitions
    func testBitDepthChange() async throws {
        // Given - Two tracks with different bit depths
        let track1 = MockFactory.makeTrack(
            title: "16-bit Track",
            duration: 180.0,
            filePath: "/tmp/track-16bit.flac"
        )
        let track2 = MockFactory.makeTrack(
            title: "24-bit Track",
            duration: 180.0,
            filePath: "/tmp/track-24bit.flac"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        // Note: Bit depth is not directly in DecodedAudioFormat, but affects bitRate
        let format1 = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 1411, // 16-bit: 44.1kHz * 16-bit * 2 channels / 1000
            duration: 180.0
        )
        let format2 = DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 2116, // 24-bit: 44.1kHz * 24-bit * 2 channels / 1000
            duration: 180.0
        )
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track1, track2],
            formatCoordinator: mockCoordinator
        )
        engine.addToQueue(track1)
        engine.addToQueue(track2)
        
        // When - Load and play 16-bit track
        mockCoordinator.result = format1
        try await engine.loadTrack(track1)
        try await engine.play()
        XCTAssertEqual(engine.detectedFormat?.bitRate, 1411,
                       "First track should have 16-bit bitrate")
        
        // Then switch to 24-bit track
        mockCoordinator.result = format2
        try await engine.loadTrack(track2)
        XCTAssertEqual(engine.detectedFormat?.bitRate, 2116,
                       "Second track should have 24-bit bitrate")
    }
    
    // MARK: - Zero/Empty Duration Edge Cases
    
    /// Edge Case: Given a track with zero duration, when loading it, then engine should handle it gracefully
    func testZeroDurationTrack() async throws {
        // Given - Track with zero duration
        let track = MockFactory.makeTrack(
            title: "Zero Duration Track",
            duration: 0.0,
            filePath: "/tmp/track-zero.mp3"
        )
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - Try to play zero duration track
        // Then - Engine should handle it (may not be playable, but shouldn't crash)
        XCTAssertEqual(engine.duration, 0.0, accuracy: 0.01,
                       "Duration should be 0")
        XCTAssertEqual(engine.progress, 0.0, accuracy: 0.01,
                       "Progress should be 0 for zero duration track")
    }
    
    /// Edge Case: Given a track with very small duration (< 0.1s), when playing it, then engine should handle it correctly
    func testVerySmallDurationTrack() async throws {
        // Given - Track with very small duration
        let track = MockFactory.makeTrack(
            title: "Tiny Track",
            duration: 0.05, // 50ms
            filePath: "/tmp/track-tiny.mp3"
        )
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - Play very small track
        try await engine.play()
        
        // Then - Engine should handle very small duration
        XCTAssertLessThan(engine.duration, 0.1, "Duration should be very small")
        XCTAssertEqual(engine.state, .playing, "Engine should play very small track")
    }
    
    // MARK: - Seeking During Playback Edge Cases
    
    /// Edge Case: Given a playing track, when I seek multiple times rapidly, then all seeks should be handled correctly
    func testRapidSeekingDuringPlayback() async throws {
        // Given - A playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Seek rapidly to multiple positions
        let seekPositions: [TimeInterval] = [10.0, 30.0, 60.0, 90.0, 120.0]
        for position in seekPositions {
            try await engine.seek(to: position)
            XCTAssertEqual(engine.currentPosition, position, accuracy: 0.1,
                           "Seek to \(position)s should work")
        }
        
        // Then - Final position should be correct
        XCTAssertEqual(engine.currentPosition, 120.0, accuracy: 0.1,
                       "Final position after rapid seeks should be 120s")
        XCTAssertEqual(engine.state, .playing, "Playback should continue after rapid seeks")
    }
    
    /// Edge Case: Given a playing track, when I seek to the exact end, then it should handle correctly
    func testSeekToExactEndDuringPlayback() async throws {
        // Given - A playing track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Seek to exact end of track
        try await engine.seek(to: 180.0)
        
        // Then - Position should be at end, progress should be 100%
        XCTAssertEqual(engine.currentPosition, 180.0, accuracy: 0.1,
                       "Position should be at end")
        XCTAssertEqual(engine.progress, 1.0, accuracy: 0.01,
                       "Progress should be 100% at end")
    }
    
    // MARK: - Format Transition Edge Cases
    
    /// Edge Case: Given tracks with multiple format changes in sequence, when playing them, then engine should handle all transitions
    func testMultipleFormatChangesInSequence() async throws {
        // Given - Three tracks with different formats
        let tracks = [
            MockFactory.makeTrack(title: "MP3", duration: 60.0, filePath: "/tmp/track1.mp3"),
            MockFactory.makeTrack(title: "FLAC", duration: 60.0, filePath: "/tmp/track2.flac"),
            MockFactory.makeTrack(title: "WAV", duration: 60.0, filePath: "/tmp/track3.wav")
        ]
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        let formats = [
            DecodedAudioFormat(codec: "MP3", sampleRate: 44_100, channelCount: 2, bitRate: 320, duration: 60.0),
            DecodedAudioFormat(codec: "FLAC", sampleRate: 44_100, channelCount: 2, bitRate: 1000, duration: 60.0),
            DecodedAudioFormat(codec: "WAV", sampleRate: 44_100, channelCount: 2, bitRate: 1411, duration: 60.0)
        ]
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: tracks,
            formatCoordinator: mockCoordinator
        )
        for track in tracks {
            engine.addToQueue(track)
        }
        
        // When - Play through all tracks
        for (index, track) in tracks.enumerated() {
            mockCoordinator.result = formats[index]
            try await engine.loadTrack(track)
            try await engine.play()
            
            // Then - Each format should be detected correctly
            XCTAssertEqual(engine.detectedFormat?.codec, formats[index].codec,
                           "Track \(index + 1) should have correct codec")
        }
    }
}
