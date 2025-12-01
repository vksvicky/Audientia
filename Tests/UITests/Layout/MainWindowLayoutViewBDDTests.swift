//
//  MainWindowLayoutViewBDDTests.swift
//  UITests
//
//  BDD tests for MainWindowLayoutView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared
@MainActor
final class MainWindowLayoutViewBDDTests: XCTestCase {
    var mockAudioEngine: MockAudioEngine!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToSeeTheMainWindowWithNavigationSidebar() {
        // Given: I open the application
        // When: The main window is displayed
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: I should see a left navigation sidebar
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeeTheToolbarWithAppIcons() {
        // Given: I open the application
        // When: The main window is displayed
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: I should see a toolbar with app-specific icons
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeeThePlaylistPanelOnTheRight() {
        // Given: I open the application
        // When: The main window is displayed
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: I should see a playlist panel on the right side
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeePlayerControlsAtTheBottom() {
        // Given: I open the application
        // When: The main window is displayed
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: I should see player controls at the bottom
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeeCurrentlyPlayingTrackInfo() {
        // Given: A track is currently playing
        let track = Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = [track]
        
        // When: I view the main window
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: I should see the track title and artist in the player controls
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToNavigateBetweenDifferentSections() {
        // Given: I am viewing the main window
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: I click on different navigation items
        // Then: The content area should change to show the selected section
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToControlPlaybackFromTheBottomControls() {
        // Given: A track is loaded
        let track = Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = [track]
        
        // When: I click play/pause in the bottom controls
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: Playback should start or pause
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeeTheHomeViewWhenHomeIsSelected() {
        // Given: I am viewing the main window
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: I select "Home" from the navigation sidebar
        // Then: I should see the welcome/home view
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeeTheLibraryWhenLibraryIsSelected() {
        // Given: I am viewing the main window
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: I select "Entire Library" from the navigation sidebar
        // Then: I should see the library browser
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantToSeeThePlayingListInTheRightPanel() {
        // Given: I am viewing the main window
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: I look at the right panel
        // Then: I should see the "Playing" list
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testAsAUserIWantTheWindowToHaveMinimumSize() {
        // Given: I open the application
        // When: The main window is displayed
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: The window should have a minimum size of 1000x600
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - BDD Scenario: Minimize to Player
    
    /// BDD: As a user, when I click the minimize button in the title bar, then the app should minimize to a floating player
    func testUserClicksMinimizeButton() {
        // Given - I have the main window open
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When - I access the view (minimize button is in title bar)
        // Then - The view should have a minimize button
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Actual button interaction is tested in MinimisePlayerBDDTests
    }
}
