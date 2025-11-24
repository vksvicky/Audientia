//
//  SettingsViewModelTests.swift
//  UITests
//
//  TDD tests for SettingsViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class SettingsViewModelTests: XCTestCase {
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
    
    // MARK: - Right Results
    
    func testLoadSettings() async {
        // Given: Managers with saved configurations
        await mockLayoutManager.setLayout(.default)
        await mockThemeManager.setTheme(.dark)
        await mockLibraryViewManager.setConfiguration(.default)
        
        // When: Loading settings
        await viewModel.loadSettings()
        
        // Then: Settings should be loaded
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertNotNil(viewModel.currentTheme)
        XCTAssertNotNil(viewModel.currentLibraryViewConfig)
    }
    
    func testSaveLayoutConfiguration() async throws {
        // Given: A modified layout
        var layout = LayoutConfiguration.default
        layout.layoutMode = .verticalSplit
        
        // When: Saving layout
        try await viewModel.saveLayoutConfiguration(layout)
        
        // Then: Layout should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.layoutMode, .verticalSplit)
    }
    
    func testSaveThemeConfiguration() async throws {
        // Given: A theme
        let theme = ThemeConfiguration.dark
        
        // When: Saving theme
        try await viewModel.saveThemeConfiguration(theme)
        
        // Then: Theme should be saved
        let saved = await mockThemeManager.getTheme()
        XCTAssertEqual(saved?.identifier, .dark)
    }
    
    // MARK: - Boundary Conditions
    
    func testLoadSettingsWithNoSavedData() async {
        // Given: No saved configurations
        // When: Loading settings
        await viewModel.loadSettings()
        
        // Then: Should use defaults
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertNotNil(viewModel.currentTheme)
        XCTAssertNotNil(viewModel.currentLibraryViewConfig)
    }
    
    // MARK: - Inverse Relationships
    
    func testResetToDefaults() async throws {
        // Given: Modified settings
        var layout = LayoutConfiguration.default
        layout.layoutMode = .tabbed
        try await viewModel.saveLayoutConfiguration(layout)
        
        // When: Resetting to defaults
        try await viewModel.resetToDefaults()
        
        // Then: Should be back to defaults
        let loaded = await mockLayoutManager.getLayout()
        XCTAssertEqual(loaded?.layoutMode, LayoutConfiguration.default.layoutMode)
    }
    
    // MARK: - Error Conditions
    
    func testSaveWithError() async {
        // Given: Manager that fails
        await mockLayoutManager.setShouldFail(true)
        
        // When: Saving
        // Then: Should handle error
        do {
            try await viewModel.saveLayoutConfiguration(.default)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

/// Mock implementations for testing
actor MockLayoutConfigurationManager: LayoutConfigurationManagerProtocol {
    private var layout: LayoutConfiguration?
    var shouldFail = false
    
    func setLayout(_ layout: LayoutConfiguration) {
        self.layout = layout
    }
    
    func getLayout() -> LayoutConfiguration? {
        layout
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func saveLayout(_ layout: LayoutConfiguration) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        self.layout = layout
    }
    
    func loadLayout() async -> LayoutConfiguration {
        layout ?? LayoutConfiguration.default
    }
    
    func resetToDefault() async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        layout = LayoutConfiguration.default
    }
}

actor MockThemeManager: ThemeManagerProtocol {
    private var theme: ThemeConfiguration?
    var shouldFail = false
    
    func setTheme(_ theme: ThemeConfiguration) {
        self.theme = theme
    }
    
    func getTheme() -> ThemeConfiguration? {
        theme
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func saveTheme(_ theme: ThemeConfiguration) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        self.theme = theme
    }
    
    func loadTheme() async -> ThemeConfiguration {
        theme ?? ThemeConfiguration.auto
    }
    
    func getAvailableThemes() -> [ThemeConfiguration] {
        [.light, .dark, .auto]
    }
    
    func resetToDefault() async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        theme = ThemeConfiguration.auto
    }
}

actor MockWindowStateManager: WindowStateManagerProtocol {
    private var state: WindowState?
    var shouldFail = false
    
    func setState(_ state: WindowState) {
        self.state = state
    }
    
    func getState() -> WindowState? {
        state
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func saveWindowState(_ state: WindowState) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        self.state = state
    }
    
    func loadWindowState() async -> WindowState? {
        state
    }
    
    func clearWindowState() async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        state = nil
    }
}

actor MockLibraryViewConfigurationManager: LibraryViewConfigurationManagerProtocol {
    private var config: LibraryViewConfiguration?
    var shouldFail = false
    
    func setConfiguration(_ config: LibraryViewConfiguration) {
        self.config = config
    }
    
    func getConfiguration() -> LibraryViewConfiguration? {
        config
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func saveConfiguration(_ config: LibraryViewConfiguration) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        self.config = config
    }
    
    func loadConfiguration() async -> LibraryViewConfiguration {
        config ?? LibraryViewConfiguration.default
    }
    
    func resetToDefault() async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        config = LibraryViewConfiguration.default
    }
}
