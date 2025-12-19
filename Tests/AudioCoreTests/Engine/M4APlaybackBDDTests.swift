//
//  M4APlaybackBDDTests.swift
//  AudioCoreTests
//
//  BDD tests for M4A format playback support
//  User scenarios for playing M4A tracks
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD tests for M4A playback support
/// User scenarios: "As a user, when I..., then I should..."
@MainActor
final class M4APlaybackBDDTests: XCTestCase {
    
    // MARK: - User Scenarios
    
    /// BDD: As a user, when I load an M4A track, then it should be detected and ready to play
    func testUserLoadsM4ATrackGetsDetectedFormat() async throws {
        // Given - An M4A track file
        let m4aTrack = MockFactory.makeTrack(
            title: "Beautiful M4A Song",
            artist: "M4A Artist",
            album: "M4A Album",
            filePath: "/music/album/track.m4a"
        )
        let expectedFormat = DecodedAudioFormat(
            codec: "AAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 256,
            duration: 240.0
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.result = expectedFormat
        mockCoordinator.shouldFail = false
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.nextLoadDuration = expectedFormat.duration
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            formatCoordinator: mockCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        // When - User loads the M4A track
        try await engine.loadTrack(m4aTrack)
        
        // Then - Track should be loaded with format detected
        XCTAssertEqual(engine.currentTrack?.title, "Beautiful M4A Song", "User should see the track title")
        XCTAssertEqual(engine.detectedFormat?.codec, "AAC", "User should see the codec is AAC")
        XCTAssertEqual(engine.detectedFormat?.sampleRate, 44_100, "User should see the sample rate")
        XCTAssertEqual(engine.duration, 240.0, accuracy: 0.01, "User should see the correct duration")
    }
    
    /// BDD: As a user, when I play an M4A track, then it should start playing
    func testUserPlaysM4ATrackStartsPlayback() async throws {
        // Given - A loaded M4A track
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Playback Test",
            filePath: "/music/track.m4a"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        try await engine.loadTrack(m4aTrack)
        
        // When - User plays the M4A track
        try await engine.play()
        
        // Then - Track should be playing
        XCTAssertEqual(engine.state, .playing, "User should see the track is playing")
        XCTAssertEqual(mockNativeEngine.playCallCount, 1, "Native engine should be playing")
    }
    
    /// BDD: As a user, when I pause an M4A track, then playback should pause
    func testUserPausesM4ATrackPausesPlayback() async throws {
        // Given - A playing M4A track
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Pause Test",
            filePath: "/music/track.m4a"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        try await engine.loadTrack(m4aTrack)
        try await engine.play()
        
        // When - User pauses the M4A track
        await engine.pause()
        
        // Then - Track should be paused
        XCTAssertEqual(engine.state, .paused, "User should see the track is paused")
        XCTAssertEqual(mockNativeEngine.pauseCallCount, 1, "Native engine should be paused")
    }
    
    /// BDD: As a user, when I seek in an M4A track, then the position should change
    func testUserSeeksM4ATrackChangesPosition() async throws {
        // Given - A playing M4A track
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Seek Test",
            filePath: "/music/track.m4a"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.seekResult = true
        mockNativeEngine.nextLoadDuration = 240.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        try await engine.loadTrack(m4aTrack)
        try await engine.play()
        
        // When - User seeks to 60 seconds
        try await engine.seek(to: 60.0)
        
        // Then - Position should be updated
        XCTAssertEqual(mockNativeEngine.seekCalls.count, 1, "Native engine should seek")
        XCTAssertEqual(mockNativeEngine.seekCalls.first ?? 0, 60.0, accuracy: 0.01, "User should see position at 60 seconds")
    }
    
    /// BDD: As a user, when I have a library with M4A files, then they should be recognized and playable
    func testUserHasLibraryWithM4AFilesAllPlayable() async throws {
        // Given - A library with mixed formats including M4A
        let tracks = [
            MockFactory.makeTrack(title: "MP3 Track", filePath: "/music/track1.mp3"),
            MockFactory.makeTrack(title: "M4A Track", filePath: "/music/track2.m4a"),
            MockFactory.makeTrack(title: "FLAC Track", filePath: "/music/track3.flac"),
            MockFactory.makeTrack(title: "Another M4A", filePath: "/music/track4.m4a")
        ]
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: tracks,
            nativeEngine: mockNativeEngine
        )
        
        // When - User loads and plays each M4A track
        for track in tracks where track.filePath.hasSuffix(".m4a") {
            try await engine.loadTrack(track)
            try await engine.play()
            
            // Then - Each M4A track should play successfully
            XCTAssertEqual(engine.currentTrack?.filePath, track.filePath, "Should load M4A track: \(track.title)")
            XCTAssertEqual(engine.state, .playing, "Should be playing M4A track: \(track.title)")
            
            await engine.stop()
        }
        
        // Verify we tested both M4A tracks
        let m4aTracks = tracks.filter { $0.filePath.hasSuffix(".m4a") }
        XCTAssertEqual(m4aTracks.count, 2, "Should have 2 M4A tracks in library")
    }
    
