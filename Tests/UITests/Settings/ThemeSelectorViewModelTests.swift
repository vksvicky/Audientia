//
//  ThemeSelectorViewModelTests.swift
//  UITests
//
//  TDD tests for ThemeSelectorViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class ThemeSelectorViewModelTests: XCTestCase {
    var viewModel: ThemeSelectorViewModel!
    var mockThemeManager: MockThemeManager!
    
    override func setUp() {
        super.setUp()
        mockThemeManager = MockThemeManager()
        viewModel = ThemeSelectorViewModel(themeManager: mockThemeManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockThemeManager = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testLoadThemes() async {
        // Given: Manager with themes
        await mockThemeManager.setTheme(.dark)
        
        // When: Loading themes
        await viewModel.loadThemes()
        
        // Then: Should load current theme and available themes
        XCTAssertEqual(viewModel.currentTheme.identifier, .dark)
        XCTAssertFalse(viewModel.availableThemes.isEmpty)
    }
    
    func testSelectTheme() async {
        // Given: Available themes
        await viewModel.loadThemes()
        
        // When: Selecting a theme
        await viewModel.selectTheme(.dark)
        
        // Then: Theme should be saved
        let saved = await mockThemeManager.getTheme()
        XCTAssertEqual(saved?.identifier, .dark)
        XCTAssertEqual(viewModel.currentTheme.identifier, .dark)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    // MARK: - Inverse Relationships
    
    func testResetToDefault() async {
        // Given: A selected theme
        await viewModel.selectTheme(.dark)
        
        // When: Resetting
        await viewModel.resetToDefault()
        
        // Then: Should be auto theme
        XCTAssertEqual(viewModel.currentTheme.identifier, .auto)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    // MARK: - Error Conditions
    
    func testSelectThemeWithError() async {
        // Given: Manager that fails
        await mockThemeManager.setShouldFail(true)
        
        // When: Selecting theme
        await viewModel.selectTheme(.dark)
        
        // Then: Should have error
        XCTAssertNotNil(viewModel.lastError)
    }
}
