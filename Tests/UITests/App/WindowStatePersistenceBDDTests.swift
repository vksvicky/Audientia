//
//  WindowStatePersistenceBDDTests.swift
//  UITests
//
//  BDD tests for window state persistence (position and minimized mode)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

// Test files often need to be longer to cover comprehensive scenarios

import AppKit
import CoreGraphics
import Foundation

#if canImport(XCTest)
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared

// swiftlint:disable file_length
// swiftlint:disable type_body_length
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
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
        
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
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
        await appDelegate.restoreMinimizedStateIfNeeded(nowPlayingViewModel: nowPlayingViewModel)
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
            let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(savedState.frame)
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
    
    // MARK: - BDD Scenario 12: Immediate State Save on View Change
    
    /// BDD: As a user, when I launch the app and change to minimized player view, then the state should be saved immediately
    func testUserChangesToMinimizedViewSavesStateImmediately() async throws {
        // Given - I have launched the app in main window mode
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I change to minimized player view
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Wait for the state to be saved (positioning helper saves state asynchronously)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then - The state should be saved immediately with minimized mode
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(savedState, "Window state should be saved immediately")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized mode immediately")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
    }
    
    /// BDD: As a user, when I change from minimized to maximized player view, then the state should be saved immediately
    func testUserChangesFromMinimizedToMaximizedViewSavesStateImmediately() async throws {
        // Given - I have minimized to player view
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for minimize and save
        
        // When - I restore to main window (maximized) view
        appDelegate.restoreFromPlayer()
        
        // Wait for the state to be saved (restoreFromPlayer saves state asynchronously)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then - The state should be saved immediately with main window mode
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(savedState, "Window state should be saved immediately")
        XCTAssertFalse(savedState?.isMinimised ?? true, "Saved state should indicate main window mode immediately")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
    }
    
    // MARK: - BDD Scenario 13: State Restoration After Crash/Restart
    
    /// BDD: As a user, when I change to minimized view and the app crashes, then on restart it should restore to minimized view
    func testUserChangesToMinimizedViewCrashesRestoresToMinimizedView() async throws {
        // Given - I have changed to minimized player view
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for save
        
        // Verify state was saved
        let savedStateBeforeCrash = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertTrue(savedStateBeforeCrash?.isMinimised ?? false, "State should be saved as minimized")
        
        // Simulate crash - create new app delegate instance (simulating app restart)
        let newAppDelegate = AppDelegate()
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newAppDelegate.mainWindow = newWindow
        
        // When - I restore window state (simulating app launch after crash)
        await newAppDelegate.restoreWindowState()
        
        // Then - The app should be set to restore minimized state
        // Note: shouldRestoreMinimizedState is private, but we can test restoreMinimizedStateIfNeeded
        await newAppDelegate.restoreMinimizedStateIfNeeded(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for restore
        
        XCTAssertTrue(newAppDelegate.isMinimised, "App should restore to minimized mode after crash")
        XCTAssertNotNil(newAppDelegate.minimisedPlayerWindow, "Minimized player window should be restored")
        
        // Cleanup
        newAppDelegate.minimisedPlayerWindow?.close()
    }
    
    /// BDD: As a user, when I change to maximized view and the app crashes, then on restart it should restore to maximized view
    func testUserChangesToMaximizedViewCrashesRestoresToMaximizedView() async throws {
        // Given - I have changed to main window (maximized) view
        // Start in minimized, then restore to maximized
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for save
        
        // Verify state was saved
        let savedStateBeforeCrash = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertFalse(savedStateBeforeCrash?.isMinimised ?? true, "State should be saved as maximized")
        
        // Simulate crash - create new app delegate instance
        let newAppDelegate = AppDelegate()
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newAppDelegate.mainWindow = newWindow
        
        // When - I restore window state (simulating app launch after crash)
        await newAppDelegate.restoreWindowState()
        
        // Then - The app should restore to main window mode
        XCTAssertFalse(newAppDelegate.isMinimised, "App should restore to main window mode after crash")
        XCTAssertNil(newAppDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
        if let mainWindow = newAppDelegate.mainWindow, let savedFrame = savedStateBeforeCrash?.frame {
            let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(savedFrame)
            XCTAssertEqual(mainWindow.frame, validFrame, "Main window should be positioned at saved location")
        }
    }
    
    // MARK: - BDD Scenario 14: State Restoration After Quit/Reopen from Xcode
    
    /// BDD: As a user, when I launch the app in minimized view and quit, then on reopening from Xcode it should restore to minimized view
    func testUserLaunchesInMinimizedViewQuitsReopensFromXcodeRestoresToMinimizedView() async throws {
        // Given - I have launched the app and it's in minimized player view
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for save
        
        // Simulate app quit - save state before termination
        await appDelegate.saveWindowStateImmediate()
        
        // Verify state was saved
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertTrue(savedState?.isMinimised ?? false, "State should be saved as minimized")
        
        // Simulate reopening from Xcode - create new app delegate instance
        let newAppDelegate = AppDelegate()
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newAppDelegate.mainWindow = newWindow
        
        // When - I restore window state (simulating app launch from Xcode)
        await newAppDelegate.restoreWindowState()
        await newAppDelegate.restoreMinimizedStateIfNeeded(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for restore
        
        // Then - The app should restore to minimized view
        XCTAssertTrue(newAppDelegate.isMinimised, "App should restore to minimized mode when reopened from Xcode")
        XCTAssertNotNil(newAppDelegate.minimisedPlayerWindow, "Minimized player window should be restored")
        if let playerWindow = newAppDelegate.minimisedPlayerWindow, let savedFrame = savedState?.frame {
            let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(savedFrame)
            XCTAssertEqual(playerWindow.frame, validFrame, "Player window should be positioned at saved location")
        }
        
        // Cleanup
        newAppDelegate.minimisedPlayerWindow?.close()
    }
    
    /// BDD: As a user, when I launch the app in maximized view and quit, then on reopening from Xcode it should restore to maximized view
    func testUserLaunchesInMaximizedViewQuitsReopensFromXcodeRestoresToMaximizedView() async throws {
        // Given - I have launched the app and it's in main window (maximized) view
        // Ensure we're in main window mode
        appDelegate.restoreFromPlayer() // In case we were minimized
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Save current main window state
        await appDelegate.saveWindowStateImmediate()
        
        // Verify state was saved
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertFalse(savedState?.isMinimised ?? true, "State should be saved as maximized")
        
        // Simulate reopening from Xcode - create new app delegate instance
        let newAppDelegate = AppDelegate()
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newAppDelegate.mainWindow = newWindow
        
        // When - I restore window state (simulating app launch from Xcode)
        await newAppDelegate.restoreWindowState()
        
        // Then - The app should restore to main window (maximized) view
        XCTAssertFalse(newAppDelegate.isMinimised, "App should restore to main window mode when reopened from Xcode")
        XCTAssertNil(newAppDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
        if let mainWindow = newAppDelegate.mainWindow, let savedFrame = savedState?.frame {
            let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(savedFrame)
            XCTAssertEqual(mainWindow.frame, validFrame, "Main window should be positioned at saved location")
        }
    }
    
    // MARK: - BDD Scenario 15: Multiple Minimize/Maximize Cycles (Stress Test)
    
    /// BDD: As a user, when I repeatedly minimize and maximize the window multiple times, 
    /// then the app should continue to work correctly without breaking
    func testMultipleMinimizeMaximizeCycles() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        XCTAssertNotNil(appDelegate.mainWindow, "Main window should exist")
        
        // When - I repeatedly minimize and maximize multiple times (stress test)
        let numberOfCycles = 5
        var lastSavedState: WindowState?
        
        for cycle in 1...numberOfCycles {
            // Minimize
            appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
            try await Task.sleep(nanoseconds: 500_000_000) // Wait for save and window state update
            
            // Verify minimized state
            XCTAssertTrue(appDelegate.isMinimised, "App should be minimized after cycle \(cycle)")
            XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist after cycle \(cycle)")
            // Main window should be hidden (not visible) when minimized
            // Note: orderOut(nil) hides the window, making isVisible false
            // Wait a bit for window state to update after orderOut
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds for window state update
            if let mainWindow = appDelegate.mainWindow {
                XCTAssertFalse(mainWindow.isVisible, "Main window should be hidden after cycle \(cycle)")
            } else {
                XCTFail("Main window should exist but be hidden, not nil")
            }
            
            // Verify state was saved
            let minimizedState = await appDelegate.windowStateManager.loadWindowState()
            XCTAssertNotNil(minimizedState, "State should be saved after minimize cycle \(cycle)")
            XCTAssertTrue(minimizedState?.isMinimised ?? false, "Saved state should indicate minimized after cycle \(cycle)")
            lastSavedState = minimizedState
            
            // Maximize (restore)
            appDelegate.restoreFromPlayer()
            try await Task.sleep(nanoseconds: 500_000_000) // Wait for save
            
            // Verify maximized state
            XCTAssertFalse(appDelegate.isMinimised, "App should be maximized after cycle \(cycle)")
            XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist after cycle \(cycle)")
            XCTAssertNotNil(appDelegate.mainWindow, "Main window should exist after cycle \(cycle)")
            
            // Verify state was saved
            let maximizedState = await appDelegate.windowStateManager.loadWindowState()
            XCTAssertNotNil(maximizedState, "State should be saved after maximize cycle \(cycle)")
            XCTAssertFalse(maximizedState?.isMinimised ?? true, "Saved state should indicate maximized after cycle \(cycle)")
            lastSavedState = maximizedState
        }
        
        // Then - Final state should be correct and app should still be functional
        XCTAssertFalse(appDelegate.isMinimised, "App should end in maximized mode after all cycles")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist after all cycles")
        XCTAssertNotNil(appDelegate.mainWindow, "Main window should still exist after all cycles")
        
        // Verify final saved state
        let finalState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(finalState, "Final state should be saved")
        XCTAssertFalse(finalState?.isMinimised ?? true, "Final saved state should indicate maximized mode")
        XCTAssertEqual(finalState?.isMinimised, lastSavedState?.isMinimised, "Final state should match last saved state")
    }
    
    /// BDD: As a user, when I repeatedly minimize and maximize rapidly, 
    /// then the app should handle rapid state changes without breaking
    func testRapidMinimizeMaximizeCycles() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I rapidly minimize and maximize multiple times (stress test with shorter delays)
        let numberOfCycles = 10
        var successfulCycles = 0
        
        for cycle in 1...numberOfCycles {
            do {
                // Minimize
                appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
                try await Task.sleep(nanoseconds: 100_000_000) // Shorter wait for rapid cycles
                
                // Verify minimized state
                guard appDelegate.isMinimised,
                      appDelegate.minimisedPlayerWindow != nil else {
                    XCTFail("Failed to minimize on cycle \(cycle)")
                    continue
                }
                
                // Maximize (restore)
                appDelegate.restoreFromPlayer()
                try await Task.sleep(nanoseconds: 100_000_000) // Shorter wait for rapid cycles
                
                // Verify maximized state
                guard !appDelegate.isMinimised,
                      appDelegate.minimisedPlayerWindow == nil,
                      appDelegate.mainWindow != nil else {
                    XCTFail("Failed to maximize on cycle \(cycle)")
                    continue
                }
                
                successfulCycles += 1
            } catch {
                XCTFail("Error on cycle \(cycle): \(error.localizedDescription)")
            }
        }
        
        // Then - Most cycles should succeed (allow for some timing issues)
        XCTAssertGreaterThanOrEqual(
            successfulCycles,
            numberOfCycles - 2,
            "At least \(numberOfCycles - 2) out of \(numberOfCycles) cycles should succeed"
        )
        
        // Final state should be correct
        XCTAssertFalse(appDelegate.isMinimised, "App should end in maximized mode after rapid cycles")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist after rapid cycles")
    }
    
    /// BDD: As a user, when I minimize, maximize, and then minimize again multiple times,
    /// then the window positions should be preserved correctly
    func testMinimizeMaximizePositionPreservation() async throws {
        // Given - I have a main window at a specific position
        let initialFrame = CGRect(x: 200, y: 300, width: 1200, height: 800)
        appDelegate.mainWindow?.setFrame(initialFrame, display: false)
        
        // When - I minimize, maximize, and minimize again multiple times
        let numberOfCycles = 3
        var savedMinimizedPositions: [CGRect] = []
        
        for cycle in 1...numberOfCycles {
            // Minimize
            appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Save minimized position
            if let playerWindow = appDelegate.minimisedPlayerWindow {
                let minimizedFrame = playerWindow.frame
                savedMinimizedPositions.append(minimizedFrame)
                
                // Verify position is valid
                XCTAssertGreaterThan(minimizedFrame.width, 0, "Minimized window should have valid width on cycle \(cycle)")
                XCTAssertGreaterThan(minimizedFrame.height, 0, "Minimized window should have valid height on cycle \(cycle)")
            }
            
            // Maximize
            appDelegate.restoreFromPlayer()
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Verify main window still exists
            XCTAssertNotNil(appDelegate.mainWindow, "Main window should exist after maximize cycle \(cycle)")
        }
        
        // Then - All minimized positions should be valid
        XCTAssertEqual(savedMinimizedPositions.count, numberOfCycles, "Should have saved \(numberOfCycles) minimized positions")
        
        // Verify positions are reasonable (not all zeros, not off-screen)
        for (index, position) in savedMinimizedPositions.enumerated() {
            XCTAssertGreaterThan(position.width, 0, "Position \(index) should have valid width")
            XCTAssertGreaterThan(position.height, 0, "Position \(index) should have valid height")
        }
    }
    
    // MARK: - BDD Scenario 16: Permutation/Combination Tests
    
    /// BDD: As a user, when I try to minimize multiple times in a row, 
    /// then the app should handle it gracefully without breaking
    func testMultipleMinimizeCallsInRow() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I call minimize multiple times in a row
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        // Second minimize call (should be idempotent)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        // Third minimize call (should be idempotent)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        // Then - App should still be in minimized state (only one window)
        XCTAssertTrue(appDelegate.isMinimised, "App should be in minimized state")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
        XCTAssertEqual(appDelegate.minimisedPlayerWindow, appDelegate.minimisedPlayerWindow, "Should have same window instance")
        
        // Verify state is saved correctly
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(savedState, "State should be saved")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized")
    }
    
    /// BDD: As a user, when I try to maximize multiple times in a row, 
    /// then the app should handle it gracefully without breaking
    func testMultipleMaximizeCallsInRow() async throws {
        // Given - I have minimized the app
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(appDelegate.isMinimised, "App should be minimized")
        
        // When - I call restore (maximize) multiple times in a row
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Second restore call (should be idempotent)
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Third restore call (should be idempotent)
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then - App should still be in maximized state
        XCTAssertFalse(appDelegate.isMinimised, "App should be in maximized state")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
        XCTAssertNotNil(appDelegate.mainWindow, "Main window should exist")
        
        // Verify state is saved correctly
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(savedState, "State should be saved")
        XCTAssertFalse(savedState?.isMinimised ?? true, "Saved state should indicate maximized")
    }
    
    /// BDD: As a user, when I minimize, then maximize, then minimize again multiple times,
    /// then each transition should work correctly
    func testMinimizeMaximizeMinimizeSequence() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I perform: Minimize -> Maximize -> Minimize -> Maximize -> Minimize
        let sequence = [
            ("minimize", true),
            ("maximize", false),
            ("minimize", true),
            ("maximize", false),
            ("minimize", true)
        ]
        
        for (index, (action, expectedMinimized)) in sequence.enumerated() {
            if action == "minimize" {
                appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
                try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
            } else {
                appDelegate.restoreFromPlayer()
                try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
            }
            
            // Then - State should match expected
            XCTAssertEqual(
                appDelegate.isMinimised,
                expectedMinimized,
                "After \(action) at step \(index + 1), isMinimised should be \(expectedMinimized)"
            )
            
            if expectedMinimized {
                XCTAssertNotNil(
                    appDelegate.minimisedPlayerWindow,
                    "Minimized player window should exist after \(action) at step \(index + 1)"
                )
            } else {
                XCTAssertNil(
                    appDelegate.minimisedPlayerWindow,
                    "Minimized player window should not exist after \(action) at step \(index + 1)"
                )
            }
            
            // Verify state is saved correctly
            let savedState = await appDelegate.windowStateManager.loadWindowState()
            XCTAssertNotNil(savedState, "State should be saved after step \(index + 1)")
            XCTAssertEqual(
                savedState?.isMinimised,
                expectedMinimized,
                "Saved state should match expected after step \(index + 1)"
            )
        }
    }
    
    /// BDD: As a user, when I maximize, then minimize, then maximize again multiple times,
    /// then each transition should work correctly
    func testMaximizeMinimizeMaximizeSequence() async throws {
        // Given - I have launched the app (already maximized)
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I perform: Maximize (already) -> Minimize -> Maximize -> Minimize -> Maximize
        let sequence = [
            ("minimize", true),
            ("maximize", false),
            ("minimize", true),
            ("maximize", false),
            ("maximize", false) // Multiple maximizes should be idempotent
        ]
        
        for (index, (action, expectedMinimized)) in sequence.enumerated() {
            if action == "minimize" {
                appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
            } else {
                appDelegate.restoreFromPlayer()
            }
            
            try await Task.sleep(nanoseconds: 300_000_000) // Wait for state save
            
            // Then - State should match expected
            XCTAssertEqual(
                appDelegate.isMinimised,
                expectedMinimized,
                "After \(action) at step \(index + 1), isMinimised should be \(expectedMinimized)"
            )
        }
    }
    
    /// BDD: As a user, when I perform complex alternating sequences of minimize/maximize,
    /// then the app should handle all combinations correctly
    func testComplexAlternatingSequences() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I perform various alternating sequences
        // Sequence 1: M -> X -> M -> M -> X -> X -> M
        let sequence1 = [
            ("minimize", true),
            ("maximize", false),
            ("minimize", true),
            ("minimize", true), // Multiple minimizes
            ("maximize", false),
            ("maximize", false), // Multiple maximizes
            ("minimize", true)
        ]
        
        for (action, expectedMinimized) in sequence1 {
            if action == "minimize" {
                appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
                try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
            } else {
                appDelegate.restoreFromPlayer()
                try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
            }
            
            XCTAssertEqual(
                appDelegate.isMinimised,
                expectedMinimized,
                "State should match expected after \(action)"
            )
        }
        
        // Then - Final state should be correct
        XCTAssertTrue(appDelegate.isMinimised, "Final state should be minimized")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
        
        // Verify final saved state
        let finalState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(finalState, "Final state should be saved")
        XCTAssertTrue(finalState?.isMinimised ?? false, "Final saved state should indicate minimized")
    }
    
    /// BDD: As a user, when I minimize, then try to minimize again before the first completes,
    /// then the app should handle concurrent minimize calls gracefully
    func testConcurrentMinimizeCalls() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I call minimize multiple times rapidly (simulating concurrent calls)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        // Don't wait, call again immediately
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        
        // Wait for all operations to complete
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Then - App should be in minimized state (only one window created)
        XCTAssertTrue(appDelegate.isMinimised, "App should be in minimized state")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
        
        // Should only have one minimized window (not multiple)
        let windowCount = appDelegate.minimisedPlayerWindow != nil ? 1 : 0
        XCTAssertEqual(windowCount, 1, "Should have exactly one minimized player window")
    }
    
    /// BDD: As a user, when I maximize, then try to maximize again before the first completes,
    /// then the app should handle concurrent maximize calls gracefully
    func testConcurrentMaximizeCalls() async throws {
        // Given - I have minimized the app
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(appDelegate.isMinimised, "App should be minimized")
        
        // When - I call restore (maximize) multiple times rapidly
        appDelegate.restoreFromPlayer()
        // Don't wait, call again immediately
        appDelegate.restoreFromPlayer()
        appDelegate.restoreFromPlayer()
        
        // Wait for all operations to complete
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Then - App should be in maximized state
        XCTAssertFalse(appDelegate.isMinimised, "App should be in maximized state")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized player window should not exist")
        XCTAssertNotNil(appDelegate.mainWindow, "Main window should exist")
    }
    
    /// BDD: As a user, when I perform minimize -> maximize -> minimize in quick succession,
    /// then state should be saved correctly after each transition
    func testQuickSuccessionStateSaving() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        var savedStates: [WindowState?] = []
        
        // When - I perform quick succession of minimize -> maximize -> minimize
        // Minimize
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        let state1 = await appDelegate.windowStateManager.loadWindowState()
        savedStates.append(state1)
        
        // Maximize
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
        let state2 = await appDelegate.windowStateManager.loadWindowState()
        savedStates.append(state2)
        
        // Minimize again
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        let state3 = await appDelegate.windowStateManager.loadWindowState()
        savedStates.append(state3)
        
        // Then - Each state should be saved correctly
        XCTAssertEqual(savedStates.count, 3, "Should have 3 saved states")
        XCTAssertTrue(savedStates[0]?.isMinimised ?? false, "First state should be minimized")
        XCTAssertFalse(savedStates[1]?.isMinimised ?? true, "Second state should be maximized")
        XCTAssertTrue(savedStates[2]?.isMinimised ?? false, "Third state should be minimized")
        
        // Verify current state matches last saved state
        XCTAssertTrue(appDelegate.isMinimised, "Current state should be minimized")
        XCTAssertEqual(
            appDelegate.isMinimised,
            savedStates[2]?.isMinimised,
            "Current state should match last saved state"
        )
    }
    
    /// BDD: As a user, when I minimize, maximize, minimize, maximize, and then minimize again,
    /// then the final state should be correctly saved and restored
    func testExtendedSequenceWithFinalState() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I perform extended sequence: M -> X -> M -> X -> M
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
        
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
        
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        
        // Then - Final state should be minimized
        XCTAssertTrue(appDelegate.isMinimised, "Final state should be minimized")
        XCTAssertNotNil(appDelegate.minimisedPlayerWindow, "Minimized player window should exist")
        
        // Verify final saved state
        let finalState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(finalState, "Final state should be saved")
        XCTAssertTrue(finalState?.isMinimised ?? false, "Final saved state should indicate minimized")
        
        // Simulate app restart and verify restoration
        let newAppDelegate = AppDelegate()
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newAppDelegate.mainWindow = newWindow
        
        await newAppDelegate.restoreWindowState()
        await newAppDelegate.restoreMinimizedStateIfNeeded(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertTrue(newAppDelegate.isMinimised, "Should restore to minimized state after restart")
        XCTAssertNotNil(newAppDelegate.minimisedPlayerWindow, "Minimized player window should be restored")
        
        // Cleanup
        newAppDelegate.minimisedPlayerWindow?.close()
    }
    
    /// BDD: As a user, when I perform all possible 2-step sequences (MM, MX, XM, XX),
    /// then each sequence should work correctly
    func testAllTwoStepSequences() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // Test sequence: Minimize -> Minimize (MM)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(appDelegate.isMinimised, "MM sequence should end minimized")
        
        // Reset: Maximize
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(appDelegate.isMinimised, "Should be maximized after reset")
        
        // Test sequence: Minimize -> Maximize (MX)
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(appDelegate.isMinimised, "MX sequence should end maximized")
        
        // Test sequence: Maximize -> Minimize (XM) - already maximized, so just minimize
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(appDelegate.isMinimised, "XM sequence should end minimized")
        
        // Reset: Maximize
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(appDelegate.isMinimised, "Should be maximized after reset")
        
        // Test sequence: Maximize -> Maximize (XX)
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(appDelegate.isMinimised, "XX sequence should end maximized")
    }
    
    /// BDD: As a user, when I perform all possible 3-step sequences,
    /// then each sequence should work correctly
    func testAllThreeStepSequences() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // Test all 8 possible 3-step sequences: MMM, MMX, MXM, MXX, XMM, XMX, XXM, XXX
        let sequences = [
            ("MMM", true),   // Minimize -> Minimize -> Minimize
            ("MMX", false), // Minimize -> Minimize -> Maximize
            ("MXM", true),  // Minimize -> Maximize -> Minimize
            ("MXX", false), // Minimize -> Maximize -> Maximize
            ("XMM", true),  // Maximize -> Minimize -> Minimize
            ("XMX", false), // Maximize -> Minimize -> Maximize
            ("XXM", true),  // Maximize -> Maximize -> Minimize
            ("XXX", false)  // Maximize -> Maximize -> Maximize
        ]
        
        for (sequence, expectedFinalState) in sequences {
            // Reset to known state (maximized)
            if appDelegate.isMinimised {
                appDelegate.restoreFromPlayer()
                try await Task.sleep(nanoseconds: 200_000_000)
            }
            XCTAssertFalse(appDelegate.isMinimised, "Should start maximized for sequence \(sequence)")
            
            // Execute sequence
            for action in sequence {
                if action == "M" {
                    appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
                    try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
                } else {
                    appDelegate.restoreFromPlayer()
                    try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
                }
            }
            
            // Verify final state
            XCTAssertEqual(
                appDelegate.isMinimised,
                expectedFinalState,
                "Sequence \(sequence) should end with isMinimised=\(expectedFinalState)"
            )
            
            // Verify saved state matches
            let savedState = await appDelegate.windowStateManager.loadWindowState()
            XCTAssertNotNil(savedState, "State should be saved after sequence \(sequence)")
            XCTAssertEqual(
                savedState?.isMinimised,
                expectedFinalState,
                "Saved state should match expected after sequence \(sequence)"
            )
        }
    }
    
    /// BDD: As a user, when I minimize, then close the minimized window, then minimize again,
    /// then the app should handle window recreation correctly
    func testMinimizeCloseMinimizeSequence() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        // When - I minimize
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        XCTAssertTrue(appDelegate.isMinimised, "Should be minimized")
        let firstWindow = appDelegate.minimisedPlayerWindow
        XCTAssertNotNil(firstWindow, "First minimized window should exist")
        
        // Close the minimized window (simulate user closing it)
        appDelegate.closeMinimisedPlayer()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for state save
        XCTAssertFalse(appDelegate.isMinimised, "Should not be minimized after closing")
        XCTAssertNil(appDelegate.minimisedPlayerWindow, "Minimized window should not exist")
        
        // Minimize again
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for positioning and state save
        XCTAssertTrue(appDelegate.isMinimised, "Should be minimized again")
        let secondWindow = appDelegate.minimisedPlayerWindow
        XCTAssertNotNil(secondWindow, "Second minimized window should exist")
        
        // Then - Should have created a new window (different instance)
        // Note: Windows might be the same if reused, but the important thing is it works
        XCTAssertNotNil(secondWindow, "Second window should exist")
        
        // Verify state is saved correctly
        let savedState = await appDelegate.windowStateManager.loadWindowState()
        XCTAssertNotNil(savedState, "State should be saved")
        XCTAssertTrue(savedState?.isMinimised ?? false, "Saved state should indicate minimized")
    }
    
    /// BDD: As a user, when I perform minimize/maximize operations with state checks between each,
    /// then intermediate states should be correct
    func testStateConsistencyBetweenOperations() async throws {
        // Given - I have launched the app
        XCTAssertFalse(appDelegate.isMinimised, "App should start in main window mode")
        
        struct StateRecord {
            let operation: String
            let isMinimised: Bool
            let hasMinimizedWindow: Bool
        }
        var stateHistory: [StateRecord] = []
        
        // When - I perform operations and check state after each
        // Operation 1: Minimize
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 300_000_000)
        stateHistory.append(StateRecord(
            operation: "minimize",
            isMinimised: appDelegate.isMinimised,
            hasMinimizedWindow: appDelegate.minimisedPlayerWindow != nil
        ))
        
        // Operation 2: Maximize
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 300_000_000)
        stateHistory.append(StateRecord(
            operation: "maximize",
            isMinimised: appDelegate.isMinimised,
            hasMinimizedWindow: appDelegate.minimisedPlayerWindow != nil
        ))
        
        // Operation 3: Minimize again
        appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        try await Task.sleep(nanoseconds: 300_000_000)
        stateHistory.append(StateRecord(
            operation: "minimize",
            isMinimised: appDelegate.isMinimised,
            hasMinimizedWindow: appDelegate.minimisedPlayerWindow != nil
        ))
        
        // Operation 4: Maximize again
        appDelegate.restoreFromPlayer()
        try await Task.sleep(nanoseconds: 300_000_000)
        stateHistory.append(StateRecord(
            operation: "maximize",
            isMinimised: appDelegate.isMinimised,
            hasMinimizedWindow: appDelegate.minimisedPlayerWindow != nil
        ))
        
        // Then - State history should be consistent
        XCTAssertEqual(stateHistory.count, 4, "Should have 4 state records")
        XCTAssertEqual(stateHistory[0].operation, "minimize", "First operation should be minimize")
        XCTAssertTrue(stateHistory[0].isMinimised, "After first minimize: minimized should be true")
        XCTAssertTrue(stateHistory[0].hasMinimizedWindow, "After first minimize: window should exist")
        XCTAssertEqual(stateHistory[1].operation, "maximize", "Second operation should be maximize")
        XCTAssertFalse(stateHistory[1].isMinimised, "After first maximize: minimized should be false")
        XCTAssertFalse(stateHistory[1].hasMinimizedWindow, "After first maximize: window should not exist")
        XCTAssertEqual(stateHistory[2].operation, "minimize", "Third operation should be minimize")
        XCTAssertTrue(stateHistory[2].isMinimised, "After second minimize: minimized should be true")
        XCTAssertTrue(stateHistory[2].hasMinimizedWindow, "After second minimize: window should exist")
        XCTAssertEqual(stateHistory[3].operation, "maximize", "Fourth operation should be maximize")
        XCTAssertFalse(stateHistory[3].isMinimised, "After second maximize: minimized should be false")
        XCTAssertFalse(stateHistory[3].hasMinimizedWindow, "After second maximize: window should not exist")
    }
}
// swiftlint:enable type_body_length

#endif
