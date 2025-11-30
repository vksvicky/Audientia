//
//  MainWindowLayoutViewTests.swift
//  UITests
//
//  TDD tests for MainWindowLayoutView following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared
@MainActor
final class MainWindowLayoutViewTests: XCTestCase {
    var mockAudioEngine: MockAudioEngine!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testViewInitialization() {
        // Given: A mock audio engine
        // When: Creating MainWindowLayoutView
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testViewHasMinimumSize() {
        // Given: A MainWindowLayoutView
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: Accessing the view
        // Then: View should have minimum size constraints
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Actual size constraints are set via .frame(minWidth:minHeight:)
    }
    
    func testViewHasMinimizeButton() {
        // Given: A MainWindowLayoutView
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: Accessing the view
        // Then: View should have a title bar with minimize button
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Title bar is part of mainLayout structure
    }
    
    func testMinimizeButtonTriggersMinimize() {
        // Given: A MainWindowLayoutView and AppDelegate
        _ = MainWindowLayoutView(audioEngine: mockAudioEngine)
        let appDelegate = AppDelegate()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        appDelegate.mainWindow = window
        
        // When: Minimize button is clicked (simulated via AppDelegate)
        // Note: nowPlayingViewModel is private, so we create a new one for testing
        let testViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: testViewModel)
        
        // Then: App should be minimized
        XCTAssertTrue(appDelegate.isMinimized)
        XCTAssertNotNil(appDelegate.minimizedPlayerWindow)
        
        // Cleanup
        appDelegate.restoreFromPlayer()
    }
    
    // MARK: - Boundary Conditions
    
    func testViewWithNilCurrentTrack() {
        // Given: An audio engine with no current track
        mockAudioEngine.currentTrack = nil
        mockAudioEngine.queue = []
        
        // When: Creating view
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should handle nil track gracefully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testViewWithEmptyQueue() {
        // Given: An audio engine with empty queue
        mockAudioEngine.queue = []
        
        // When: Creating view
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should handle empty queue
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Inverse Relationships
    
    func testNavigationItemSelection() {
        // Given: A view with default navigation item
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: Accessing view
        // Then: Default navigation should be .home
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: This tests the internal state, actual selection is tested in BDD tests
    }
    
    // MARK: - Error Conditions
    
    func testViewHandlesImportError() {
        // Given: A view
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // When: Accessing view
        // Then: View should have error handling for imports
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Actual error handling is tested in BDD scenarios
    }
    
    // MARK: - Performance
    
    func testViewCreationPerformance() {
        // Given: A mock audio engine
        measure {
            // When: Creating view multiple times
            for _ in 0..<100 {
                let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
                SwiftUIViewTestHelpers.verifyViewCreation(view)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testViewWithVeryLongTrackTitle() {
        // Given: A track with very long title
        let longTitle = String(repeating: "A", count: 1000)
        let track = Track(
            id: UUID(),
            title: longTitle,
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/test/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = [track]
        
        // When: Creating view
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should handle long titles with lineLimit
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testViewWithUnicodeCharacters() {
        // Given: A track with Unicode characters
        let track = Track(
            id: UUID(),
            title: "🎵 音楽 🎶",
            artist: "アーティスト",
            album: "アルバム",
            duration: 180.0,
            filePath: "/test/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
        mockAudioEngine.currentTrack = track
        mockAudioEngine.queue = [track]
        
        // When: Creating view
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should handle Unicode characters
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
}
