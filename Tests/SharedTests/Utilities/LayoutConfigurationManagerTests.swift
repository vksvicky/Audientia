//
//  LayoutConfigurationManagerTests.swift
//  SharedTests
//
//  TDD tests for LayoutConfigurationManager following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared
final class LayoutConfigurationManagerTests: XCTestCase {
    var manager: LayoutConfigurationManager!
    var mockStorage: MockSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockSettingsStorage()
        manager = LayoutConfigurationManager(storage: mockStorage)
    }
    
    override func tearDown() {
        manager = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testSaveAndLoadLayout() async throws {
        // Given: A layout configuration
        var layout = LayoutConfiguration.default
        layout.layoutMode = .verticalSplit
        
        // When: Saving and loading
        try await manager.saveLayout(layout)
        let loaded = await manager.loadLayout()
        
        // Then: Should match
        XCTAssertEqual(loaded.layoutMode, .verticalSplit)
    }
    
    func testLoadDefaultWhenNoSavedLayout() async {
        // Given: No saved layout
        // When: Loading
        let loaded = await manager.loadLayout()
        
        // Then: Should return default
        XCTAssertEqual(loaded.layoutMode, LayoutConfiguration.default.layoutMode)
    }
    
    // MARK: - Boundary Conditions
    
    func testSaveLayoutWithAllPanelsHidden() async throws {
        // Given: Layout with all panels hidden
        var layout = LayoutConfiguration.default
        for panel in LayoutPanel.allCases {
            layout.panelVisibility[panel] = false
        }
        
        // When: Saving and loading
        try await manager.saveLayout(layout)
        let loaded = await manager.loadLayout()
        
        // Then: All panels should be hidden
        for panel in LayoutPanel.allCases {
            XCTAssertFalse(loaded.panelVisibility[panel] ?? true)
        }
    }
    
    // MARK: - Inverse Relationships
    
    func testResetToDefault() async throws {
        // Given: A modified layout
        var layout = LayoutConfiguration.default
        layout.layoutMode = .tabbed
        try await manager.saveLayout(layout)
        
        // When: Resetting to default
        try await manager.resetToDefault()
        let loaded = await manager.loadLayout()
        
        // Then: Should be default
        XCTAssertEqual(loaded.layoutMode, LayoutConfiguration.default.layoutMode)
    }
    
    // MARK: - Error Conditions
    
    func testSaveWithStorageError() async {
        // Given: Storage that fails
        await mockStorage.setShouldThrowError(true)
        
        // When: Saving
        // Then: Should throw
        do {
            try await manager.saveLayout(.default)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
