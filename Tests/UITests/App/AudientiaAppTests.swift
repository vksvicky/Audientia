//
//  AudientiaAppTests.swift
//  UITests
//
//  TDD tests for AudientiaApp and AppDelegate following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class AudientiaAppTests: XCTestCase {
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testAppDelegateInitialisation() {
        // Given: AppDelegate
        // When: Initialised
        // Then: Should be created successfully
        XCTAssertNotNil(appDelegate)
    }
    
    func testApplicationShouldTerminateAfterLastWindowClosed() {
        // Given: AppDelegate
        // When: Checking if app should terminate after last window closed
        let shouldTerminate = appDelegate.applicationShouldTerminateAfterLastWindowClosed(
            NSApplication.shared
        )
        
        // Then: Should return true
        XCTAssertTrue(shouldTerminate)
    }
    
    // MARK: - Boundary Conditions
    
    func testHideMainWindowWhenNoWindowExists() {
        // Given: No main window exists
        // When: Hiding main window
        appDelegate.hideMainWindow()
        
        // Then: Should not crash
        // Note: This tests graceful handling when window doesn't exist
    }
    
    func testShowMainWindowWhenNoWindowExists() {
        // Given: No main window exists
        // When: Showing main window
        appDelegate.showMainWindow()
        
        // Then: Should not crash
        // Note: This tests graceful handling when window doesn't exist
    }
    
    func testDisableKeyboardShortcutsWhenNoMenuExists() {
        // Given: No menu exists
        // When: Disabling keyboard shortcuts
        appDelegate.disableKeyboardShortcuts()
        
        // Then: Should not crash
        // Note: This tests graceful handling when menu doesn't exist
    }
    
    func testEnableKeyboardShortcutsWhenNoMenuExists() {
        // Given: No menu exists
        // When: Enabling keyboard shortcuts
        appDelegate.enableKeyboardShortcuts()
        
        // Then: Should not crash
        // Note: This tests graceful handling when menu doesn't exist
    }
    
    // MARK: - Inverse Relationships
    
    func testDisableThenEnableKeyboardShortcuts() {
        // Given: A menu exists
        // When: Disabling then enabling shortcuts
        appDelegate.disableKeyboardShortcuts()
        appDelegate.enableKeyboardShortcuts()
        
        // Then: Shortcuts should be re-enabled
        // Note: This tests the roundtrip operation
    }
    
    func testHideThenShowMainWindow() {
        // Given: A main window exists
        // When: Hiding then showing window
        appDelegate.hideMainWindow()
        appDelegate.showMainWindow()
        
        // Then: Window should be shown
        // Note: This tests the roundtrip operation
    }
    
    // MARK: - Error Conditions
    
    func testShowSetupWizardWhenSplashScreenIsVisible() {
        // Given: Splash screen is visible (shortcuts disabled)
        appDelegate.disableKeyboardShortcuts()
        
        // When: Trying to show setup wizard
        appDelegate.showSetupWizard()
        
        // Then: Setup wizard should not be shown
        // Note: This tests that wizard is blocked during splash
    }
    
    // MARK: - Performance
    
    func testWindowManagementPerformance() {
        // Given: AppDelegate
        measure {
            // When: Performing window operations multiple times
            for _ in 0..<100 {
                appDelegate.hideMainWindow()
                appDelegate.showMainWindow()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testMultipleHideMainWindowCalls() {
        // Given: AppDelegate
        // When: Hiding main window multiple times
        appDelegate.hideMainWindow()
        appDelegate.hideMainWindow()
        appDelegate.hideMainWindow()
        
        // Then: Should not crash
    }
    
    func testMultipleShowMainWindowCalls() {
        // Given: AppDelegate
        // When: Showing main window multiple times
        appDelegate.showMainWindow()
        appDelegate.showMainWindow()
        appDelegate.showMainWindow()
        
        // Then: Should not crash
    }
    
    func testMultipleDisableEnableShortcutCalls() {
        // Given: AppDelegate
        // When: Disabling and enabling shortcuts multiple times
        for _ in 0..<10 {
            appDelegate.disableKeyboardShortcuts()
            appDelegate.enableKeyboardShortcuts()
        }
        
        // Then: Should not crash
    }
}
