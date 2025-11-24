//
//  LayoutCustomizationViewModelBDDTests.swift
//  UITests
//
//  BDD tests for LayoutCustomizationViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class LayoutCustomizationViewModelBDDTests: XCTestCase {
    var viewModel: LayoutCustomizationViewModel!
    var mockLayoutManager: MockLayoutConfigurationManager!
    
    override func setUp() {
        super.setUp()
        mockLayoutManager = MockLayoutConfigurationManager()
        viewModel = LayoutCustomizationViewModel(layoutManager: mockLayoutManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockLayoutManager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToCustomizeMyLayoutAndHaveItSaved() async {
        // Given: I want a vertical split layout
        viewModel.setLayoutMode(.verticalSplit)
        
        // When: I save my layout preference
        await viewModel.saveLayout()
        
        // Then: My layout should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.layoutMode, .verticalSplit)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    func testAsAUserIWantToShowOrHidePanels() async {
        // Given: I want to show the track details panel
        viewModel.setPanelVisibility(.trackDetails, visible: true)
        
        // When: I save my layout
        await viewModel.saveLayout()
        
        // Then: The panel should be visible
        let saved = await mockLayoutManager.getLayout()
        XCTAssertTrue(saved?.panelVisibility[.trackDetails] ?? false)
    }
    
    func testAsAUserIWantToAdjustPanelSizes() async {
        // Given: I want a larger library browser
        viewModel.setPanelSize(.libraryBrowser, size: 500)
        
        // When: I save my layout
        await viewModel.saveLayout()
        
        // Then: The panel size should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.panelSizes[.libraryBrowser], 500)
    }
}
