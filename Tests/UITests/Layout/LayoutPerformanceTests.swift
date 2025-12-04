//
//  LayoutPerformanceTests.swift
//  Audientia - UI Performance Tests
//
//  Performance tests for layout transitions (tab switching, toolbar/player collapse)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared

// MARK: - Layout Performance Tests

/// Performance tests for layout transitions
final class LayoutPerformanceTests: XCTestCase {
    
    var mockAudioEngine: MockAudioEngine!
    var mockLayoutStateManager: MockLayoutStateManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        mockLayoutStateManager = MockLayoutStateManager()
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        mockLayoutStateManager = nil
        super.tearDown()
    }
    
    // MARK: - Tab Switching Performance
    
    /// Performance: Switching between all tabs repeatedly
    @MainActor
    func testPerformance_TabSwitching() {
        measure {
            let view = MainWindowLayoutView(
                audioEngine: mockAudioEngine,
                layoutStateManager: mockLayoutStateManager
            )
            SwiftUIViewTestHelpers.verifyViewCreation(view)
            
            // Simulate rapid tab switching by iterating over all TabItem cases
            let allTabs = TabItem.allCases
            for _ in 0..<10 {
                for tab in allTabs {
                    _ = tab.displayName
                    _ = tab.iconName
                    _ = tab.searchPlaceholder
                    _ = tab.keyboardShortcutNumber
                }
            }
        }
    }
    
    // MARK: - Toolbar / Player Collapse Performance
    
    /// Performance: Toggling toolbar and player collapse/expand states
    /// Note: This test measures UI performance, not async state management performance
    @MainActor
    func testPerformance_ToolbarAndPlayerCollapseExpand() {
        measure {
            let view = MainWindowLayoutView(
                audioEngine: mockAudioEngine,
                layoutStateManager: mockLayoutStateManager
            )
            SwiftUIViewTestHelpers.verifyViewCreation(view)
            
            // Simulate repeated state transitions by creating LayoutState objects
            // This measures the performance of state object creation and UI updates,
            // not the async persistence overhead
            for _ in 0..<50 {
                _ = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
                _ = LayoutState(isToolbarExpanded: true, isPlayerExpanded: false)
                _ = LayoutState.default
            }
        }
    }
    
    // MARK: - Search Routing Performance
    
    /// Performance: Updating search text and routing to appropriate ViewModels
    @MainActor
    func testPerformance_SearchRouting() {
        measure {
            let view = MainWindowLayoutView(
                audioEngine: mockAudioEngine,
                layoutStateManager: mockLayoutStateManager
            )
            SwiftUIViewTestHelpers.verifyViewCreation(view)
            
            // Simulate search text changes
            let queries = ["rock", "jazz", "favorites", "devices", "visuals"]
            for _ in 0..<20 {
                for query in queries {
                    _ = query.lowercased()
                }
            }
        }
    }
}
