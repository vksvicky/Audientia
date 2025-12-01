//
//  SettingsViewBDDTests.swift
//  UITests
//
//  BDD tests for SettingsView
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
final class SettingsViewBDDTests: XCTestCase {
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
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToAccessAllSettingsInOnePlace() async {
        // Given: I want to configure my application
        // When: I open the settings view
        let view = SettingsView(viewModel: viewModel)
        await viewModel.loadSettings()
        
        // Then: I should see all settings categories
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertNotNil(viewModel.currentTheme)
    }
}

#endif
