//
//  MinimisePlayerBDDTests.swift
//  UITests
//
//  BDD tests for minimize-to-player functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
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
final class MinimisePlayerBDDTests: XCTestCase {
    var appDelegate: AppDelegate!
    var mockAudioEngine: MockAudioEngine!
    var nowPlayingViewModel: NowPlayingViewModel!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // Setup main window reference
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        appDelegate.mainWindow = window
    }
    
    override func tearDown() {
        if appDelegate.isMinimised {
            appDelegate.restoreFromPlayer()
        }
        appDelegate.minimisedPlayerWindow?.close()
        appDelegate.minimisedPlayerWindow = nil
        nowPlayingViewModel = nil
        mockAudioEngine = nil
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Minimize to Player
    
    /// BDD: As a user, when I click the minimize button, then the main window should hide and a floating player should appear
    func testUserMinimizesToPlayer() {
        // Given - I have the main window open with a track playing
        let track = MockFactory.makeTrack(
            title: "Test Track",
            artist: "Test Artist"
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        appDelegate.mainWindow?.makeKeyAndOrderFront(nil)
        XCTAssertTrue(appDelegate.mainWindow?.isVisible ?? false)
        
        // When - I click the minimize button
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then - The main window should be hidden and a floating player should appear
        XCTAssertFalse(appDelegate.mainWindow?.isVisible ?? true)
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow)
        XCTAssertTrue(appDelegate.minimisedPlayerWindow?.isVisible ?? false)
        XCTAssertTrue(appDelegate.isMinimised)
    }
    
    // MARK: - BDD Scenario 2: Restore from Minimised Player
    
    /// BDD: As a user, when I click the restore button in the minimised player, then the main window should be restored
    func testUserRestoresFromMinimisedPlayer() {
        // Given - I have minimised the player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        XCTAssertTrue(appDelegate.isMinimised)
        let minimisedWindow = appDelegate.minimisedPlayerWindow
        XCTAssertNotNil(minimisedWindow)
        XCTAssertTrue(minimisedWindow?.isVisible ?? false)
        
        // When - I click the restore button
        appDelegate.restoreFromPlayer()
        
        // Then - The main window should be shown and the minimised player should close
        XCTAssertFalse(appDelegate.isMinimised)
        XCTAssertTrue(appDelegate.mainWindow?.isVisible ?? false)
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "minimisedPlayerWindow property should be nil after restore")
        // The window object itself may still exist in memory (just closed), so check it's closed instead
        XCTAssertFalse(minimisedWindow?.isVisible ?? true, "Minimised window should be closed after restore")
    }
    
    // MARK: - BDD Scenario 3: Control Playback from Minimised Player
    
    /// BDD: As a user, when I control playback from the minimised player, then playback should work correctly
    func testUserControlsPlaybackFromMinimisedPlayer() async throws {
        // Given - I have minimised the player and a track is playing
        let track = MockFactory.makeTrack()
        mockAudioEngine.currentTrack = track
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        XCTAssertTrue(appDelegate.isMinimised)
        
        // When - I pause playback from the minimised player
        await nowPlayingViewModel.pause()
        
        // Then - Playback should pause
        XCTAssertTrue(nowPlayingViewModel.isPaused)
        XCTAssertTrue(mockAudioEngine.pauseCalled)
    }
    
    // MARK: - BDD Scenario 4: Navigate Tracks from Minimised Player
    
    /// BDD: As a user, when I navigate tracks from the minimised player, then the next track should play
    func testUserNavigatesTracksFromMinimisedPlayer() async throws {
        // Given - I have minimised the player with multiple tracks in queue
        let track1 = MockFactory.makeTrack(title: "Track 1")
        let track2 = MockFactory.makeTrack(title: "Track 2")
        
        mockAudioEngine.currentTrack = track1
        mockAudioEngine.queue = [track1, track2]
        mockAudioEngine.state = .playing
        nowPlayingViewModel.updateState()
        
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // When - I click next track from the minimised player
        try await nowPlayingViewModel.playNext()
        
        // Then - The next track should be queued
        XCTAssertTrue(mockAudioEngine.playNextCalled)
    }
    
    // MARK: - BDD Scenario 5: Minimize While No Track Playing
    
    /// BDD: As a user, when I minimize the player with no track playing, then the minimised player should still appear
    func testUserMinimizesWithNoTrackPlaying() {
        // Given - I have the main window open but no track is playing
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.state = .stopped
        nowPlayingViewModel.updateState()
        
        appDelegate.mainWindow?.makeKeyAndOrderFront(nil)
        
        // When - I click the minimize button
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then - The minimised player should still appear
        XCTAssertTrue(appDelegate.isMinimised)
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow)
        XCTAssertTrue(appDelegate.minimisedPlayerWindow?.isVisible ?? false)
    }
    
    // MARK: - BDD Scenario 6: Minimize and Restore Workflow
    
    /// BDD: As a user, when I minimize and restore multiple times, then the app should handle it correctly
    func testUserMinimizesAndRestoresMultipleTimes() {
        // Given - I have the main window open
        appDelegate.mainWindow?.makeKeyAndOrderFront(nil)
        
        // When - I minimize and restore multiple times
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        appDelegate.restoreFromPlayer()
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        appDelegate.restoreFromPlayer()
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then - The app should handle it correctly
        XCTAssertTrue(appDelegate.isMinimised)
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow)
        
        // When - I restore again
        appDelegate.restoreFromPlayer()
        
        // Then - The main window should be shown
        XCTAssertFalse(appDelegate.isMinimised)
        XCTAssertTrue(appDelegate.mainWindow?.isVisible ?? false)
    }
}
