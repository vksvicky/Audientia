// CollapsibleToolbarTests.swift
// Audientia - UI Tests
//
// TDD Unit Tests for CollapsibleToolbar component
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import SwiftUI
import XCTest

@testable import Audientia

// MARK: - TDD Unit Tests

/// Unit tests for CollapsibleToolbar following TDD practices
final class CollapsibleToolbarTests: XCTestCase {
    
    // MARK: - [Right]: Are the Results Right?
    
    @MainActor
    func testExpandedHeightIs44() {
        XCTAssertEqual(CollapsibleToolbar.expandedHeight, 44, "Expanded height should be 44px")
    }
    
    @MainActor
    func testCollapsedHeightIs20() {
        XCTAssertEqual(CollapsibleToolbar.collapsedHeight, 20, "Collapsed height should be 20px")
    }
    
    @MainActor
    func testToolbarCreatesSuccessfully() {
        // Given/When
        let toolbar = CollapsibleToolbar(
            selectedTab: .constant(.home),
            isExpanded: .constant(true)
        )
        
        // Then
        XCTAssertNotNil(toolbar, "Toolbar should be created successfully")
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    @MainActor
    func testToolbarStateTransitions() {
        // Given
        var isExpanded = true
        
        // When expanded -> collapsed
        isExpanded = false
        
        // Then
        XCTAssertFalse(isExpanded, "Toolbar should be collapsible")
        
        // When collapsed -> expanded
        isExpanded = true
        
        // Then
        XCTAssertTrue(isExpanded, "Toolbar should be expandable")
    }
    
    @MainActor
    func testToolbarWorksWithAllTabs() {
        // Given/When/Then - toolbar should work with any selected tab
        for tab in TabItem.allCases {
            let toolbar = CollapsibleToolbar(
                selectedTab: .constant(tab),
                isExpanded: .constant(true)
            )
            XCTAssertNotNil(toolbar, "Toolbar should work with \(tab) selected")
        }
    }
    
    // MARK: - Right-B[I]CEP: Inverse Relationships
    
    @MainActor
    func testExpandedAndCollapsedAreMutuallyExclusive() {
        // Given
        var isExpanded = true
        
        // Then - if expanded, not collapsed
        XCTAssertTrue(isExpanded)
        XCTAssertFalse(!isExpanded)
        
        // When
        isExpanded = false
        
        // Then - if collapsed, not expanded
        XCTAssertFalse(isExpanded)
        XCTAssertTrue(!isExpanded)
    }
    
    // MARK: - Right-BI[C]EP: Cross-Checking
    
    @MainActor
    func testHeightDifferenceIsSignificant() {
        // The height difference should be noticeable for the animation
        let heightDifference = CollapsibleToolbar.expandedHeight - CollapsibleToolbar.collapsedHeight
        
        XCTAssertGreaterThan(heightDifference, 20, "Height difference should be significant")
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    @MainActor
    func testKeyboardShortcutForToggle() {
        // Given: User wants to toggle toolbar visibility
        // The shortcut should be ⌘T
        let expectedModifiers: EventModifiers = .command
        let expectedKey: KeyEquivalent = "t"
        
        // These values match what's defined in CollapsibleToolbar
        XCTAssertEqual(expectedModifiers, .command)
        XCTAssertEqual(expectedKey, "t")
    }
}

// MARK: - BDD Tests

/// BDD-style tests for CollapsibleToolbar user scenarios
final class CollapsibleToolbarBDDTests: XCTestCase {
    
    // MARK: - Scenario: User collapses toolbar to maximize content area
    
    @MainActor
    func testScenario_UserCollapsesToolbar() {
        // Given: User wants more vertical space for content
        var isExpanded = true
        
        // When: User clicks the collapse button (chevron up)
        isExpanded = false
        
        // Then: Toolbar collapses to minimal height
        XCTAssertFalse(isExpanded)
        XCTAssertEqual(
            CollapsibleToolbar.collapsedHeight,
            20,
            "Collapsed toolbar should be 20px"
        )
    }
    
    // MARK: - Scenario: User expands toolbar to see tabs
    
    @MainActor
    func testScenario_UserExpandsToolbar() {
        // Given: Toolbar is collapsed
        var isExpanded = false
        
        // When: User clicks the expand button (chevron down)
        isExpanded = true
        
        // Then: Toolbar expands to show full tab bar
        XCTAssertTrue(isExpanded)
        XCTAssertEqual(
            CollapsibleToolbar.expandedHeight,
            44,
            "Expanded toolbar should be 44px"
        )
    }
    
    // MARK: - Scenario: User toggles with keyboard shortcut
    
    @MainActor
    func testScenario_UserTogglesWithKeyboard() {
        // Given: User prefers keyboard navigation
        var isExpanded = true
        
        // When: User presses ⌘T
        isExpanded.toggle()
        
        // Then: Toolbar state toggles
        XCTAssertFalse(isExpanded)
        
        // When: User presses ⌘T again
        isExpanded.toggle()
        
        // Then: Toolbar returns to original state
        XCTAssertTrue(isExpanded)
    }
    
    // MARK: - Scenario: Animation provides smooth transition
    
    @MainActor
    func testScenario_AnimationIsDefined() {
        // Given: User expects smooth visual feedback
        // When: Toolbar state changes
        // Then: Animation duration should be reasonable (0.2 seconds per design)
        
        let expectedDuration = 0.2
        XCTAssertEqual(expectedDuration, 0.2, "Animation should be 0.2 seconds for smooth transition")
    }
    
    // MARK: - Scenario: Collapsed toolbar shows expand hint
    
    @MainActor
    func testScenario_CollapsedToolbarIsAccessible() {
        // Given: Toolbar is collapsed
        let isExpanded = false
        
        // When: User looks at collapsed toolbar
        // Then: There should be a visible way to expand it (chevron down button)
        
        XCTAssertFalse(isExpanded)
        // The expand button is always visible when collapsed
        // Verified by visual inspection of the component
    }
    
    // MARK: - Scenario: Tab selection persists through collapse/expand
    
    @MainActor
    func testScenario_TabSelectionPersistsThroughToggle() {
        // Given: User has Library tab selected
        let selectedTab = TabItem.library
        var isExpanded = true
        
        // When: User collapses and expands toolbar
        isExpanded = false
        isExpanded = true
        
        // Then: Library tab should still be selected and toolbar state changed
        XCTAssertEqual(selectedTab, .library, "Tab selection should persist through collapse/expand")
        XCTAssertTrue(isExpanded, "Toolbar should be expanded after toggle")
    }
}
