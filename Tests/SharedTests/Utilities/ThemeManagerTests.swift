//
//  ThemeManagerTests.swift
//  SharedTests
//
//  TDD tests for ThemeManager following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared

final class ThemeManagerTests: XCTestCase {
    var manager: ThemeManager!
    var mockStorage: MockSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockSettingsStorage()
        manager = ThemeManager(storage: mockStorage)
    }
    
    override func tearDown() {
        manager = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testSaveAndLoadTheme() async throws {
        // Given: A theme
        let theme = ThemeConfiguration.dark
        
        // When: Saving and loading
        try await manager.saveTheme(theme)
        let loaded = await manager.loadTheme()
        
        // Then: Should match
        XCTAssertEqual(loaded.identifier, .dark)
    }
    
    func testLoadDefaultWhenNoSavedTheme() async {
        // Given: No saved theme
        // When: Loading
        let loaded = await manager.loadTheme()
        
        // Then: Should return auto
        XCTAssertEqual(loaded.identifier, .auto)
    }
    
    func testGetAvailableThemes() {
        // Given: Manager
        // When: Getting available themes
        let themes = manager.getAvailableThemes()
        
        // Then: Should include light, dark, auto
        let identifiers = themes.map { $0.identifier }
        XCTAssertTrue(identifiers.contains(.light))
        XCTAssertTrue(identifiers.contains(.dark))
        XCTAssertTrue(identifiers.contains(.auto))
    }
    
    // MARK: - Inverse Relationships
    
    func testResetToDefault() async throws {
        // Given: A saved theme
        try await manager.saveTheme(.dark)
        
        // When: Resetting
        try await manager.resetToDefault()
        let loaded = await manager.loadTheme()
        
        // Then: Should be auto
        XCTAssertEqual(loaded.identifier, .auto)
    }
}
