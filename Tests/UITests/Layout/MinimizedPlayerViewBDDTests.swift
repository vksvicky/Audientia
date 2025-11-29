//
//  MinimizedPlayerViewBDDTests.swift
//  UITests
//
//  BDD tests for MinimizedPlayerView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI
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
final class MinimizedPlayerViewBDDTests: XCTestCase {
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
    
    // MARK: - BDD Scenario 1: View Minimized Player
    
    /// BDD: As a user, when I minimize the player, then I should see a compact floating player window
    func testUserViewsMinimizedPlayer() {
        // Given - A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Bohemian Rhapsody",
            artist: "Queen"
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I view the minimized player
        let view = MinimizedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        
        // Then - I should see the track information
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.artist, "Queen")
        XCTAssertTrue(nowPlayingViewModel.isPlaying)
    }
    
    // MARK: - BDD Scenario 2: Restore from Minimized Player
    
    /// BDD: As a user, when I click the restore button in the minimized player, then the main window should be restored
    func testUserRestoresFromMinimizedPlayer() {
        // Given - I am viewing the minimized player
        let view = MinimizedPlayerView(
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
    
    // MARK: - BDD Scenario 3: Control Playback from Minimized Player
    
    /// BDD: As a user, when I control playback from the minimized player, then playback should respond correctly
    func testUserControlsPlaybackFromMinimizedPlayer() async throws {
        // Given - A track is loaded and I am viewing the minimized player
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .paused
        nowPlayingViewModel.updateState()
        
        let view = MinimizedPlayerView(
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
    
    // MARK: - BDD Scenario 4: Navigate Tracks from Minimized Player
    
    /// BDD: As a user, when I navigate tracks from the minimized player, then the next/previous track should play
    func testUserNavigatesTracksFromMinimizedPlayer() async throws {
        // Given - Multiple tracks in queue and I am viewing the minimized player
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        let track3 = MockFactory.makeTrack(title: "Track 3")
        
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track1, track2, track3]
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        let view = MinimizedPlayerView(
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
    
    /// BDD: As a user, when I view the minimized player with no track playing, then I should see an appropriate state
    func testUserViewsMinimizedPlayerWithoutTrack() {
        // Given - No track is playing
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        // When - I view the minimized player
        let view = MinimizedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCallbackInvoked = true }
        )
        
        // Then - I should see the player in a stopped state
        _ = view.body
        XCTAssertNil(nowPlayingViewModel.currentTrack)
        XCTAssertTrue(nowPlayingViewModel.isStopped)
    }
}
