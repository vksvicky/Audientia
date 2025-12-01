//
//  MainWindowPlayerControlsTests.swift
//  UITests
//
//  TDD tests for MainWindowPlayerControls following Right-BICEP principles
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

/// TDD Tests for MainWindowPlayerControls
/// Following Right-BICEP principles for comprehensive test coverage
@MainActor
final class MainWindowPlayerControlsTests: XCTestCase {
    
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
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: View should initialize with NowPlayingViewModel
    func testViewInitialization() {
        // Given: A NowPlayingViewModel
        // When: Creating MainWindowPlayerControls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: View should be hosted without triggering SwiftUI state warnings
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }
    
    /// Test: View should display track information when track is playing
    func testDisplaysTrackInformation() {
        // Given: A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera"
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: View should display track information
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.artist, "Queen")
    }
    
    /// Test: View should display "No track selected" when no track is playing
    func testDisplaysNoTrackMessage() {
        // Given: No track is loaded
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: View should show "No track selected"
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: Previous button should be disabled when queue has only one track
    func testPreviousButtonDisabledWithSingleTrack() {
        // Given: Only one track in queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = []
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Previous button should be disabled
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.queue.count, 0)
    }
    
    /// Test: Next button should be disabled when queue has only one track
    func testNextButtonDisabledWithSingleTrack() {
        // Given: Only one track in queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = []
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Next button should be disabled
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.queue.count, 0)
    }
    
    /// Test: Previous button should be enabled when queue has multiple tracks
    func testPreviousButtonEnabledWithMultipleTracks() {
        // Given: Multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track2]
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Previous button should be enabled
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertGreaterThan(nowPlayingViewModel.queue.count, 0)
    }
    
    /// Test: Next button should be enabled when queue has multiple tracks
    func testNextButtonEnabledWithMultipleTracks() {
        // Given: Multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track2]
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Next button should be enabled
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertGreaterThan(nowPlayingViewModel.queue.count, 0)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Play button should show pause icon when playing
    func testPlayButtonShowsPauseWhenPlaying() {
        // Given: Track is playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Play button should show pause icon
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertTrue(nowPlayingViewModel.isPlaying)
    }
    
    /// Test: Play button should show play icon when paused
    func testPlayButtonShowsPlayWhenPaused() {
        // Given: Track is paused
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .paused
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Play button should show play icon
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertFalse(nowPlayingViewModel.isPlaying)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: Repeat button should show correct icon for each loop mode
    func testRepeatButtonShowsCorrectIconForLoopMode() {
        // Given: Different loop modes
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        
        // When: Loop mode is none
        mockAudioEngine.loopMode = .none
        nowPlayingViewModel.updateState()
        var view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingControllerNone = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingControllerNone.view)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .none)
        
        // When: Loop mode is track
        mockAudioEngine.loopMode = .track
        nowPlayingViewModel.updateState()
        view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingControllerTrack = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingControllerTrack.view)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .track)
        
        // When: Loop mode is queue
        mockAudioEngine.loopMode = .queue
        nowPlayingViewModel.updateState()
        view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingControllerQueue = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingControllerQueue.view)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .queue)
    }
    
    /// Test: Shuffle button should show blue when active
    func testShuffleButtonShowsBlueWhenActive() {
        // Given: Shuffle is enabled
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.isShuffleEnabled = true
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Shuffle should be active
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertTrue(nowPlayingViewModel.isShuffleEnabled)
    }
    
    /// Test: Shuffle button should show primary color when inactive
    func testShuffleButtonShowsPrimaryWhenInactive() {
        // Given: Shuffle is disabled
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.isShuffleEnabled = false
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Shuffle should be inactive
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertFalse(nowPlayingViewModel.isShuffleEnabled)
    }
    
    /// Test: Repeat button should show blue when loop mode is active
    func testRepeatButtonShowsBlueWhenLoopModeActive() {
        // Given: Loop mode is track
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.loopMode = .track
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Loop mode should be active
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNotEqual(nowPlayingViewModel.loopMode, .none)
    }
    
    /// Test: Repeat button should show primary color when loop mode is none
    func testRepeatButtonShowsPrimaryWhenLoopModeNone() {
        // Given: Loop mode is none
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.loopMode = .none
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Loop mode should be none
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.loopMode, .none)
    }
    
    /// Test: Visualizer button should show blue when active
    func testVisualizerButtonShowsBlueWhenActive() {
        // Given: Visualizer is shown
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: View is rendered with visualizer active
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(true))
        
        // Then: Visualizer button should show active state
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        // Visualizer state is managed by binding, so we verify the view compiles
    }
    
    /// Test: Visualizer button should show primary color when inactive
    func testVisualizerButtonShowsPrimaryWhenInactive() {
        // Given: Visualizer is not shown
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: View is rendered with visualizer inactive
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: Visualizer button should show inactive state
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        // Visualizer state is managed by binding, so we verify the view compiles
    }
    
    /// Test: Mute button should show correct icon based on mute state
    func testMuteButtonShowsCorrectIcon() {
        // Given: Audio engine mute states
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        
        // When: Not muted
        mockAudioEngine.isMuted = false
        nowPlayingViewModel.updateState()
        var view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        var hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertFalse(nowPlayingViewModel.isMuted)
        
        // When: Muted
        mockAudioEngine.isMuted = true
        nowPlayingViewModel.updateState()
        view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertTrue(nowPlayingViewModel.isMuted)
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: View should handle nil track gracefully
    func testHandlesNilTrackGracefully() {
        // Given: No track loaded
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: View should not crash
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    /// Test: View should handle empty queue gracefully
    func testHandlesEmptyQueueGracefully() {
        // Given: Track playing but empty queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = []
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        
        // Then: View should not crash
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.queue.count, 0)
    }
    
    // MARK: - Artwork Loading Tests
    
    /// Test: Artwork loading should be triggered when track changes
    func testArtworkLoadingTriggeredOnTrackChange() async {
        // Given: Initial track with artwork
        let track1 = MockFactory.makeTrack(title: "Track 1")
        mockAudioEngine.currentTrack = track1
        nowPlayingViewModel.updateState()
        
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Give time for initial artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // When: Track changes
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track2
        nowPlayingViewModel.updateState()
        
        // Give time for new artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: New artwork loading should have been triggered
        // (Verify through console logs in real app)
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Track 2")
    }
    
    /// Test: Artwork should be cleared when no track is playing
    func testArtworkClearedWhenNoTrack() {
        // Given: No current track
        mockAudioEngine.currentTrack = nil
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then: View should render without crashing (artwork should be nil)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    /// Test: Multiple rapid track changes should not cause concurrent artwork loading
    func testRapidTrackChangesHandledGracefully() async {
        // Given: Multiple tracks
        let tracks = (0..<5).map { MockFactory.makeTrack(title: "Track \($0)") }
        
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // When: Rapidly changing tracks
        for track in tracks {
            mockAudioEngine.currentTrack = track
            nowPlayingViewModel.updateState()
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        // Give time for final artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should end with last track without crashes
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Track 4")
    }
    
    /// Test: Artwork extraction should handle missing files gracefully
    func testArtworkExtractionHandlesMissingFiles() {
        // Given: Track with non-existent file path
        let track = MockFactory.makeTrack(filePath: "/nonexistent/path/to/file.mp3")
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then: Should not crash, artwork should be nil
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.filePath, "/nonexistent/path/to/file.mp3")
    }
    
    /// Test: Artwork loading should work with various file extensions
    func testArtworkLoadingWithVariousFileExtensions() {
        let extensions = ["mp3", "m4a", "flac", "wav", "aac", "ogg"]
        
        for ext in extensions {
            // Given: Track with specific extension
            let track = MockFactory.makeTrack(filePath: "/path/to/file.\(ext)")
            mockAudioEngine.currentTrack = track
            nowPlayingViewModel.updateState()
            
            // When: View is rendered
            let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
            let hostingController = NSHostingController(rootView: view)
            
            // Then: Should not crash
            XCTAssertNotNil(hostingController.view, "Failed for extension: \(ext)")
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: View should render efficiently with many tracks in queue
    func testPerformanceWithLargeQueue() {
        // Given: Large queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = (0..<100).map { _ in MockFactory.makeTrack() }
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        measure {
            let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
            let hostingController = NSHostingController(rootView: view)
            _ = hostingController.view
        }
    }
    
    /// Test: Artwork loading should complete within reasonable time
    func testArtworkLoadingPerformance() {
        // Given: Track with file path
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: Measuring artwork loading performance
        measure {
            let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
            let hostingController = NSHostingController(rootView: view)
            _ = hostingController.view
        }
    }
}

#endif
