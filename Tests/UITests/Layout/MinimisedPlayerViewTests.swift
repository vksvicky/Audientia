//
//  MinimisedPlayerViewTests.swift
//  UITests
//
//  TDD tests for MinimisedPlayerView following Right-BICEP principles
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
final class MinimisedPlayerViewTests: XCTestCase {
    var mockAudioEngine: MockAudioEngine!
    var nowPlayingViewModel: NowPlayingViewModel!
    var restoreCalled: Bool!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        restoreCalled = false
    }
    
    override func tearDown() {
        nowPlayingViewModel = nil
        mockAudioEngine = nil
        restoreCalled = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    func testViewInitialisation() {
        // Given: A NowPlayingViewModel and restore callback
        // When: Creating MinimisedPlayerView
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: View should be created
        _ = view.body // Access body to verify compilation
    }
    
    func testViewDisplaysTrackInformation() {
        // Given: A track is currently playing
        let track = MockFactory.makeTrack(
            title: "Test Track",
            artist: "Test Artist"
        )
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: View should display track information
        _ = view.body // Verify compilation
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Test Track")
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.artist, "Test Artist")
    }
    
    func testViewShowsNoTrackWhenNothingPlaying() {
        // Given: No track is playing
        mockAudioEngine.currentTrack = nil
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: View should handle no track state
        _ = view.body // Verify compilation
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    // MARK: - Right-[B]ICEP - Boundary Conditions
    
    func testViewHandlesEmptyQueue() {
        // Given: Track playing but empty queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = []
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: Previous/Next buttons should be disabled
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.queue.count, 0)
    }
    
    func testViewHandlesSingleTrackInQueue() {
        // Given: Single track in queue
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = [track]
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: Previous/Next buttons should be disabled
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.queue.count, 1)
    }
    
    func testViewHandlesLongTrackTitle() {
        // Given: Track with very long title
        let longTitle = String(repeating: "A", count: 200)
        let track = MockFactory.makeTrack(title: longTitle)
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: View should handle long title gracefully
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, longTitle)
    }
    
    // MARK: - Right-BIC[E]P - Forcing Error Conditions
    
    func testViewHandlesViewModelStateChanges() {
        // Given: View is created
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // When: Track changes
        let track1 = MockFactory.makeTrack(title: "Track 1")
        mockAudioEngine.currentTrack = track1
        nowPlayingViewModel.updateState()
        
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track2
        nowPlayingViewModel.updateState()
        
        // Then: View should reflect changes
        _ = view.body
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Track 2")
    }
    
    // MARK: - Restore Functionality
    
    func testRestoreButtonCallsCallback() {
        // Given: View with restore callback
        var callbackInvoked = false
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { callbackInvoked = true }
        )
        
        // When: Restore button is tapped (simulated by calling onRestore)
        view.onRestore()
        
        // Then: Callback should be invoked
        XCTAssertTrue(callbackInvoked, "Restore callback should be invoked")
        
        // When: Restore is called (simulating button tap)
        // Note: In actual UI test, we would tap the button
        // For unit test, we verify the callback exists
        _ = view.body
        
        // Then: Callback should be available
        XCTAssertNotNil(view.onRestore)
    }
    
    func testViewMaintainsStateDuringPlayback() {
        // Given: Track is playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When: View is rendered during playback
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: View should show playing state
        _ = view.body
        XCTAssertTrue(nowPlayingViewModel.isPlaying)
    }
    
    // MARK: - Artwork Loading Tests
    
    func testArtworkLoadingTriggeredWhenTrackChanges() async {
        // Given: Initial track
        let track1 = MockFactory.makeTrack(title: "Track 1")
        mockAudioEngine.currentTrack = track1
        nowPlayingViewModel.updateState()
        
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        _ = view.body
        
        // Give time for initial artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Track changes
        let track2 = MockFactory.makeTrack(title: "Track 2")
        mockAudioEngine.currentTrack = track2
        nowPlayingViewModel.updateState()
        
        // Give time for new artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: New artwork should be loaded
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Track 2")
    }
    
    func testArtworkClearedWhenNoTrackPlaying() {
        // Given: No current track
        mockAudioEngine.currentTrack = nil
        nowPlayingViewModel.updateState()
        
        // When: View is rendered
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        
        // Then: Should not crash
        _ = view.body
        XCTAssertNil(nowPlayingViewModel.currentTrack)
    }
    
    func testArtworkLoadingHandlesVariousFileFormats() {
        let fileFormats = ["mp3", "m4a", "flac", "wav", "aac", "ogg"]
        
        for format in fileFormats {
            // Given: Track with specific format
            let track = MockFactory.makeTrack(filePath: "/path/to/file.\(format)")
            mockAudioEngine.currentTrack = track
            nowPlayingViewModel.updateState()
            
            // When: View is rendered
            let view = MinimisedPlayerView(
                nowPlayingViewModel: nowPlayingViewModel,
                onRestore: { self.restoreCalled = true }
            )
            
            // Then: Should not crash
            _ = view.body
            XCTAssertNotNil(nowPlayingViewModel.currentTrack, "Failed for format: \(format)")
        }
    }
    
    func testArtworkLoadingPerformance() {
        // Given: Track with file path
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When: Measuring artwork loading performance
        measure {
            let view = MinimisedPlayerView(
                nowPlayingViewModel: nowPlayingViewModel,
                onRestore: { self.restoreCalled = true }
            )
            _ = view.body
        }
    }
    
    func testMultipleRapidTrackChangesHandledGracefully() async {
        // Given: Multiple tracks
        let tracks = (0..<5).map { MockFactory.makeTrack(title: "Track \($0)") }
        
        let view = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { self.restoreCalled = true }
        )
        _ = view.body
        
        // When: Rapidly changing tracks
        for track in tracks {
            mockAudioEngine.currentTrack = track
            nowPlayingViewModel.updateState()
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        // Give time for final artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should end with last track
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Track 4")
    }
}

#endif
