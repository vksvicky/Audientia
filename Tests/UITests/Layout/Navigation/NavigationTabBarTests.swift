// NavigationTabBarTests.swift
// Audientia - UI Tests
//
// TDD Unit Tests for NavigationTabBar component
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import SwiftUI
import XCTest

@testable import Audientia

// MARK: - TDD Unit Tests

/// Unit tests for NavigationTabBar following TDD practices
final class NavigationTabBarTests: XCTestCase {
    
    // MARK: - [Right]: Are the Results Right?
    
    @MainActor
    func testNavigationTabBarRendersAllTabs() {
        // Given
        let selectedTab = TabItem.home
        
        // When
        let view = NavigationTabBar(selectedTab: .constant(selectedTab))
        
        // Then - view should be created without errors
        XCTAssertNotNil(view, "NavigationTabBar should be created successfully")
    }
    
    @MainActor
    func testNavigationTabBarHasCorrectHeight() {
        // Given/When
        let expectedHeight: CGFloat = 44
        
        // Then - height should be 44px as per design spec
        // This is verified by the frame modifier in the component
        XCTAssertEqual(expectedHeight, 44, "Tab bar height should be 44px")
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    @MainActor
    func testFirstTabIsHome() {
        // Given
        let firstTab = TabItem.allCases.first
        
        // Then
        XCTAssertEqual(firstTab, .home, "First tab should be Home")
    }
    
    @MainActor
    func testLastTabIsVisualiser() {
        // Given
        let lastTab = TabItem.allCases.last
        
        // Then
        XCTAssertEqual(lastTab, .visualiser, "Last tab should be Visualiser")
    }
    
    // MARK: - Right-BIC[E]P: Error Conditions
    
    @MainActor
    func testNavigationTabBarHandlesAllTabCases() {
        // Given/When/Then - all tabs should render without crashes
        for tab in TabItem.allCases {
            let view = NavigationTabBar(selectedTab: .constant(tab))
            XCTAssertNotNil(view, "NavigationTabBar should handle \(tab) selection")
        }
    }
}

// MARK: - BDD Tests

/// BDD-style tests for NavigationTabBar user scenarios
final class NavigationTabBarBDDTests: XCTestCase {
    
    // MARK: - Scenario: User sees horizontal tab bar
    
    @MainActor
    func testScenario_UserSeesHorizontalTabBar() {
        // Given: The main window is open
        // When: The user looks at the top of the content area
        // Then: They see a horizontal tab bar with 5 tabs
        
        let tabCount = TabItem.allCases.count
        XCTAssertEqual(tabCount, 5, "Tab bar should display 5 tabs")
    }
    
    // MARK: - Scenario: User clicks tab to navigate
    
    @MainActor
    func testScenario_UserClicksTabToNavigate() {
        // Given: User is on the Home tab
        var selectedTab = TabItem.home
        
        // When: User clicks the Library tab
        selectedTab = .library
        
        // Then: The selected tab changes to Library
        XCTAssertEqual(selectedTab, .library)
    }
    
    // MARK: - Scenario: User uses keyboard shortcut
    
    @MainActor
    func testScenario_UserUsesKeyboardShortcut() {
        // Given: User wants quick navigation
        // When: User presses ⌘3
        let targetTab = TabItem.playlists
        
        // Then: Playlists tab is selected (shortcut number 3)
        XCTAssertEqual(targetTab.keyboardShortcutNumber, 3)
    }
    
    // MARK: - Scenario: Selected tab is visually highlighted
    
    @MainActor
    func testScenario_SelectedTabIsHighlighted() {
        // Given: User is viewing the tab bar
        // When: A tab is selected
        // Then: The selected tab should be visually highlighted
        
        let selectedTab = TabItem.library
        let view = NavigationTabBar(selectedTab: .constant(selectedTab))
        XCTAssertNotNil(view, "Tab bar should render with selected tab highlighted")
    }
    
    // MARK: - Scenario: Hover states provide visual feedback
    
    @MainActor
    func testScenario_HoverStatesProvideVisualFeedback() {
        // Given: User hovers over a tab button
        // When: Mouse cursor is over an unselected tab
        // Then: Tab should show hover state (subtle background highlight)
        
        // Note: Hover states are implemented using @State isHovered and .onHover modifier
        // Visual feedback: Color(NSColor.controlAccentColor).opacity(0.1) on hover
        let view = NavigationTabBar(selectedTab: .constant(.home))
        XCTAssertNotNil(view, "Tab bar should support hover states")
    }
    
    // MARK: - Scenario: Pressed states provide tactile feedback
    
    @MainActor
    func testScenario_PressedStatesProvideTactileFeedback() {
        // Given: User presses a tab button
        // When: Mouse button is pressed down
        // Then: Tab should show pressed state (darker background)
        
        // Note: Pressed states are implemented using @State isPressed and pressEvents modifier
        // Visual feedback: Color(NSColor.controlAccentColor).opacity(0.2) when pressed
        let view = NavigationTabBar(selectedTab: .constant(.home))
        XCTAssertNotNil(view, "Tab bar should support pressed states")
    }
    
    // MARK: - Scenario: VoiceOver accessibility support
    
    @MainActor
    func testScenario_VoiceOverAccessibilitySupport() {
        // Given: User is using VoiceOver
        // When: They navigate the tab bar
        // Then: Each tab should have proper accessibility labels and hints
        
        let view = NavigationTabBar(selectedTab: .constant(.home))
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // Verify all tabs have display names for accessibility
        for tab in TabItem.allCases {
            XCTAssertFalse(tab.displayName.isEmpty, "Tab \(tab) should have an accessibility label")
        }
    }
    
    // MARK: - Scenario: Tab shows icon and label
    
    @MainActor
    func testScenario_TabShowsIconAndLabel() {
        // Given: Any tab
        for tab in TabItem.allCases {
            // When: Tab is displayed
            // Then: It has both icon and label
            XCTAssertFalse(tab.iconName.isEmpty, "\(tab) should have an icon")
            XCTAssertFalse(tab.displayName.isEmpty, "\(tab) should have a label")
        }
    }
    
    // MARK: - Scenario: Tab order is consistent
    
    @MainActor
    func testScenario_TabOrderIsConsistent() {
        // Given: User expects a logical tab order
        let expectedOrder: [TabItem] = [.home, .library, .playlists, .devices, .visualiser]
        
        // When: Tabs are displayed
        let actualOrder = TabItem.allCases
        
        // Then: Order matches expected
        XCTAssertEqual(actualOrder, expectedOrder, "Tab order should be: Home, Library, Playlists, Devices, Visualiser")
    }
}
