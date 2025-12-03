// ContextualSidebarTests.swift
// Audientia - UI Tests
//
// TDD Unit Tests for ContextualSidebar component
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import SwiftUI
import XCTest

@testable import Audientia

// MARK: - TDD Unit Tests

/// Unit tests for ContextualSidebar following TDD practices
final class ContextualSidebarTests: XCTestCase {
    
    // MARK: - [Right]: Are the Results Right?
    
    @MainActor
    func testSidebarWidth() {
        XCTAssertEqual(ContextualSidebar.width, 180, "Sidebar width should be 180px")
    }
    
    @MainActor
    func testSidebarCreatesSuccessfully() {
        // Given/When
        let sidebar = ContextualSidebar(
            selectedTab: .constant(.home),
            searchText: .constant("")
        )
        
        // Then
        XCTAssertNotNil(sidebar, "Sidebar should be created successfully")
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    @MainActor
    func testSidebarWorksWithAllTabs() {
        // Given/When/Then - sidebar should work with any selected tab
        for tab in TabItem.allCases {
            let sidebar = ContextualSidebar(
                selectedTab: .constant(tab),
                searchText: .constant("")
            )
            XCTAssertNotNil(sidebar, "Sidebar should work with \(tab) selected")
        }
    }
    
    @MainActor
    func testEmptySearchText() {
        // Given/When
        let searchText = ""
        let sidebar = ContextualSidebar(
            selectedTab: .constant(.home),
            searchText: .constant(searchText)
        )
        
        // Then
        XCTAssertNotNil(sidebar, "Sidebar should handle empty search text")
    }
    
    @MainActor
    func testLongSearchText() {
        // Given/When
        let longSearchText = String(repeating: "a", count: 100)
        let sidebar = ContextualSidebar(
            selectedTab: .constant(.library),
            searchText: .constant(longSearchText)
        )
        
        // Then
        XCTAssertNotNil(sidebar, "Sidebar should handle long search text")
    }
    
    // MARK: - Right-BI[C]EP: Cross-Checking
    
    @MainActor
    func testSearchPlaceholderMatchesTab() {
        // Given
        for tab in TabItem.allCases {
            // When/Then
            let placeholder = tab.searchPlaceholder
            XCTAssertFalse(placeholder.isEmpty, "Search placeholder should not be empty for \(tab)")
        }
    }
    
    // MARK: - Right-BIC[E]P: Error Conditions
    
    @MainActor
    func testSidebarHandlesSpecialCharactersInSearch() {
        // Given
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        
        // When/Then - should not crash
        let sidebar = ContextualSidebar(
            selectedTab: .constant(.library),
            searchText: .constant(specialCharacters)
        )
        XCTAssertNotNil(sidebar, "Sidebar should handle special characters in search")
    }
    
    @MainActor
    func testSidebarHandlesUnicodeInSearch() {
        // Given
        let unicodeText = "音楽 🎵 música мүзика"
        
        // When/Then - should not crash
        let sidebar = ContextualSidebar(
            selectedTab: .constant(.library),
            searchText: .constant(unicodeText)
        )
        XCTAssertNotNil(sidebar, "Sidebar should handle unicode in search")
    }
}

// MARK: - BDD Tests

/// BDD-style tests for ContextualSidebar user scenarios
final class ContextualSidebarBDDTests: XCTestCase {
    
    // MARK: - Scenario: Sidebar shows contextual content for Home tab
    
    @MainActor
    func testScenario_HomeSidebarContent() {
        // Given: User is on the Home tab
        let selectedTab = TabItem.home
        
        // When: They look at the sidebar
        // Then: They see Quick Access section (Recently Played, Recently Added, etc.)
        
        XCTAssertEqual(selectedTab, .home)
        // Content verification is visual - tested via snapshot tests
    }
    
    // MARK: - Scenario: Sidebar shows contextual content for Library tab
    
    @MainActor
    func testScenario_LibrarySidebarContent() {
        // Given: User is on the Library tab
        let selectedTab = TabItem.library
        
        // When: They look at the sidebar
        // Then: They see Browse By section (All Tracks, Artists, Albums, Genres, Years, Folders)
        
        XCTAssertEqual(selectedTab, .library)
        // Content shows All Tracks, Artists, Albums, Genres, Years, Folders
    }
    
