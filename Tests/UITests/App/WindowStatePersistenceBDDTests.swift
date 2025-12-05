//
//  WindowStatePersistenceBDDTests.swift
//  UITests
//
//  BDD tests for window state persistence (position and minimized mode)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import CoreGraphics
import Foundation

#if canImport(XCTest)
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared

@MainActor
final class WindowStatePersistenceBDDTests: XCTestCase {
    var appDelegate: AppDelegate!
    var mockAudioEngine: MockAudioEngine!
    var nowPlayingViewModel: NowPlayingViewModel!
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        appDelegate = AppDelegate()
        
        // Setup main window reference
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
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
    
    // MARK: - BDD Scenario 1: Minimize and Restore State
    
    /// BDD: As a user, when I minimize to player and restart the app, then it should restore to minimized mode
    func testUserMinimizesAndRestoresToMinimizedModeOnRestart() async throws {
        // Given - I have minimized the app to player mode
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Wait for the save to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Simulate app termination - save state
        await appDelegate.saveWindowStateImmediate()
        
        // When - I restart the app and restore window state
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        
        // Then - The saved state should indicate minimized mode
        XCTAssertNotNil(savedState, "Window state should be saved")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized mode")
        XCTAssertNotNil(savedState?.frame, "Saved state should include window frame")
    }
    
    // MARK: - BDD Scenario 2: Restore and Save Main Window State
    
    /// BDD: As a user, when I restore from minimized mode and restart the app, then it should restore to main window mode
    func testUserRestoresAndSavesMainWindowState() async throws {
        // Given - I have minimized the app and then restored it
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for minimize to complete
        
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for restore and save to complete
        
        // When - I check the saved state
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        
        // Then - The saved state should indicate main window mode
        XCTAssertNotNil(savedState, "Window state should be saved")
        XCTAssertFalse(savedState?.isMinimised ?? true, "Saved state should indicate main window mode")
        if let mainWindow = appDelegate.mainWindow {
            XCTAssertEqual(savedState?.frame, mainWindow.frame, "Saved frame should match main window frame")
        }
    }
    
    // MARK: - BDD Scenario 3: Window Position Persistence
    
    /// BDD: As a user, when I move the main window and restart the app, then it should restore to the same position
    func testUserMovesWindowAndRestoresPosition() async throws {
        // Given - I have moved the main window to a specific position
        let targetFrame = CGRect(x: 200, y: 300, width: 1200, height: 800)
        appDelegate.mainWindow?.setFrame(targetFrame, display: false)
        
        // When - I save the window state and restore it
        await appDelegate.saveWindowStateImmediate()
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        
        // Then - The saved position should match the window position
        XCTAssertNotNil(savedState, "Window state should be saved")
        XCTAssertEqual(savedState?.frame, targetFrame, "Saved frame should match window position")
    }
    
    // MARK: - BDD Scenario 4: Minimized Player Position Persistence
    
    /// BDD: As a user, when I move the minimized player window and restart the app, then it should restore to the same position
    func testUserMovesMinimizedPlayerAndRestoresPosition() async throws {
        // Given - I have minimized to player and moved the player window
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for window creation and positioning
        
        let targetFrame = CGRect(x: 500, y: 600, width: 400, height: 80)
        appDelegate.minimisedPlayerWindow?.setFrame(targetFrame, display: false)
        
        // When - I save the window state
        await appDelegate.saveWindowStateImmediate()
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        
        // Then - The saved position should match the player window position
        XCTAssertNotNil(savedState, "Window state should be saved")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized mode")
        XCTAssertEqual(savedState?.frame, targetFrame, "Saved frame should match player window position")
    }
    
    // MARK: - BDD Scenario 5: Multiple Minimize/Restore Cycles
    
    /// BDD: As a user, when I minimize, restore, and minimize again, then the final state should be saved correctly
    func testUserMinimizesRestoresAndMinimizesAgain() async throws {
        // Given - I have minimized, restored, and minimized again
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for positioning and save
        
        // When - I check the saved state
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        
        // Then - The saved state should indicate minimized mode (the final state)
        XCTAssertNotNil(savedState, "Window state should be saved")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized mode (final state)")
    }
    
    // MARK: - BDD Scenario 6: Save State on App Termination
    
    /// BDD: As a user, when I close the app in minimized mode, then the state should be saved before termination
    func testUserClosesAppInMinimizedModeSavesState() async throws {
        // Given - I have minimized to player mode
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // When - I simulate app termination (save state)
        await appDelegate.saveWindowStateImmediate()
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        
        // Then - The state should be saved with minimized mode
        XCTAssertNotNil(savedState, "Window state should be saved on termination")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized mode")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
        if let playerWindow = appDelegate.minimisedPlayerWindow {
            XCTAssertEqual(savedState?.frame, playerWindow.frame, "Saved frame should match player window")
        }
    }
    
