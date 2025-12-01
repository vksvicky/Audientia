//
//  MinimisePlayerTests.swift
//  UITests
//
//  TDD tests for minimize-to-player functionality in AppDelegate following Right-BICEP principles
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
final class MinimisePlayerTests: XCTestCase {
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
        // Clean up any minimised windows
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
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    func testMinimizeToPlayerCreatesWindow() {
        // Given: AppDelegate with main window and not minimised
        XCTAssertFalse(appDelegate.isMinimised)
        
        // When: Minimizing to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Minimised player window should be created
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow)
        XCTAssertTrue(appDelegate.isMinimised)
    }
    
    func testMinimizeToPlayerHidesMainWindow() {
        // Given: Main window is visible
        appDelegate.mainWindow?.makeKeyAndOrderFront(nil)
        XCTAssertTrue(appDelegate.mainWindow?.isVisible ?? false)
        
        // When: Minimizing to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Main window should be hidden
        XCTAssertFalse(appDelegate.mainWindow?.isVisible ?? true)
    }
    
    func testRestoreFromPlayerShowsMainWindow() {
        // Given: App is minimised to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        XCTAssertTrue(appDelegate.isMinimised)
        
        // When: Restoring from player
        appDelegate.restoreFromPlayer()
        
        // Then: Main window should be shown and minimised window closed
        XCTAssertFalse(appDelegate.isMinimised)
        XCTAssertNil(appDelegate.minimisedPlayerWindow)
    }
    
    func testRestoreFromPlayerClosesMinimisedWindow() {
        // Given: App is minimised to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        let minimisedWindow = appDelegate.minimisedPlayerWindow
        XCTAssertNotNil(minimisedWindow)
        XCTAssertTrue(minimisedWindow?.isVisible ?? false)
        
        // When: Restoring from player
        appDelegate.restoreFromPlayer()
        
        // Then: Minimised window should be closed
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "minimisedPlayerWindow property should be nil after restore")
        // The window object itself may still exist in memory (just closed), so check it's closed instead
        XCTAssertFalse(minimisedWindow?.isVisible ?? true, "Minimised window should be closed after restore")
    }
    
    // MARK: - Right-[B]ICEP - Boundary Conditions
    
    func testMinimizeToPlayerWhenAlreadyMinimised() {
        // Given: App is already minimised
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        let firstWindow = appDelegate.minimisedPlayerWindow
        
        // When: Attempting to minimize again
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Should not create duplicate window
        XCTAssertEqual(appDelegate.minimisedPlayerWindow, firstWindow)
    }
    
    func testRestoreFromPlayerWhenNotMinimised() {
        // Given: App is not minimised
        appDelegate.isMinimised = false
        
        // When: Attempting to restore
        appDelegate.restoreFromPlayer()
        
        // Then: Should handle gracefully without error
        XCTAssertFalse(appDelegate.isMinimised)
    }
    
    func testMinimizeToPlayerWithNilMainWindow() {
        // Given: Main window is nil
        appDelegate.mainWindow = nil
        
        // When: Minimizing to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Should still create minimised window
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow)
        XCTAssertTrue(appDelegate.isMinimised)
    }
    
    // MARK: - Right-BIC[E]P - Forcing Error Conditions
    
    func testMinimizeToPlayerMultipleTimes() {
        // Given: AppDelegate
        // When: Minimizing multiple times
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        appDelegate.restoreFromPlayer()
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        appDelegate.restoreFromPlayer()
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Should handle multiple minimize/restore cycles
        XCTAssertTrue(appDelegate.isMinimised)
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow)
    }
    
    func testRestoreFromPlayerMultipleTimes() {
        // Given: App is minimised
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // When: Restoring multiple times
        appDelegate.restoreFromPlayer()
        appDelegate.restoreFromPlayer()
        appDelegate.restoreFromPlayer()
        
        // Then: Should handle gracefully
        XCTAssertFalse(appDelegate.isMinimised)
        XCTAssertNil(appDelegate.minimisedPlayerWindow)
    }
    
    // MARK: - Right-BICE[P] - Performance Characteristics
    
    func testMinimizeToPlayerPerformance() {
        // Given: AppDelegate
        measure {
            // When: Minimizing to player
            appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
            appDelegate.restoreFromPlayer()
        }
    }
    
    // MARK: - Window Configuration
    
    func testMinimisedWindowHasCorrectProperties() {
        // Given: AppDelegate
        // When: Minimizing to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Window should have correct properties
        let window = appDelegate.minimisedPlayerWindow
        XCTAssertNotNil(window)
        XCTAssertEqual(window?.frame.width, 400)
        XCTAssertEqual(window?.frame.height, 80)
        XCTAssertEqual(window?.level, .floating)
        XCTAssertTrue(window?.isMovableByWindowBackground ?? false)
    }
    
    func testMinimisedWindowIsPositionedCorrectly() {
        // Given: AppDelegate with main window positioned
        appDelegate.mainWindow?.setFrameOrigin(NSPoint(x: 100, y: 100))
        let mainWindowFrame = appDelegate.mainWindow?.frame ?? NSRect.zero
        
        // When: Minimizing to player
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Then: Window should be positioned (centered relative to main window or screen)
        let window = appDelegate.minimisedPlayerWindow
        XCTAssertNotNil(window)
        
        if let screen = NSScreen.main, let window = window {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 400
            let windowHeight: CGFloat = 80
            
            // Implementation centers the window relative to main window position or screen center
            let expectedX: CGFloat
            let expectedY: CGFloat
            
            if mainWindowFrame != NSRect.zero {
                // Centered relative to where the main window was
                expectedX = mainWindowFrame.midX - windowWidth / 2
                expectedY = mainWindowFrame.midY - windowHeight / 2
            } else {
                // Centered on screen
                expectedX = screenRect.midX - windowWidth / 2
                expectedY = screenRect.midY - windowHeight / 2
            }
            
            XCTAssertEqual(window.frame.origin.x, expectedX, accuracy: 1.0, "Window X position should be centered")
            XCTAssertEqual(window.frame.origin.y, expectedY, accuracy: 1.0, "Window Y position should be centered")
        }
    }
}