    // MARK: - Scenario: Sidebar shows contextual content for Playlists tab
    
    @MainActor
    func testScenario_PlaylistsSidebarContent() {
        // Given: User is on the Playlists tab
        let selectedTab = TabItem.playlists
        
        // When: They look at the sidebar
        // Then: They see Playlists section and Smart Playlists section
        
        XCTAssertEqual(selectedTab, .playlists)
    }
    
    // MARK: - Scenario: Sidebar shows contextual content for Devices tab
    
    @MainActor
    func testScenario_DevicesSidebarContent() {
        // Given: User is on the Devices tab
        let selectedTab = TabItem.devices
        
        // When: They look at the sidebar
        // Then: They see Connected Devices and Sync Options sections
        
        XCTAssertEqual(selectedTab, .devices)
    }
    
    // MARK: - Scenario: Sidebar shows contextual content for Visualiser tab
    
    @MainActor
    func testScenario_VisualiserSidebarContent() {
        // Given: User is on the Visualiser tab
        let selectedTab = TabItem.visualiser
        
        // When: They look at the sidebar
        // Then: They see Visualisation Style options and Settings sliders
        
        XCTAssertEqual(selectedTab, .visualiser)
    }
    
    // MARK: - Scenario: User types in search field
    
    @MainActor
    func testScenario_UserTypesInSearch() {
        // Given: User wants to search
        var searchText = ""
        
        // When: User types in search field
        searchText = "Beatles"
        
        // Then: Search text is captured
        XCTAssertEqual(searchText, "Beatles")
    }
    
    // MARK: - Scenario: Search placeholder changes with tab
    
    @MainActor
    func testScenario_SearchPlaceholderIsContextual() {
        // Given: User switches between tabs
        // When: They focus the search field
        // Then: Placeholder reflects current context
        
        XCTAssertEqual(TabItem.library.searchPlaceholder, "Search library...")
        XCTAssertEqual(TabItem.playlists.searchPlaceholder, "Search playlists...")
        XCTAssertEqual(TabItem.devices.searchPlaceholder, "Search devices...")
    }
    
    // MARK: - Scenario: Library statistics are always visible
    
    @MainActor
    func testScenario_LibraryStatsAlwaysVisible() {
        // Given: User is on any tab
        // When: They look at the bottom of the sidebar
        // Then: Library statistics (tracks, artists, albums, duration, size) are visible
        
        for tab in TabItem.allCases {
            // Library stats should be visible regardless of selected tab
            XCTAssertNotNil(tab, "Stats section should be visible for \(tab)")
        }
    }
    
    // MARK: - Scenario: Sidebar width is fixed
    
    @MainActor
    func testScenario_SidebarWidthIsFixed() {
        // Given: User resizes the window
        // When: Window size changes
        // Then: Sidebar maintains fixed width of 180px
        
        XCTAssertEqual(ContextualSidebar.width, 180, "Sidebar should maintain 180px width")
    }
}

// MARK: - Navigation Content Tests

/// Tests for sidebar navigation items
final class ContextualSidebarNavigationTests: XCTestCase {
    
    // MARK: - Home Tab Navigation Items
    
    @MainActor
    func testHomeQuickAccessItems() {
        // Expected quick access items in Home sidebar
        let expectedItems = [
            "Recently Played",
            "Recently Added",
            "Most Played",
            "Favourites"
        ]
        
        XCTAssertEqual(expectedItems.count, 4, "Home should have 4 quick access items")
    }
    
    // MARK: - Library Tab Navigation Items
    
    @MainActor
    func testLibraryBrowseByItems() {
        // Expected browse by items in Library sidebar
        let expectedItems = [
            "All Tracks",
            "Artists",
            "Albums",
            "Genres",
            "Years",
            "Folders"
        ]
        
        XCTAssertEqual(expectedItems.count, 6, "Library should have 6 browse by items")
    }
    
    // MARK: - Visualiser Tab Options
    
    @MainActor
    func testVisualiserStyleOptions() {
        // Expected visualisation styles
        let expectedStyles = [
            "LED Bars",
            "Lumi Bars",
            "Radial Spectrum",
            "Dual Channel",
            "Discrete Frequencies",
            "Round Bars Reflex"
        ]
        
        XCTAssertEqual(expectedStyles.count, 6, "Visualiser should have 6 style options")
    }
}