    // MARK: - BDD Scenario 7: Save State on Minimized Window Close
    
    /// BDD: As a user, when I close the minimized player window, then the state should be saved before closing
    func testUserClosesMinimizedPlayerWindowSavesState() async throws {
        // Given - I have minimized to player mode
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let playerWindowFrame = appDelegate.minimisedPlayerWindow?.frame ?? CGRect.zero
        
        // When - I close the minimized player window (simulate windowShouldClose)
        await appDelegate.saveWindowStateImmediate()
        appDelegate.closeMinimisedPlayer()
        
        // Then - The state should have been saved before closing
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(savedState, "Window state should be saved before closing")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized mode")
        XCTAssertEqual(savedState?.frame, playerWindowFrame, "Saved frame should match player window frame")
    }
    
    // MARK: - BDD Scenario 8: Restore State on App Launch
    
    /// BDD: As a user, when I launch the app with a saved minimized state, then it should restore to minimized mode
    func testUserLaunchesAppWithSavedMinimizedState() async throws {
        // Given - I have a saved minimized state
        let savedState = WindowState(
            frame: CGRect(x: 500, y: 600, width: 400, height: 80),
            isMaximized: false,
            isMinimised: true
        )
        try await appDelegate.windowStateManager.saveWindowState(savedState)
        
        // When - I restore the window state
        await appDelegate.restoreWindowState()
        
        // Then - The app should be set to restore minimized state
        // Note: We can't directly test shouldRestoreMinimizedState as it's private,
        // but we can test that restoreMinimizedStateIfNeeded works
        appDelegate.restoreMinimizedStateIfNeeded(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertTrue(appDelegate.isMinimised, "App should be in minimized mode")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
    }
    
    // MARK: - BDD Scenario 9: Restore State on App Launch (Main Window)
    
    /// BDD: As a user, when I launch the app with a saved main window state, then it should restore to main window mode
    func testUserLaunchesAppWithSavedMainWindowState() async throws {
        // Given - I have a saved main window state
        let savedState = WindowState(
            frame: CGRect(x: 200, y: 300, width: 1200, height: 800),
            isMaximized: false,
            isMinimised: false
        )
        try await appDelegate.windowStateManager.saveWindowState(savedState)
        
        // When - I restore the window state
        await appDelegate.restoreWindowState()
        
        // Then - The main window should be positioned correctly
        XCTAssertFalse(appDelegate.isMinimised, "App should be in main window mode")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
        if let mainWindow = appDelegate.mainWindow {
            let validFrame = appDelegate.ensureFrameOnScreen(savedState.frame)
            XCTAssertEqual(mainWindow.frame, validFrame, "Main window should be positioned at saved location")
        }
    }
    
    // MARK: - BDD Scenario 10: No Saved State (First Launch)
    
    /// BDD: As a user, when I launch the app for the first time, then it should use default window settings
    func testUserLaunchesAppForFirstTime() async throws {
        // Given - There is no saved window state
        try await appDelegate.windowStateManager.clearWindowState()
        
        // When - I restore the window state
        await appDelegate.restoreWindowState()
        
        // Then - The app should use default settings (no minimized state)
        XCTAssertFalse(appDelegate.isMinimised, "App should not be in minimized mode on first launch")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
    }
    
    // MARK: - BDD Scenario 11: Frame Validation (Off-Screen)
    
    /// BDD: As a user, when I have a saved window position that's off-screen, then it should be adjusted to a valid position
    func testUserHasOffScreenWindowPositionGetsAdjusted() async throws {
        // Given - I have a saved state with an off-screen position
        let offScreenFrame = CGRect(x: 10000, y: 10000, width: 1200, height: 800)
        let savedState = WindowState(
            frame: offScreenFrame,
            isMaximized: false,
            isMinimised: false
        )
        try await appDelegate.windowStateManager.saveWindowState(savedState)
        
        // When - I restore the window state
        await appDelegate.restoreWindowState()
        
        // Then - The window should be positioned on a valid screen
        if let mainWindow = appDelegate.mainWindow {
            let restoredFrame = mainWindow.frame
            // Frame should be adjusted to be on screen
            let screens = NSScreen.screens
            let isOnScreen = screens.contains { screen in
                screen.frame.intersects(restoredFrame)
            }
            XCTAssertTrue(isOnScreen, "Window should be positioned on a valid screen")
        }
    }
}

#endif
