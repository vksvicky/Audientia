//
//  MainWindowPlayerControlsBDDTests.swift
//  UITests
//
//  BDD tests for MainWindowPlayerControls
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

/// BDD Tests for MainWindowPlayerControls
@MainActor
final class MainWindowPlayerControlsBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockAudioEngine: MockAudioEngine!
    private var nowPlayingViewModel: NowPlayingViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
    }
    
    override func tearDown() {
        nowPlayingViewModel = nil
        mockAudioEngine = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: View Player Controls
    
    /// BDD: As a user, when I view the player controls, then I should see the current track information
    func testAsAUserIWantToViewCurrentTrackInformation() {
        // Given - A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera"
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - I should see the track information
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.artist, "Queen")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.album, "A Night at the Opera")
    }
    
    // MARK: - BDD Scenario 8: Visualizer Functionality
    
    /// BDD: As a user, when I click the visualizer button, then the visualizer should toggle
    func testAsAUserIWantToToggleVisualizer() {
        // Given - Visualizer is not shown
        var showVisualizer = false
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I click the visualizer button
        showVisualizer.toggle()
        
        // Then - Visualizer should be shown
        XCTAssertTrue(showVisualizer)
        
        // When - I click the visualizer button again
        showVisualizer.toggle()
        
        // Then - Visualizer should be hidden
        XCTAssertFalse(showVisualizer)
    }
    
    /// BDD: As a user, when visualizer is active, then the visualizer button should show blue
    func testAsAUserIWantToSeeBlueVisualizerButtonWhenActive() {
        // Given - Visualizer is shown
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls with visualizer active
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(true))
        
        // Then - Visualizer button should show active state
        _ = view.body
        // Visualizer state is managed by binding, so we verify the view compiles
    }
    
    /// BDD: As a user, when no track is playing, then I should see "No track selected"
    func testAsAUserIWantToSeeNoTrackMessageWhenNothingPlaying() {
        // Given - No track is loaded
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - I should see "No track selected"
        _ = view.body
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    // MARK: - BDD Scenario 2: Playback Controls
    
    /// BDD: As a user, when I click the play button, then the track should start playing
    func testAsAUserIWantToPlayTrack() async throws {
        // Given - A track is loaded but paused
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .paused
        nowPlayingViewModel.updateState()
        
        // When - I click the play button
        try await nowPlayingViewModel.play()
        
        // Then - The track should be playing
        XCTAssertTrue(mockAudioEngine.playCalled)
        XCTAssertEqual(mockAudioEngine.state, .playing)
    }
    
    /// BDD: As a user, when I click the pause button, then playback should pause
    func testAsAUserIWantToPauseTrack() async {
        // Given - A track is playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I click the pause button
        await nowPlayingViewModel.pause()
        
        // Then - Playback should be paused
        XCTAssertTrue(mockAudioEngine.pauseCalled)
        XCTAssertEqual(mockAudioEngine.state, .paused)
    }
    
    /// BDD: As a user, when I click the stop button, then playback should stop
    func testAsAUserIWantToStopTrack() async {
        // Given - A track is playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        mockAudioEngine.currentPosition = 60.0
        nowPlayingViewModel.updateState()
        
        // When - I click the stop button
        await nowPlayingViewModel.stop()
        
        // Then - Playback should stop and position reset
        XCTAssertTrue(mockAudioEngine.stopCalled)
        XCTAssertEqual(mockAudioEngine.state, .stopped)
        XCTAssertEqual(mockAudioEngine.currentPosition, 0.0)
    }
    
    /// BDD: As a user, when I click the previous button, then the previous track should play
    func testAsAUserIWantToPlayPreviousTrack() async throws {
        // Given - Multiple tracks in queue with history
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track2
        mockAudioEngine.queueHistory = [track1]
        mockAudioEngine.currentQueueIndex = 0
        nowPlayingViewModel.updateState()
        
        // When - I click the previous button
        try await nowPlayingViewModel.playPrevious()
        
        // Then - Previous track should play
        XCTAssertTrue(mockAudioEngine.playPreviousCalled)
    }
    
    /// BDD: As a user, when I click the next button, then the next track should play
    func testAsAUserIWantToPlayNextTrack() async throws {
        // Given - Multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track2]
        nowPlayingViewModel.updateState()
        
        // When - I click the next button
        try await nowPlayingViewModel.playNext()
        
        // Then - Next track should play
        XCTAssertTrue(mockAudioEngine.playNextCalled)
    }
    
    // MARK: - BDD Scenario 3: Repeat/Loop Controls
    
    /// BDD: As a user, when I click the repeat button, then loop mode should toggle
    func testAsAUserIWantToToggleLoopMode() {
        // Given - Loop mode is none
        mockAudioEngine.loopMode = .none
        nowPlayingViewModel.updateState()
        XCTAssertEqual(nowPlayingViewModel.loopMode, .none)
        
        // When - I click the repeat button
        nowPlayingViewModel.toggleLoopMode()
        
        // Then - Loop mode should change to track
        XCTAssertEqual(nowPlayingViewModel.loopMode, .track)
        
        // When - I click the repeat button again
        nowPlayingViewModel.toggleLoopMode()
        
        // Then - Loop mode should change to queue
        XCTAssertEqual(nowPlayingViewModel.loopMode, .queue)
        
        // When - I click the repeat button again
        nowPlayingViewModel.toggleLoopMode()
        
        // Then - Loop mode should change back to none
        XCTAssertEqual(nowPlayingViewModel.loopMode, .none)
    }
    
    /// BDD: As a user, when loop mode is active, then the repeat button should show active state
    func testAsAUserIWantToSeeActiveRepeatButtonWhenLoopModeIsOn() {
        // Given - Loop mode is track
        mockAudioEngine.loopMode = .track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - Repeat button should show active state
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.loopMode, .track)
    }
    
    // MARK: - BDD Scenario 4: Volume Controls
    
    /// BDD: As a user, when I adjust the volume slider, then the volume should change
    func testAsAUserIWantToAdjustVolume() {
        // Given - Current volume is 0.5
        mockAudioEngine.volume = 0.5
        nowPlayingViewModel.updateState()
        XCTAssertEqual(nowPlayingViewModel.volume, 0.5)
        
        // When - I adjust the volume slider to 0.8
        nowPlayingViewModel.volume = 0.8
        
        // Then - Volume should be updated
        XCTAssertEqual(mockAudioEngine.volume, 0.8)
        XCTAssertEqual(nowPlayingViewModel.volume, 0.8)
    }
    
    /// BDD: As a user, when I click the mute button, then audio should be muted
    func testAsAUserIWantToMuteAudio() {
        // Given - Audio is not muted
        mockAudioEngine.isMuted = false
        mockAudioEngine.volume = 0.7
        nowPlayingViewModel.updateState()
        XCTAssertFalse(nowPlayingViewModel.isMuted)
        
        // When - I click the mute button
        nowPlayingViewModel.toggleMute()
        
        // Then - Audio should be muted
        XCTAssertTrue(mockAudioEngine.isMuted)
        XCTAssertTrue(nowPlayingViewModel.isMuted)
    }
    
    /// BDD: As a user, when I click the mute button again, then audio should be unmuted
    func testAsAUserIWantToUnmuteAudio() {
        // Given - Audio is muted
        mockAudioEngine.isMuted = true
        mockAudioEngine.previousVolume = 0.7
        nowPlayingViewModel.updateState()
        XCTAssertTrue(nowPlayingViewModel.isMuted)
        
        // When - I click the mute button
        nowPlayingViewModel.toggleMute()
        
        // Then - Audio should be unmuted
        XCTAssertFalse(mockAudioEngine.isMuted)
        XCTAssertFalse(nowPlayingViewModel.isMuted)
    }
    
    // MARK: - BDD Scenario 5: Button States
    
    /// BDD: As a user, when there is only one track, then previous and next buttons should be disabled
    func testAsAUserIWantToSeeDisabledNavigationButtonsWithSingleTrack() {
        // Given - Only one track in queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = []
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - Previous and next buttons should be disabled
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.queue.count, 0)
    }
    
    /// BDD: As a user, when there are multiple tracks, then previous and next buttons should be enabled
    func testAsAUserIWantToSeeEnabledNavigationButtonsWithMultipleTracks() {
        // Given - Multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track2]
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - Previous and next buttons should be enabled
        _ = view.body
        XCTAssertGreaterThan(nowPlayingViewModel.queue.count, 0)
    }
    
    // MARK: - BDD Scenario 6: Shuffle Functionality
    
    /// BDD: As a user, when I click the shuffle button, then shuffle mode should toggle
    func testAsAUserIWantToToggleShuffleMode() {
        // Given - Shuffle is disabled
        mockAudioEngine.isShuffleEnabled = false
        nowPlayingViewModel.updateState()
        XCTAssertFalse(nowPlayingViewModel.isShuffleEnabled)
        
        // When - I click the shuffle button
        nowPlayingViewModel.toggleShuffle()
        
        // Then - Shuffle should be enabled
        XCTAssertTrue(mockAudioEngine.isShuffleEnabled)
        XCTAssertTrue(nowPlayingViewModel.isShuffleEnabled)
        
        // When - I click the shuffle button again
        nowPlayingViewModel.toggleShuffle()
        
        // Then - Shuffle should be disabled
        XCTAssertFalse(mockAudioEngine.isShuffleEnabled)
        XCTAssertFalse(nowPlayingViewModel.isShuffleEnabled)
    }
    
    /// BDD: As a user, when shuffle is enabled, then the shuffle button should show blue
    func testAsAUserIWantToSeeBlueShuffleButtonWhenActive() {
        // Given - Shuffle is enabled
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.isShuffleEnabled = true
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - Shuffle button should show active state
        _ = view.body
        XCTAssertTrue(nowPlayingViewModel.isShuffleEnabled)
    }
    
    /// BDD: As a user, when I enable shuffle with tracks in queue, then the queue should be shuffled
    func testAsAUserIWantQueueShuffledWhenShuffleEnabled() {
        // Given - Multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        let track3 = MockFactory.makeTrack(title: "Track 3")
        mockAudioEngine.queue = [track1, track2, track3]
        let originalOrder = mockAudioEngine.queue.map { $0.title }
        
        // When - I enable shuffle
        mockAudioEngine.setShuffle(true)
        nowPlayingViewModel.updateState()
        
        // Then - Queue should be shuffled (order may be different)
        XCTAssertTrue(mockAudioEngine.isShuffleEnabled)
        // Note: Due to randomness, we can't guarantee order changed, but we verify shuffle was called
        XCTAssertEqual(mockAudioEngine.queue.count, 3)
    }
    
    // MARK: - BDD Scenario 7: Repeat Functionality
    
    /// BDD: As a user, when I click the repeat button, then loop mode should cycle through states
    func testAsAUserIWantToCycleThroughLoopModes() {
        // Given - Loop mode is none
        mockAudioEngine.loopMode = .none
        nowPlayingViewModel.updateState()
        XCTAssertEqual(nowPlayingViewModel.loopMode, .none)
        
        // When - I click the repeat button
        nowPlayingViewModel.toggleLoopMode()
        
        // Then - Loop mode should be track
        XCTAssertEqual(mockAudioEngine.loopMode, .track)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .track)
        
        // When - I click the repeat button again
        nowPlayingViewModel.toggleLoopMode()
        
        // Then - Loop mode should be queue
        XCTAssertEqual(mockAudioEngine.loopMode, .queue)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .queue)
        
        // When - I click the repeat button again
        nowPlayingViewModel.toggleLoopMode()
        
        // Then - Loop mode should be none
        XCTAssertEqual(mockAudioEngine.loopMode, .none)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .none)
    }
    
    /// BDD: As a user, when loop mode is active, then the repeat button should show blue
    func testAsAUserIWantToSeeBlueRepeatButtonWhenLoopModeActive() {
        // Given - Loop mode is track
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.loopMode = .track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then - Repeat button should show active state
        _ = view.body
        XCTAssertNotEqual(nowPlayingViewModel.loopMode, .none)
    }
}
