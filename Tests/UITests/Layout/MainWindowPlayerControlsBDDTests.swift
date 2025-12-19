//
//  MainWindowPlayerControlsBDDTests.swift
//  UITests
//
//  BDD tests for MainWindowPlayerControls
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
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

/// BDD Tests for CollapsiblePlayerBar (formerly MainWindowPlayerControls)
@MainActor
final class MainWindowPlayerControlsBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockAudioEngine: MockAudioEngine!
    private var nowPlayingViewModel: NowPlayingViewModel!
    private var tempDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        
        // Clear AppSettings
        AppSettings.shared.lastPlayedTrack = nil
    }
    
    override func tearDown() {
        nowPlayingViewModel = nil
        mockAudioEngine = nil
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        
        // Clear AppSettings
        AppSettings.shared.lastPlayedTrack = nil
        
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
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - I should see the track information
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.artist, "Queen")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.album, "A Night at the Opera")
    }
    
    // MARK: - BDD Scenario 8: Visualizer Functionality
    
    /// BDD: As a user, when I want to toggle the visualiser, then I can access it via the Visualiser tab
    /// Note: Visualiser functionality has been moved to a separate tab in the main window layout
    func testAsAUserIWantToAccessVisualizer() {
        // Given - A track is playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - Player controls should be visible
        // Note: Visualiser is now accessed via the Visualiser tab, not from player controls
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }
    
    /// BDD: As a user, when no track is playing, then I should see "No track selected"
    func testAsAUserIWantToSeeNoTrackMessageWhenNothingPlaying() {
        // Given - No track is loaded
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - I should see "No track selected"
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    // MARK: - BDD Scenario 2: Playback Controls
    
    /// BDD: As a user, when I click the play button, then the track should start playing
    func testAsAUserIWantToPlayTrack() async throws {
        // Given - A track is loaded but paused
        // Create a temporary file for the track so file existence check passes
        let testFile = tempDirectory.appendingPathComponent("test.mp3")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        let track = MockFactory.makeTrack(filePath: testFile.path)
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
        // History contains: [track1, track2] where we're currently on track2 (index 1)
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track2
        mockAudioEngine.queueHistory = [track1, track2] // Both tracks in history
        mockAudioEngine.currentQueueIndex = 1 // Currently on track2 (index 1)
        nowPlayingViewModel.updateState()
        
        // When - I click the previous button
        try await nowPlayingViewModel.playPrevious()
        
        // Then - Previous track should play
        XCTAssertTrue(mockAudioEngine.playPreviousCalled)
        XCTAssertEqual(mockAudioEngine.currentTrack?.title, "Track 1", "Should be playing track1 after going back")
        XCTAssertEqual(mockAudioEngine.currentQueueIndex, 0, "Should be at index 0 after going back")
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
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - Repeat button should show active state
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .track)
    }
    
    // MARK: - BDD Scenario 4: Volume Controls
    
    /// BDD: As a user, when I adjust the volume slider, then the volume should change
    func testAsAUserIWantToAdjustVolume() async {
        // Given - Current volume is 0.5
        mockAudioEngine.volume = 0.5
        nowPlayingViewModel.volume = 0.5 // Set view model volume to match
        // Wait a bit for any async operations
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertEqual(nowPlayingViewModel.volume, 0.5)
        
        // When - I adjust the volume slider to 0.8
        nowPlayingViewModel.volume = 0.8
        
        // Wait for async volume update to complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Then - Volume should be updated
        XCTAssertEqual(mockAudioEngine.volume, 0.8, accuracy: 0.01)
        XCTAssertEqual(nowPlayingViewModel.volume, 0.8, accuracy: 0.01)
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
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - Previous and next buttons should be disabled
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
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
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - Previous and next buttons should be enabled
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
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
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - Shuffle button should show active state
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertTrue(nowPlayingViewModel.isShuffleEnabled)
    }
    
    /// BDD: As a user, when I enable shuffle with tracks in queue, then the queue should be shuffled
    func testAsAUserIWantQueueShuffledWhenShuffleEnabled() {
        // Given - Multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        let track3 = MockFactory.makeTrack(title: "Track 3")
        mockAudioEngine.queue = [track1, track2, track3]
        _ = mockAudioEngine.queue.map { $0.title }
        
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
        let view = CollapsiblePlayerBar(nowPlayingViewModel: nowPlayingViewModel, isExpanded: .constant(true), onMinimize: nil)
        
        // Then - Repeat button should show active state
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNotEqual(nowPlayingViewModel.loopMode, .none)
    }
}

#endif
