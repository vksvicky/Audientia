//
//  LayoutConfigurationManagerBDDTests.swift
//  SharedTests
//
//  BDD tests for LayoutConfigurationManager
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared
final class LayoutConfigurationManagerBDDTests: XCTestCase {
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
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToCustomizeMyLayoutAndHaveItSaved() async throws {
        // Given: I want a vertical split layout
        var layout = LayoutConfiguration.default
        layout.layoutMode = .verticalSplit
        
        // When: I save my layout preference
        try await manager.saveLayout(layout)
        
        // Then: My layout should be saved
        let loaded = await manager.loadLayout()
        XCTAssertEqual(loaded.layoutMode, .verticalSplit)
    }
    
    func testAsAUserIWantToResetMyLayoutToDefaults() async throws {
        // Given: I have a customized layout
        var layout = LayoutConfiguration.default
        layout.layoutMode = .tabbed
        try await manager.saveLayout(layout)
        
        // When: I reset to defaults
        try await manager.resetToDefault()
        
        // Then: My layout should be back to default
        let loaded = await manager.loadLayout()
        XCTAssertEqual(loaded.layoutMode, LayoutConfiguration.default.layoutMode)
    }
}
