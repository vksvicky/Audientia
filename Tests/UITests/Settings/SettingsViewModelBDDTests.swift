//
//  SettingsViewModelBDDTests.swift
//  UITests
//
//  BDD tests for SettingsViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class SettingsViewModelBDDTests: XCTestCase {
    var viewModel: SettingsViewModel!
    var mockLayoutManager: MockLayoutConfigurationManager!
    var mockThemeManager: MockThemeManager!
    var mockWindowStateManager: MockWindowStateManager!
    var mockLibraryViewManager: MockLibraryViewConfigurationManager!
    
    override func setUp() {
        super.setUp()
        mockLayoutManager = MockLayoutConfigurationManager()
        mockThemeManager = MockThemeManager()
        mockWindowStateManager = MockWindowStateManager()
        mockLibraryViewManager = MockLibraryViewConfigurationManager()
        viewModel = SettingsViewModel(
            layoutManager: mockLayoutManager,
            themeManager: mockThemeManager,
            windowStateManager: mockWindowStateManager,
            libraryViewManager: mockLibraryViewManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockLayoutManager = nil
        mockThemeManager = nil
        mockWindowStateManager = nil
        mockLibraryViewManager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToViewAllMySettings() async {
        // Given: I have saved settings
        await mockLayoutManager.setLayout(.default)
        await mockThemeManager.setTheme(.dark)
        await mockLibraryViewManager.setConfiguration(.default)
        
        // When: I open the settings view
        await viewModel.loadSettings()
        
        // Then: I should see all my current settings
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertNotNil(viewModel.currentTheme)
        XCTAssertNotNil(viewModel.currentLibraryViewConfig)
        XCTAssertFalse(viewModel.availableThemes.isEmpty)
    }
    
    func testAsAUserIWantToChangeMyThemeAndHaveItSaved() async throws {
        // Given: I want to change to dark theme
        let darkTheme = ThemeConfiguration.dark
        
        // When: I select and save the dark theme
        try await viewModel.saveThemeConfiguration(darkTheme)
        
        // Then: My theme preference should be saved
        let saved = await mockThemeManager.getTheme()
        XCTAssertEqual(saved?.identifier, .dark)
        XCTAssertEqual(viewModel.currentTheme?.identifier, .dark)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    func testAsAUserIWantToCustomizeMyLayoutAndHaveItSaved() async throws {
        // Given: I want a vertical split layout
        var layout = LayoutConfiguration.default
        layout.layoutMode = .verticalSplit
        
        // When: I save my layout preference
        try await viewModel.saveLayoutConfiguration(layout)
        
        // Then: My layout should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.layoutMode, .verticalSplit)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    func testAsAUserIWantToResetAllSettingsToDefaults() async throws {
        // Given: I have customized settings
        var layout = LayoutConfiguration.default
        layout.layoutMode = .tabbed
        try await viewModel.saveLayoutConfiguration(layout)
        
        // When: I reset to defaults
        try await viewModel.resetToDefaults()
        
        // Then: All settings should be back to defaults
        let loadedLayout = await mockLayoutManager.getLayout()
        XCTAssertEqual(loadedLayout?.layoutMode, LayoutConfiguration.default.layoutMode)
        XCTAssertNotNil(viewModel.successMessage)
    }
}
