// NowPlayingViewModelTests.swift
// Audientia - UI Tests
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Combine
import XCTest

@testable import AudioCore
@testable import Shared

// Import NowPlayingViewModel from UI module
// Since it's in the app target, we include the source file in UITests target

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

/// TDD Tests for NowPlayingViewModel
/// Following Right-BICEP principles for comprehensive test coverage
@MainActor
final class NowPlayingViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: NowPlayingViewModel!
    private var mockAudioEngine: MockAudioEngine!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockAudioEngine = MockAudioEngine()
        viewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockAudioEngine = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// BDD: Given a track is loaded, when I view the Now Playing screen, then I should see the track information
    func testDisplaysCurrentTrackInformation() async throws {
        // Given - A track is loaded in the audio engine
        let track = MockFactory.makeTrack(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.duration = 180.0
        mockAudioEngine.state = PlaybackState.playing
        
        // When - ViewModel syncs state from engine
        viewModel.updateState()
        
        // Then - Track information should be available
        XCTAssertEqual(viewModel.currentTrack?.title, "Test Track")
        XCTAssertEqual(viewModel.currentTrack?.artist, "Test Artist")
        XCTAssertEqual(viewModel.currentTrack?.album, "Test Album")
    }
    
    /// BDD: Given playback is active, when I view the Now Playing screen, then I should see the current playback state
    func testDisplaysPlaybackState() {
        // Given - Audio engine is playing
        mockAudioEngine.state = PlaybackState.playing
        
        // When - ViewModel observes state
        viewModel.updateState()
        
        // Then - Playback state should be playing
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertFalse(viewModel.isStopped)
    }
    
    /// BDD: Given a track is playing, when I view the Now Playing screen, then I should see the current position and progress
    func testDisplaysPlaybackProgress() {
        // Given - Track is playing at 30 seconds of a 180 second track
        let track = MockFactory.makeTrack(duration: 180.0)
        mockAudioEngine.currentTrack = track
        mockAudioEngine.duration = 180.0
        mockAudioEngine.currentPosition = 30.0
        mockAudioEngine.state = PlaybackState.playing
        
        // When - ViewModel updates
        viewModel.updateState()
        
        // Then - Progress should be calculated correctly
        XCTAssertEqual(viewModel.currentPosition, 30.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.progress, 30.0 / 180.0, accuracy: 0.01)
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test with no track loaded (empty state)
    func testHandlesNoTrackLoaded() {
        // Given - No track is loaded
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.duration = 0.0
        mockAudioEngine.state = PlaybackState.stopped
        
        // When - ViewModel updates
        viewModel.updateState()
        
        // Then - Should handle gracefully
        XCTAssertNil(viewModel.currentTrack)
        XCTAssertTrue(viewModel.isStopped)
        XCTAssertEqual(viewModel.currentPosition, 0.0)
        XCTAssertEqual(viewModel.progress, 0.0)
    }
    
    /// Test with zero duration track
    func testHandlesZeroDurationTrack() {
        // Given - Track with zero duration
        let track = MockFactory.makeTrack(duration: 0.0)
        mockAudioEngine.currentTrack = track
        mockAudioEngine.duration = 0.0
        mockAudioEngine.currentPosition = 0.0
        
        // When - ViewModel updates
        viewModel.updateState()
        
        // Then - Progress should be 0 (not NaN or infinity)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertFalse(viewModel.progress.isNaN)
        XCTAssertFalse(viewModel.progress.isInfinite)
    }
    
    /// Test with very long track (3+ hours)
    func testHandlesVeryLongTrack() {
        // Given - Very long track (3 hours = 10800 seconds)
        let longDuration: TimeInterval = 10800.0
        let track = MockFactory.makeTrack(duration: longDuration)
        mockAudioEngine.currentTrack = track
        mockAudioEngine.duration = longDuration
        mockAudioEngine.currentPosition = 5400.0 // Halfway
        
        // When - ViewModel updates
        viewModel.updateState()
        
        // Then - Progress should be calculated correctly
        XCTAssertEqual(viewModel.progress, 0.5, accuracy: 0.01)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// BDD: Given playback is paused, when I press play, then playback should resume
    func testPlayPauseInverseRelationship() async throws {
        // Given - Track is loaded and paused
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.duration = track.duration
        mockAudioEngine.state = PlaybackState.paused
        
        // When - User presses play
        try await viewModel.play()
        
        // Then - Engine should be asked to play
        XCTAssertTrue(mockAudioEngine.playCalled)
        
        // When - User presses pause
        await viewModel.pause()
        
        // Then - Engine should be asked to pause
        XCTAssertTrue(mockAudioEngine.pauseCalled)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Verify ViewModel state matches AudioEngine state
    func testViewModelStateMatchesAudioEngine() {
        // Given - Audio engine in various states
        let states: [PlaybackState] = [.stopped, .playing, .paused, .loading]
        
        for state in states {
            mockAudioEngine.state = state
            viewModel.updateState()
            
            // Then - ViewModel should reflect engine state
            switch state {
            case .stopped:
                XCTAssertTrue(viewModel.isStopped)
            case .playing:
                XCTAssertTrue(viewModel.isPlaying)
            case .paused:
                XCTAssertTrue(viewModel.isPaused)
            case .loading:
                XCTAssertTrue(viewModel.isLoading)
            case .error:
                // Error state is handled separately
                break
            }
        }
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// BDD: Given playback fails, when I try to play, then I should see an error message
    func testHandlesPlaybackError() async {
        // Given - Audio engine will fail to play (no track loaded)
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.shouldFailPlay = true
        
        // When - User tries to play
        do {
            try await viewModel.play()
            XCTFail("Expected error to be thrown")
        } catch {
            // Then - Error should be handled
            XCTAssertNotNil(viewModel.lastError)
        }
    }
    
    /// Test handling of missing track file
    func testHandlesMissingTrackFile() async {
        // Given - Track with invalid file path
        let track = MockFactory.makeTrack(filePath: "/nonexistent/file.mp3")
        mockAudioEngine.currentTrack = track
        mockAudioEngine.shouldFailLoad = true
        
        // When - User tries to load track
        do {
            try await viewModel.loadTrack(track)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertNotNil(viewModel.lastError)
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test that state updates are performant
    func testStateUpdatePerformance() {
        measure {
            for _ in 0..<1000 {
                viewModel.updateState()
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    /// Test rapid play/pause toggling
    func testRapidPlayPauseToggle() async throws {
        // Given - Track is loaded
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        
        // When - Rapidly toggling play/pause
        for _ in 0..<10 {
            try await viewModel.play()
            await viewModel.pause()
        }
        
        // Then - Should handle gracefully without crashes
        XCTAssertTrue(mockAudioEngine.playCalled)
        XCTAssertTrue(mockAudioEngine.pauseCalled)
    }
    
    /// Test seeking beyond track duration
    func testSeekBeyondDuration() async {
        // Given - Track with 180 second duration
        let track = MockFactory.makeTrack(duration: 180.0)
        mockAudioEngine.currentTrack = track
        mockAudioEngine.duration = 180.0
        
        // When - User seeks to 200 seconds (beyond duration)
        await viewModel.seek(to: 200.0)
        
        // Then - Should clamp to duration or handle gracefully
        // (Implementation may clamp to duration or seek to end)
        XCTAssertLessThanOrEqual(viewModel.currentPosition, 180.0)
    }
}
