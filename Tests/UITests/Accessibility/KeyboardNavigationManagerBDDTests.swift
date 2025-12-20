//
//  KeyboardNavigationManagerBDDTests.swift
//  UITests
//
//  BDD tests for KeyboardNavigationManager
//  User scenario tests for keyboard navigation workflows
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// BDD tests for KeyboardNavigationManager
/// Tests user scenarios for keyboard navigation
@MainActor
final class KeyboardNavigationManagerBDDTests: XCTestCase {
    
    private var manager: KeyboardNavigationManager!
    
    override func setUp() {
        super.setUp()
        manager = KeyboardNavigationManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Basic Tab Navigation
    
    /// BDD: As a keyboard-only user, when I press Tab,
    /// then focus should move from toolbar to sidebar to content to player
    func testScenario_KeyboardUserNavigatesWithTabKey() {
        // Given: I am a keyboard-only user
        // And: Focus is on the first toolbar tab
        let initialFocus = KeyboardNavigationElement.toolbarTab(.home)
        manager.setFocus(to: initialFocus)
        
        // When: I press Tab repeatedly (enough times to move through multiple sections)
        var focuses: [KeyboardNavigationElement] = [initialFocus]
        for _ in 0 ..< 10 { // Press Tab 10 times to ensure we move through multiple sections
            if let nextFocus = manager.moveFocusForward() {
                focuses.append(nextFocus)
            }
        }
        
        // Then: Focus should move through elements
        XCTAssertGreaterThan(focuses.count, 1, "Tab navigation should move focus")
        
        // And: Each focus should be different from the previous
        for i in 1 ..< focuses.count {
            XCTAssertNotEqual(
                focuses[i - 1],
                focuses[i],
                "Tab press \(i) should move to different element"
            )
        }
        
        // And: Focus should eventually move through multiple sections
        // (Note: May move through multiple elements in same section first, e.g., all toolbar tabs)
        let allSections = Set(focuses.map { $0.section })
        XCTAssertGreaterThan(allSections.count, 1, "Focus should move through multiple sections after multiple Tab presses")
    }
    
    /// BDD: As a keyboard-only user, when I press Shift+Tab,
    /// then focus should move backward through the navigation order
    func testScenario_KeyboardUserNavigatesBackwardWithShiftTab() {
        // Given: I am a keyboard-only user
        // And: Focus is on a player control
        let initialFocus = KeyboardNavigationElement.playerPlayPause
        manager.setFocus(to: initialFocus)
        
        // When: I press Shift+Tab
        let previousFocus = manager.moveFocusBackward()
        
        // Then: Focus should move to the previous element
        XCTAssertNotNil(previousFocus, "Shift+Tab should move focus backward")
        
        // And: Focus should be different from the initial focus
        if let previousFocus = previousFocus {
            XCTAssertNotEqual(
                previousFocus,
                initialFocus,
                "Shift+Tab should move to a different element"
            )
            
            // And: Current focus should be updated
            XCTAssertEqual(
                manager.currentFocus,
                previousFocus,
                "Current focus should be updated to previous element"
            )
        }
    }
    
    // MARK: - BDD Scenario 2: Focus Wrapping
    
    /// BDD: As a keyboard-only user, when I press Tab from the last element,
    /// then focus should wrap to the first element
    func testScenario_KeyboardUserWrapsFromLastToFirst() {
        // Given: I am a keyboard-only user
        // And: Focus is on the last element (player collapse)
        manager.setFocus(to: .playerCollapse)
        
        // When: I press Tab
        let nextFocus = manager.moveFocusForward()
        
        // Then: Focus should wrap to the first element
        XCTAssertNotNil(nextFocus, "Tab from last element should wrap to first")
        
        // And: Focus should be in the toolbar section
        if let nextFocus = nextFocus {
            XCTAssertEqual(
                nextFocus.section,
                KeyboardNavigationSection.toolbar,
                "Focus should wrap to toolbar section"
            )
        }
    }
    
    /// BDD: As a keyboard-only user, when I press Shift+Tab from the first element,
    /// then focus should wrap to the last element
    func testScenario_KeyboardUserWrapsFromFirstToLast() {
        // Given: I am a keyboard-only user
        // And: Focus is on the first element (home tab)
        manager.setFocus(to: .toolbarTab(.home))
        
        // When: I press Shift+Tab
        let previousFocus = manager.moveFocusBackward()
        
        // Then: Focus should wrap to the last element
        XCTAssertNotNil(previousFocus, "Shift+Tab from first element should wrap to last")
        
        // And: Focus should be in the player section
        if let previousFocus = previousFocus {
            XCTAssertEqual(
                previousFocus.section,
                KeyboardNavigationSection.player,
                "Focus should wrap to player section"
            )
        }
    }
    
    // MARK: - BDD Scenario 3: Section Navigation
    
    /// BDD: As a keyboard-only user, when I want to jump to a specific section,
    /// then I can move focus directly to that section
    func testScenario_KeyboardUserJumpsToSection() {
        // Given: I am a keyboard-only user
        // And: Focus is on the toolbar
        manager.setFocus(to: .toolbarTab(.home))
        
        // When: I want to jump to the player section
        let playerFocus = manager.moveFocusToSection(.player)
        
        // Then: Focus should move to the player section
        XCTAssertNotNil(playerFocus, "Should be able to jump to player section")
        
        // And: Focus should be on a player element
        if let playerFocus = playerFocus {
            XCTAssertEqual(
                playerFocus.section,
                KeyboardNavigationSection.player,
                "Focus should be in player section"
            )
        }
    }
    
    // MARK: - BDD Scenario 4: Focus Roundtrip
    
    /// BDD: As a keyboard-only user, when I navigate forward then backward,
    /// then I should return to my original position
    func testScenario_KeyboardUserReturnsToOriginalPosition() {
        // Given: I am a keyboard-only user
        // And: Focus is on the library tab
        let initialFocus = KeyboardNavigationElement.toolbarTab(.library)
        manager.setFocus(to: initialFocus)
        
        // When: I press Tab three times, then Shift+Tab three times
        _ = manager.moveFocusForward()
        _ = manager.moveFocusForward()
        _ = manager.moveFocusForward()
        _ = manager.moveFocusBackward()
        _ = manager.moveFocusBackward()
        let finalFocus = manager.moveFocusBackward()
        
        // Then: Focus should return to the library tab
        XCTAssertEqual(
            finalFocus,
            initialFocus,
            "Focus should return to original position after roundtrip"
        )
        XCTAssertEqual(
            manager.currentFocus,
            initialFocus,
            "Current focus should match original"
        )
    }
    
    // MARK: - BDD Scenario 5: Focus State Management
    
    /// BDD: As a keyboard-only user, when I clear focus,
    /// then I can restore it to continue navigation
    func testScenario_KeyboardUserRestoresFocus() {
        // Given: I am a keyboard-only user
        // And: Focus is on a specific element
        let initialFocus = KeyboardNavigationElement.sidebarSearch
        manager.setFocus(to: initialFocus)
        
        // When: I clear focus, then restore it
        manager.clearFocus()
        XCTAssertNil(manager.currentFocus, "Focus should be cleared")
        
        manager.restoreFocus()
        
        // Then: Focus should be restored
        XCTAssertNotNil(manager.currentFocus, "Focus should be restored")
    }
    
    // MARK: - BDD Scenario 6: Initial Focus
    
    /// BDD: As a keyboard-only user, when I first start using the app,
    /// then I can press Tab to start navigation from the first element
    func testScenario_KeyboardUserStartsNavigationFromFirst() {
        // Given: I am a keyboard-only user
        // And: No focus is set (initial state)
        XCTAssertNil(manager.currentFocus, "No focus should be set initially")
        
        // When: I press Tab
        let firstFocus = manager.moveFocusForward()
        
        // Then: Focus should be set to the first element
        XCTAssertNotNil(firstFocus, "Tab should set focus to first element")
        
        // And: Focus should be in the toolbar section
        if let firstFocus = firstFocus {
            XCTAssertEqual(
                firstFocus.section,
                KeyboardNavigationSection.toolbar,
                "First focus should be in toolbar section"
            )
        }
    }
}
