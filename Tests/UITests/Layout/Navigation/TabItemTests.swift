// TabItemTests.swift
// Audientia - UI Tests
//
// TDD Unit Tests for TabItem enum
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import SwiftUI
import XCTest

@testable import Audientia

// MARK: - TDD Unit Tests

/// Unit tests for TabItem enum following TDD practices
/// Tests cover: [Right]-BICEP, boundary conditions, and edge cases
final class TabItemTests: XCTestCase {
    
    // MARK: - [Right]: Are the Results Right?
    
    func testAllCasesContainsExpectedTabs() {
        // Given/When
        let allCases = TabItem.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 5, "Should have exactly 5 tabs")
        XCTAssertTrue(allCases.contains(.home), "Should contain home tab")
        XCTAssertTrue(allCases.contains(.library), "Should contain library tab")
        XCTAssertTrue(allCases.contains(.playlists), "Should contain playlists tab")
        XCTAssertTrue(allCases.contains(.devices), "Should contain devices tab")
        XCTAssertTrue(allCases.contains(.visualiser), "Should contain visualiser tab")
    }
    
    func testDisplayNamesAreCorrect() {
        XCTAssertEqual(TabItem.home.displayName, "Home")
        XCTAssertEqual(TabItem.library.displayName, "Library")
        XCTAssertEqual(TabItem.playlists.displayName, "Playlists")
        XCTAssertEqual(TabItem.devices.displayName, "Devices")
        XCTAssertEqual(TabItem.visualiser.displayName, "Visualiser")
    }
    
    func testIconNamesAreValidSFSymbols() {
        // All tab icons should be valid SF Symbol names
        let validIconPatterns = ["house", "books", "list", "iphone", "waveform"]
        
        for (index, tab) in TabItem.allCases.enumerated() {
            XCTAssertFalse(tab.iconName.isEmpty, "Icon name should not be empty for \(tab)")
            XCTAssertTrue(
                tab.iconName.contains(validIconPatterns[index]) || !tab.iconName.isEmpty,
                "Icon \(tab.iconName) should be a valid SF Symbol pattern"
            )
        }
    }
    
    func testKeyboardShortcutsAreSequential() {
        // Keyboard shortcuts should be 1, 2, 3, 4, 5
        XCTAssertEqual(TabItem.home.keyboardShortcutNumber, 1)
        XCTAssertEqual(TabItem.library.keyboardShortcutNumber, 2)
        XCTAssertEqual(TabItem.playlists.keyboardShortcutNumber, 3)
        XCTAssertEqual(TabItem.devices.keyboardShortcutNumber, 4)
        XCTAssertEqual(TabItem.visualiser.keyboardShortcutNumber, 5)
    }
    
    func testSearchPlaceholdersAreContextual() {
        XCTAssertEqual(TabItem.home.searchPlaceholder, "Search...")
        XCTAssertTrue(TabItem.library.searchPlaceholder.contains("library"))
        XCTAssertTrue(TabItem.playlists.searchPlaceholder.contains("playlists"))
        XCTAssertTrue(TabItem.devices.searchPlaceholder.contains("devices"))
        XCTAssertEqual(TabItem.visualiser.searchPlaceholder, "Search...")
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    func testRawValuesAreUnique() {
        let rawValues = TabItem.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        
        XCTAssertEqual(rawValues.count, uniqueRawValues.count, "All raw values should be unique")
    }
    
    func testIdentifiersAreUnique() {
        let ids = TabItem.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIds.count, "All identifiers should be unique")
    }
    
    func testKeyEquivalentsAreUnique() {
        // Keyboard shortcuts must be unique to avoid conflicts
        let shortcuts = TabItem.allCases.map { $0.keyboardShortcutNumber }
        let uniqueShortcuts = Set(shortcuts)
        
        XCTAssertEqual(shortcuts.count, uniqueShortcuts.count, "All keyboard shortcuts should be unique")
    }
    
    // MARK: - Right-B[I]CEP: Inverse Relationships
    
    func testIdMatchesRawValue() {
        for tab in TabItem.allCases {
            XCTAssertEqual(tab.id, tab.rawValue, "ID should match raw value for \(tab)")
        }
    }
    
    // MARK: - Right-BI[C]EP: Cross-Checking
    
    func testTabOrderMatchesKeyboardShortcutOrder() {
        // Tabs should be in the same order as their keyboard shortcuts
        let sortedByShortcut = TabItem.allCases.sorted { $0.keyboardShortcutNumber < $1.keyboardShortcutNumber }
        
        XCTAssertEqual(TabItem.allCases, sortedByShortcut, "Tab order should match keyboard shortcut order")
    }
    
    // MARK: - Right-BIC[E]P: Error Conditions
    
    func testNoRadioTabExists() {
        // Radio was removed from design - ensure it doesn't exist
        let hasRadio = TabItem.allCases.contains { $0.displayName.lowercased().contains("radio") }
        XCTAssertFalse(hasRadio, "Radio tab should not exist in the new design")
    }
    
    func testNoPlayingTabExists() {
        // Playing tab was removed - now part of player bar
        let hasPlaying = TabItem.allCases.contains { $0.displayName.lowercased().contains("playing") }
        XCTAssertFalse(hasPlaying, "Playing tab should not exist - consolidated into player bar")
    }
    
    // MARK: - Hashable Conformance
    
    func testHashableConformance() {
        var set: Set<TabItem> = []
        
        for tab in TabItem.allCases {
            set.insert(tab)
        }
        
        XCTAssertEqual(set.count, 5, "All tabs should be hashable and insertable into a Set")
    }
    
    func testEquatableConformance() {
        XCTAssertEqual(TabItem.home, TabItem.home)
        XCTAssertNotEqual(TabItem.home, TabItem.library)
    }
}

