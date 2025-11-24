//
//  ThemeSelectorViewModelBDDTests.swift
//  UITests
//
//  BDD tests for ThemeSelectorViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class ThemeSelectorViewModelBDDTests: XCTestCase {
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
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToSelectADarkThemeAndHaveItPersist() async {
        // Given: I prefer dark theme
        await viewModel.loadThemes()
        
        // When: I select the dark theme
        await viewModel.selectTheme(.dark)
        
        // Then: My theme preference should be saved
        let saved = await mockThemeManager.getTheme()
        XCTAssertEqual(saved?.identifier, .dark)
        XCTAssertEqual(viewModel.currentTheme.identifier, .dark)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    func testAsAUserIWantToSeeAvailableThemes() async {
        // Given: I want to change my theme
        // When: I view available themes
        await viewModel.loadThemes()
        
        // Then: I should see light, dark, and auto options
        XCTAssertTrue(viewModel.availableThemes.count >= 3)
        let identifiers = viewModel.availableThemes.map { $0.identifier }
        XCTAssertTrue(identifiers.contains(.light))
        XCTAssertTrue(identifiers.contains(.dark))
        XCTAssertTrue(identifiers.contains(.auto))
    }
}
