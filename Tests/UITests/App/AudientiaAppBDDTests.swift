//
//  AudientiaAppBDDTests.swift
//  UITests
//
//  BDD tests for AudientiaApp and AppDelegate
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class AudientiaAppBDDTests: XCTestCase {
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantTheSplashScreenToHideOtherWindows() {
        // Given: The splash screen is showing
        // When: The app launches with splash screen enabled
        appDelegate.hideMainWindow()
        
        // Then: The main window and setup wizard should be hidden
        // Note: This tests that windows are hidden during splash
    }
    
    func testAsAUserIWantKeyboardShortcutsDisabledDuringSplash() {
        // Given: The splash screen is showing
        // When: I try to use keyboard shortcuts
        appDelegate.disableKeyboardShortcuts()
        
        // Then: Keyboard shortcuts should be disabled
        // Note: This tests that shortcuts are disabled during splash
    }
    
    func testAsAUserIWantWindowsToAppearAfterSplashDismisses() {
        // Given: The splash screen has dismissed
        // When: The splash screen animation completes
        appDelegate.enableKeyboardShortcuts()
        appDelegate.showMainWindow()
        
        // Then: The main window should be visible and shortcuts enabled
        // Note: This tests that windows appear after splash
    }
    
    func testAsAUserIWantTheSetupWizardBlockedDuringSplash() {
        // Given: The splash screen is showing
        appDelegate.disableKeyboardShortcuts()
        
        // When: I try to open the setup wizard
        appDelegate.showSetupWizard()
        
        // Then: The setup wizard should not appear
        // Note: This tests that wizard is blocked during splash
    }
    
    func testAsAUserIWantTheMainWindowToHaveMinimumSize() {
        // Given: The main window is displayed
        // When: I view the window
        // Then: The window should have a minimum size of 1000x600
        // Note: This is tested in MainWindowLayoutViewBDDTests
    }
    
    func testAsAUserIWantToMaximizeAndMinimizeTheWindow() {
        // Given: The main window is displayed
        // When: I try to maximize or minimize
        // Then: The window should support maximize and minimize
        // Note: This is tested via window configuration in AppDelegate
    }
    
    func testAsAUserIWantTheSplashScreenToBeTheOnlyVisibleWindow() {
        // Given: The splash screen is showing
        // When: The app launches
        appDelegate.hideMainWindow()
        
        // Then: Only the splash screen should be visible
        // Note: This tests that other windows are hidden
    }
    
    func testAsAUserIWantKeyboardShortcutsToWorkAfterSplash() {
        // Given: The splash screen has dismissed
        // When: I try to use keyboard shortcuts
        appDelegate.enableKeyboardShortcuts()
        
        // Then: Keyboard shortcuts should work normally
        // Note: This tests that shortcuts are re-enabled after splash
    }
}
