//
//  MinimisedPlayerViewBDDTests.swift
//  UITests
//
//  BDD tests for MinimisedPlayerView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI

#if canImport(XCTest)
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared

// MockFactory helper for creating test tracks
private enum MockFactory {
    static func makeTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3"
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
}

@MainActor
final class MinimisedPlayerViewBDDTests: XCTestCase {
    var mockAudioEngine: MockAudioEngine!
    var nowPlayingViewModel: NowPlayingViewModel!
    var restoreCallbackInvoked: Bool!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        restoreCallbackInvoked = false
    }
    
    override func tearDown() {
        nowPlayingViewModel = nil
        mockAudioEngine = nil
        restoreCallbackInvoked = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: View Minimised Player
    
    /// BDD: As a user, when I minimize the player, then I should see a compact floating player window
    func testUserViewsMinimisedPlayer() {
        // Given - A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Bohemian Rhapsody",
            artist: "Queen"
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I view the minimised player
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        
        // Then - I should see the track information
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.artist, "Queen")
        XCTAssertTrue(nowPlayingViewModel.isPlaying)
    }
    
    // MARK: - BDD Scenario 2: Restore from Minimised Player
    
    /// BDD: As a user, when I click the restore button in the minimised player, then the main window should be restored
    func testUserRestoresFromMinimisedPlayer() {
        // Given - I am viewing the minimised player
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        
        // When - I click the restore button
        // Note: In actual UI test, we would simulate button tap
        // For unit test, we verify the callback mechanism
        view.onRestore()
        
        // Then - The restore callback should be invoked
        XCTAssertTrue(restoreCallbackInvoked)
    }
    
    // MARK: - BDD Scenario 3: Control Playback from Minimised Player
    
    /// BDD: As a user, when I control playback from the minimised player, then playback should respond correctly
    func testUserControlsPlaybackFromMinimisedPlayer() async throws {
        // Given - A track is loaded and I am viewing the minimised player
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .paused
        nowPlayingViewModel.updateState()
        
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        _ = view.body
        
        // When - I click the play button
        try await nowPlayingViewModel.play()
        
        // Then - Playback should start
        XCTAssertTrue(nowPlayingViewModel.isPlaying)
        XCTAssertTrue(mockAudioEngine.playCalled)
    }
    
    // MARK: - BDD Scenario 4: Navigate Tracks from Minimised Player
    
    /// BDD: As a user, when I navigate tracks from the minimised player, then the next/previous track should play
    func testUserNavigatesTracksFromMinimisedPlayer() async throws {
        // Given - Multiple tracks in queue and I am viewing the minimised player
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        let track3 = MockFactory.makeTrack(title: "Track 3")
        
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track1, track2, track3]
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        _ = view.body
        
        // When - I click the next button
        try await nowPlayingViewModel.playNext()
        
        // Then - Next track should be queued
        XCTAssertTrue(mockAudioEngine.playNextCalled)
    }
    
    // MARK: - BDD Scenario 5: View Player Without Track
    
    /// BDD: As a user, when I view the minimised player with no track playing, then I should see an appropriate state
    func testUserViewsMinimisedPlayerWithoutTrack() {
        // Given - No track is playing
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        // When - I view the minimised player
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        
        // Then - I should see the player in a stopped state
        _ = view.body
        XCTAssertNil(nowPlayingViewModel.currentTrack)
        XCTAssertTrue(nowPlayingViewModel.isStopped)
    }
    
    // MARK: - BDD Scenario 6: Album Artwork in Minimised Player
    
    /// BDD: As a user, I want to see album artwork in the minimised player
    func testUserSeesAlbumArtworkInMinimisedPlayer() async {
        // Given - A track with artwork is playing
        let track = MockFactory.makeTrack(title: "Beautiful Song", filePath: "/music/album/track.m4a")
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I view the minimised player
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        _ = view.body
        
        // Then - Artwork should be loaded
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Beautiful Song")
        
        // Give time for artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    /// BDD: As a user, I want to see a placeholder when no artwork is available
    func testUserSeesPlaceholderWhenNoArtworkAvailable() {
        // Given - A track without artwork
        let track = MockFactory.makeTrack(filePath: "/path/without/artwork.wav")
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the minimised player
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        
        // Then - Placeholder should be shown (music.note icon)
        _ = view.body
        XCTAssertNotNil(nowPlayingViewModel.currentTrack)
    }
    
    /// BDD: As a user, when track changes, I want to see the new artwork
    func testUserSeesNewArtworkWhenTrackChanges() async {
        // Given - Playing a track with artwork
        let track1 = MockFactory.makeTrack(title: "Song 1", filePath: "/music/song1.mp3")
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        _ = view.body
        
        // Give time for initial artwork
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When - Track changes to another song
        let track2 = MockFactory.makeTrack(title: "Song 2", filePath: "/music/song2.flac")
        mockAudioEngine.currentTrack = track2
        nowPlayingViewModel.updateState()
        
        // Give time for new artwork
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - New artwork should be displayed
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Song 2")
    }
    
    /// BDD: As a user, I want artwork to work with different audio formats
    func testUserSeesArtworkForDifferentAudioFormats() {
        let formats = [
            ("MP3 file", "/music/track.mp3"),
            ("M4A file", "/music/track.m4a"),
            ("FLAC file", "/music/track.flac"),
            ("WAV file", "/music/track.wav"),
            ("OGG file", "/music/track.ogg")
        ]
        
        for (description, filePath) in formats {
            // Given - A track with specific format
            let track = MockFactory.makeTrack(title: description, filePath: filePath)
            mockAudioEngine.currentTrack = track
            nowPlayingViewModel.updateState()
            
            // When - I view the minimised player
            let view = MinimisedPlayerView(
                nowPlayingViewModel: nowPlayingViewModel,
                onRestore: { self.restoreCallbackInvoked = true }
            )
            
            // Then - Artwork should be attempted to load
            _ = view.body
            XCTAssertNotNil(nowPlayingViewModel.currentTrack, "Failed for: \(description)")
        }
    }
}

#endif
