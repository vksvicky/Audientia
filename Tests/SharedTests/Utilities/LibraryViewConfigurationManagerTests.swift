//
//  LibraryViewConfigurationManagerTests.swift
//  SharedTests
//
//  TDD tests for LibraryViewConfigurationManager following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared
final class LibraryViewConfigurationManagerTests: XCTestCase {
    var manager: LibraryViewConfigurationManager!
    var mockStorage: MockSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockSettingsStorage()
        manager = LibraryViewConfigurationManager(storage: mockStorage)
    }
    
    override func tearDown() {
        manager = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testSaveAndLoadConfiguration() async throws {
        // Given: A configuration
        var config = LibraryViewConfiguration.default
        config.viewMode = .grid
        config.grouping = .artist
        
        // When: Saving and loading
        try await manager.saveConfiguration(config)
        let loaded = await manager.loadConfiguration()
        
        // Then: Should match
        XCTAssertEqual(loaded.viewMode, .grid)
        XCTAssertEqual(loaded.grouping, .artist)
    }
    
    func testLoadDefaultWhenNoSavedConfiguration() async {
        // Given: No saved configuration
        // When: Loading
        let loaded = await manager.loadConfiguration()
        
        // Then: Should return default
        XCTAssertEqual(loaded.viewMode, LibraryViewConfiguration.default.viewMode)
    }
    
    // MARK: - Inverse Relationships
    
    func testResetToDefault() async throws {
        // Given: A modified configuration
        var config = LibraryViewConfiguration.default
        config.viewMode = .grid
        try await manager.saveConfiguration(config)
        
        // When: Resetting
        try await manager.resetToDefault()
        let loaded = await manager.loadConfiguration()
        
        // Then: Should be default
        XCTAssertEqual(loaded.viewMode, LibraryViewConfiguration.default.viewMode)
    }
}
