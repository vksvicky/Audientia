// NowPlayingBDDScenarios.swift
// Audientia - UI BDD Scenarios
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Combine
import XCTest
@testable import AudioCore
@testable import Shared

// Use MockFactory from AudioCoreTests - in production, this would be in shared test infrastructure
// For now, we'll create a local helper
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

/// BDD Scenarios for Now Playing UI
/// Following "Given-When-Then" pattern for user stories
@MainActor
final class NowPlayingBDDScenarios: XCTestCase {
    
    private var viewModel: NowPlayingViewModel!
    private var mockAudioEngine: MockAudioEngine!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        viewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAudioEngine = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: View Now Playing Screen
    
    /// BDD: As a user, when I open the Now Playing screen, then I should see the currently playing track information
    func testUserViewsNowPlayingScreen() async throws {
        // Given - A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera"
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        mockAudioEngine.currentPosition = 60.0
        
        // When - I view the Now Playing screen
        viewModel.updateState()
        
        // Then - I should see the track information
        XCTAssertEqual(viewModel.currentTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(viewModel.currentTrack?.artist, "Queen")
        XCTAssertEqual(viewModel.currentTrack?.album, "A Night at the Opera")
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertEqual(viewModel.currentPosition, 60.0, accuracy: 0.1)
    }
    
    // MARK: - BDD Scenario 2: Play Track
    
    /// BDD: As a user, when I press the play button, then the track should start playing
    func testUserPlaysTrack() async throws {
        // Given - A track is loaded but not playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .stopped
        
        // When - I press the play button
        try await viewModel.play()
        
        // Then - The track should start playing
        XCTAssertTrue(mockAudioEngine.playCalled)
        XCTAssertTrue(viewModel.isPlaying)
    }
    
    // MARK: - BDD Scenario 3: Pause Track
    
    /// BDD: As a user, when I press the pause button, then playback should pause
    func testUserPausesTrack() async {
        // Given - A track is currently playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        
        // When - I press the pause button
        await viewModel.pause()
        
        // Then - Playback should pause
        XCTAssertTrue(mockAudioEngine.pauseCalled)
        XCTAssertTrue(viewModel.isPaused)
    }
    
    // MARK: - BDD Scenario 4: Seek in Track
    
    /// BDD: As a user, when I drag the progress slider, then playback should seek to that position
    func testUserSeeksInTrack() async {
        // Given - A track is playing at 30 seconds
        let track = MockFactory.makeTrack(duration: 180.0)
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        mockAudioEngine.currentPosition = 30.0
        mockAudioEngine.duration = 180.0
        
        // When - I drag the slider to 90 seconds
        await viewModel.seek(to: 90.0)
        
        // Then - Playback should seek to 90 seconds
        XCTAssertTrue(mockAudioEngine.seekCalled)
        XCTAssertEqual(viewModel.currentPosition, 90.0, accuracy: 0.1)
    }
    
    // MARK: - BDD Scenario 5: Adjust Volume
    
    /// BDD: As a user, when I adjust the volume slider, then the playback volume should change
    func testUserAdjustsVolume() {
        // Given - Volume is at 50%
        viewModel.volume = 0.5
        
        // When - I adjust the volume slider to 75%
        viewModel.volume = 0.75
        
        // Then - Volume should be updated
        XCTAssertEqual(viewModel.volume, 0.75, accuracy: 0.01)
    }
    
    // MARK: - BDD Scenario 6: View Playback Progress
    
    /// BDD: As a user, when a track is playing, then I should see the progress update in real-time
    func testUserViewsPlaybackProgress() {
        // Given - A track is playing
        let track = MockFactory.makeTrack(duration: 180.0)
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        mockAudioEngine.currentPosition = 45.0
        mockAudioEngine.duration = 180.0
        
        // When - ViewModel updates
        viewModel.updateState()
        
        // Then - Progress should be calculated and displayed
        XCTAssertEqual(viewModel.currentPosition, 45.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.progress, 45.0 / 180.0, accuracy: 0.01)
    }
    
    // MARK: - BDD Scenario 7: Handle Loading State
    
    /// BDD: As a user, when a track is loading, then I should see a loading indicator
    func testUserSeesLoadingState() {
        // Given - A track is being loaded
        mockAudioEngine.state = .loading
        
        // When - ViewModel updates
        viewModel.updateState()
        
        // Then - Loading state should be indicated
        XCTAssertTrue(viewModel.isLoading)
    }
    
    // MARK: - BDD Scenario 8: Handle Error State
    
    /// BDD: As a user, when playback fails, then I should see an error message
    func testUserSeesErrorState() async {
        // Given - Playback will fail
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.shouldFailPlay = true
        
        // When - I try to play
        do {
            try await viewModel.play()
            XCTFail("Expected error")
        } catch {
            // Then - Error should be displayed
            XCTAssertNotNil(viewModel.lastError)
        }
    }
}