    /// BDD: As a user, when I try to play a corrupted M4A file, then I should get an error message
    func testUserTriesToPlayCorruptedM4AFileGetsError() async throws {
        // Given - A corrupted M4A file (both format detection and native engine fail)
        let corruptedM4ATrack = MockFactory.makeTrack(
            title: "Corrupted M4A",
            filePath: "/music/corrupted.m4a"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.error = FormatDecoderError.decoderFailed(decoder: "AVFoundation", reason: "Invalid file format")
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = false // Native engine also fails
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [corruptedM4ATrack],
            formatCoordinator: mockCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        // When - User tries to load corrupted M4A file
        // Note: AudioEngine doesn't throw when both format detection and native load fail,
        // it records the error in lastFormatDetectionError and loads the track with state .stopped
        try await engine.loadTrack(corruptedM4ATrack)
        
        // Then - Format detection error should be recorded (user can see this via UI)
        XCTAssertNotNil(engine.lastFormatDetectionError, "User should see format detection error for corrupted file")
        if let error = engine.lastFormatDetectionError {
            XCTAssertTrue(
                error.localizedDescription.contains("failed") ||
                error.localizedDescription.contains("Invalid"),
                "User should see error message about file corruption: \(error.localizedDescription)"
            )
        }
        
        // Track should still be loaded (state will be .stopped, not .error, due to code flow)
        XCTAssertEqual(engine.currentTrack?.filePath, corruptedM4ATrack.filePath, "Track should be set even with format detection error")
        XCTAssertEqual(engine.state, .stopped, "State should be stopped after load completes")
    }
    
    /// BDD: As a user, when I have M4A files with different sample rates, then they should all play correctly
    func testUserHasM4AFilesWithDifferentSampleRatesAllPlay() async throws {
        // Given - M4A files with different sample rates
        let testCases = [
            (sampleRate: 44_100, track: MockFactory.makeTrack(title: "44.1kHz M4A", filePath: "/music/track_44k.m4a")),
            (sampleRate: 48_000, track: MockFactory.makeTrack(title: "48kHz M4A", filePath: "/music/track_48k.m4a")),
            (sampleRate: 96_000, track: MockFactory.makeTrack(title: "96kHz M4A", filePath: "/music/track_96k.m4a"))
        ]
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: testCases.map { $0.track },
            nativeEngine: mockNativeEngine
        )
        
        // When - User loads and plays each M4A file
        for (sampleRate, track) in testCases {
            let expectedFormat = DecodedAudioFormat(
                codec: "AAC",
                sampleRate: sampleRate,
                channelCount: 2,
                bitRate: 256,
                duration: 180.0
            )
            
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.result = expectedFormat
            mockCoordinator.shouldFail = false
            
            // Create engine with format coordinator for this track
            let trackEngine = AudioEngineTestHelpers.createMockEngine(
                withTracks: [track],
                formatCoordinator: mockCoordinator,
                nativeEngine: mockNativeEngine
            )
            
            try await trackEngine.loadTrack(track)
            
            // Then - Each M4A file should load with correct sample rate
            XCTAssertEqual(trackEngine.detectedFormat?.sampleRate, sampleRate, "User should see correct sample rate for \(track.title)")
            XCTAssertEqual(trackEngine.currentTrack?.title, track.title, "User should see track loaded: \(track.title)")
        }
    }
    
    /// BDD: As a user, when I switch between M4A and other formats, then playback should work seamlessly
    func testUserSwitchesBetweenM4AAndOtherFormatsSeamlessly() async throws {
        // Given - Tracks in different formats
        let mp3Track = MockFactory.makeTrack(title: "MP3 Track", filePath: "/music/track1.mp3")
        let m4aTrack = MockFactory.makeTrack(title: "M4A Track", filePath: "/music/track2.m4a")
        let flacTrack = MockFactory.makeTrack(title: "FLAC Track", filePath: "/music/track3.flac")
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [mp3Track, m4aTrack, flacTrack],
            nativeEngine: mockNativeEngine
        )
        
        // When - User plays MP3, then switches to M4A, then to FLAC
        try await engine.loadTrack(mp3Track)
        try await engine.play()
        XCTAssertEqual(engine.currentTrack?.filePath, mp3Track.filePath, "User should see MP3 playing")
        
        try await engine.loadTrack(m4aTrack)
        try await engine.play()
        XCTAssertEqual(engine.currentTrack?.filePath, m4aTrack.filePath, "User should see M4A playing")
        
        try await engine.loadTrack(flacTrack)
        try await engine.play()
        XCTAssertEqual(engine.currentTrack?.filePath, flacTrack.filePath, "User should see FLAC playing")
        
        // Then - All format switches should work seamlessly
        XCTAssertEqual(mockNativeEngine.loadFileCalls.count, 3, "User should be able to switch between formats")
        XCTAssertEqual(mockNativeEngine.playCallCount, 3, "User should be able to play all formats")
    }
}
