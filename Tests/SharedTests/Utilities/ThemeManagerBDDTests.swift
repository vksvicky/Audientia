//
//  ThemeManagerBDDTests.swift
//  SharedTests
//
//  BDD tests for ThemeManager
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared

final class ThemeManagerBDDTests: XCTestCase {
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
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToSelectADarkThemeAndHaveItPersist() async throws {
        // Given: I prefer dark theme
        let theme = ThemeConfiguration.dark
        
        // When: I select and save the dark theme
        try await manager.saveTheme(theme)
        
        // Then: My theme preference should be saved
        let loaded = await manager.loadTheme()
        XCTAssertEqual(loaded.identifier, .dark)
    }
    
    func testAsAUserIWantToSeeAvailableThemes() {
        // Given: I want to change my theme
        // When: I view available themes
        let themes = manager.getAvailableThemes()
        
        // Then: I should see light, dark, and auto options
        XCTAssertTrue(themes.count >= 3)
        let identifiers = themes.map { $0.identifier }
        XCTAssertTrue(identifiers.contains(.light))
        XCTAssertTrue(identifiers.contains(.dark))
        XCTAssertTrue(identifiers.contains(.auto))
    }
}
