//
//  SettingsViewTests.swift
//  UITests
//
//  TDD tests for SettingsView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class SettingsViewTests: XCTestCase {
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
    
    func testViewInitialization() {
        // Given: A view model
        // When: Creating view
        let view = SettingsView(viewModel: viewModel)
        
        // Then: View should be created
        _ = view.body // Access body to verify compilation
    }
    
    func testViewLoadsSettingsOnAppear() async {
        // Given: A view
        let view = SettingsView(viewModel: viewModel)
        
        // When: View appears (task runs)
        await viewModel.loadSettings()
        
        // Then: Settings should be loaded
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertNotNil(viewModel.currentTheme)
    }
}
