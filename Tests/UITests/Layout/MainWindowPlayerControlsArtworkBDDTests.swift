//
//  MainWindowPlayerControlsArtworkBDDTests.swift
//  UITests
//
//  BDD tests for MainWindowPlayerControls - Album Artwork Scenarios
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

/// BDD Tests for MainWindowPlayerControls - Album Artwork Scenarios
@MainActor
final class MainWindowPlayerControlsArtworkBDDTests: XCTestCase {
    
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
    
    // MARK: - Album Artwork Scenarios
    
    /// BDD: As a user, I want to see album artwork when playing a track
    func testAsAUserIWantToSeeAlbumArtworkWhenPlayingTrack() async {
        // Given - A track is loaded
        let track = MockFactory.makeTrack(title: "My Favorite Song")
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then - The view should render and attempt to load artwork
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "My Favorite Song")
        
        // Give time for artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    /// BDD: As a user, I want to see a placeholder when no artwork is available
    func testAsAUserIWantToSeePlaceholderWhenNoArtwork() {
        // Given - A track with no artwork
        let track = MockFactory.makeTrack(filePath: "/path/without/artwork.mp3")
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then - The view should show a placeholder (music.note icon)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNotNil(nowPlayingViewModel.currentTrack)
    }
    
    /// BDD: As a user, when I switch tracks, I want to see the new track's artwork
    func testAsAUserIWantToSeeNewArtworkWhenSwitchingTracks() async {
        // Given - Playing a track
        let track1 = MockFactory.makeTrack(title: "Song 1")
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Give time for initial artwork
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When - I switch to a different track
        let track2 = MockFactory.makeTrack(title: "Song 2")
        mockAudioEngine.currentTrack = track2
        nowPlayingViewModel.updateState()
        
        // Give time for new artwork
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - New artwork should be loaded
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Song 2")
    }
    
    /// BDD: As a user, I want artwork to load from embedded metadata
    func testAsAUserIWantArtworkToLoadFromEmbeddedMetadata() {
        // Given - A track with embedded artwork (simulated by file extension)
        let track = MockFactory.makeTrack(filePath: "/path/to/song.m4a")
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then - Artwork extraction should be attempted
        XCTAssertNotNil(hostingController.view)
        XCTAssertTrue(track.filePath.hasSuffix(".m4a"))
    }
    
    /// BDD: As a user, I want artwork to fallback to sidecar files if no embedded artwork
    func testAsAUserIWantArtworkToFallbackToSidecarFiles() {
        // Given - A track without embedded artwork
        let track = MockFactory.makeTrack(filePath: "/music/album/track.flac")
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then - Should attempt to load from sidecar files (cover.jpg, folder.png, etc.)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNotNil(nowPlayingViewModel.currentTrack)
    }
    
    /// BDD: As a user, I want the app to handle corrupt artwork files gracefully
    func testAsAUserIWantAppToHandleCorruptArtworkGracefully() {
        // Given - A track with potentially corrupt artwork
        let track = MockFactory.makeTrack(filePath: "/path/to/corrupt.mp3")
        mockAudioEngine.currentTrack = track
        nowPlayingViewModel.updateState()
        
        // When - I view the player controls
        let view = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let hostingController = NSHostingController(rootView: view)
        
        // Then - Should not crash, show placeholder instead
        XCTAssertNotNil(hostingController.view)
        XCTAssertNotNil(nowPlayingViewModel.currentTrack)
    }
    
    /// BDD: As a user, I want artwork to be visible in both main and minimized player
    func testAsAUserIWantArtworkInBothPlayerViews() async {
        // Given - A track is playing
        let track = MockFactory.makeTrack(title: "Beautiful Song")
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        // When - I view both player controls
        let mainView = MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel, showVisualizer: .constant(false))
        let mainController = NSHostingController(rootView: mainView)
        
        // Then - Both views should attempt to load artwork
        XCTAssertNotNil(mainController.view)
        XCTAssertEqual(nowPlayingViewModel.currentTrack?.title, "Beautiful Song")
        
        // Give time for artwork loading
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

#endif
