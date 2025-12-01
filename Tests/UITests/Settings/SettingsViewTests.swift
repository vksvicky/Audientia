//
//  SettingsViewTests.swift
//  UITests
//
//  TDD tests for SettingsView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import SwiftUI

#if canImport(XCTest)
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class SettingsViewTests: XCTestCase {
    var viewModel: SettingsViewModel!
    var mockLayoutManager: SettingsMockLayoutConfigurationManager!
    var mockThemeManager: MockThemeManager!
    var mockWindowStateManager: MockWindowStateManager!
    var mockLibraryViewManager: SettingsMockLibraryViewConfigurationManager!
    
    override func setUp() {
        super.setUp()
        mockLayoutManager = SettingsMockLayoutConfigurationManager()
        mockThemeManager = MockThemeManager()
        mockWindowStateManager = MockWindowStateManager()
        mockLibraryViewManager = SettingsMockLibraryViewConfigurationManager()
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
    
    func testViewInitialisation() {
        // Given: A view model
        // When: Creating view
        let view = SettingsView(viewModel: viewModel)
        
        // Then: View should be hosted without triggering SwiftUI state warnings
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }
    
    func testViewLoadsSettingsOnAppear() async {
        // Given: A view
        _ = SettingsView(viewModel: viewModel)
        
        // When: View appears (task runs)
        await viewModel.loadSettings()
        
        // Then: Settings should be loaded
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertNotNil(viewModel.currentTheme)
    }
}

#endif