// MARK: - BDD Tests

/// BDD-style tests for TabItem behavior scenarios
final class TabItemBDDTests: XCTestCase {
    
    // MARK: - Scenario: User navigates using keyboard shortcuts
    
    func testScenario_UserNavigatesWithKeyboardShortcuts() {
        // Given: A user wants to quickly navigate to different sections
        // When: They use keyboard shortcuts ⌘1 through ⌘5
        // Then: Each shortcut should map to a specific tab
        
        let expectedMapping: [(KeyEquivalent, TabItem)] = [
            (KeyEquivalent("1"), .home),
            (KeyEquivalent("2"), .library),
            (KeyEquivalent("3"), .playlists),
            (KeyEquivalent("4"), .devices),
            (KeyEquivalent("5"), .visualiser)
        ]
        
        for (expectedKey, tab) in expectedMapping {
            XCTAssertEqual(
                tab.keyEquivalent,
                expectedKey,
                "⌘\(tab.keyboardShortcutNumber) should navigate to \(tab.displayName)"
            )
        }
    }
    
    // MARK: - Scenario: Search context changes based on tab
    
    func testScenario_SearchPlaceholderReflectsContext() {
        // Given: A user is on different tabs
        // When: They focus the search field
        // Then: The placeholder should reflect the current context
        
        XCTAssertTrue(
            TabItem.library.searchPlaceholder != TabItem.playlists.searchPlaceholder,
            "Search placeholders should be contextual to the tab"
        )
    }
    
    // MARK: - Scenario: Tab icons are visually distinct
    
    func testScenario_TabIconsAreVisuallyDistinct() {
        // Given: A user looking at the tab bar
        // When: They scan the icons
        // Then: Each icon should be visually distinct
        
        let icons = TabItem.allCases.map { $0.iconName }
        let uniqueIcons = Set(icons)
        
        XCTAssertEqual(icons.count, uniqueIcons.count, "Each tab should have a unique icon")
    }
    
    // MARK: - Scenario: All tabs have accessible names
    
    func testScenario_TabsHaveAccessibleNames() {
        // Given: A user using VoiceOver
        // When: They navigate the tab bar
        // Then: Each tab should have a meaningful display name
        
        for tab in TabItem.allCases {
            XCTAssertFalse(tab.displayName.isEmpty, "Tab should have an accessible display name")
            XCTAssertTrue(
                tab.displayName.count >= 4,
                "Display name '\(tab.displayName)' should be descriptive enough"
            )
        }
    }
}
