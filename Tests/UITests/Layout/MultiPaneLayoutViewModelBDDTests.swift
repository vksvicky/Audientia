//
//  MultiPaneLayoutViewModelBDDTests.swift
//  UITests
//
//  BDD tests for MultiPaneLayoutViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class MultiPaneLayoutViewModelBDDTests: XCTestCase {
    var viewModel: MultiPaneLayoutViewModel!
    var mockLayoutManager: MockLayoutConfigurationManager!
    
    override func setUp() {
        super.setUp()
        mockLayoutManager = MockLayoutConfigurationManager()
        viewModel = MultiPaneLayoutViewModel(layoutManager: mockLayoutManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockLayoutManager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToSeeAMultiPaneLayoutWithResizablePanels() async {
        // Given: I want a MediaMonkey-style interface
        await viewModel.loadLayout()
        
        // When: I view the layout
        // Then: I should see multiple panels
        XCTAssertNotNil(viewModel.currentLayout)
        XCTAssertFalse(viewModel.currentLayout.panelVisibility.isEmpty)
    }
    
    func testAsAUserIWantToShowOrHidePanels() async {
        // Given: I want to show the track details panel
        // When: I toggle its visibility
        viewModel.togglePanelVisibility(.trackDetails)
        await viewModel.saveLayout()
        
        // Then: The panel should be visible and saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertTrue(saved?.panelVisibility[.trackDetails] ?? false)
    }
    
    func testAsAUserIWantToResizePanels() async {
        // Given: I want a larger library browser
        // When: I resize it
        viewModel.updatePanelSize(.libraryBrowser, size: 500)
        await viewModel.saveLayout()
        
        // Then: The panel size should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.panelSizes[.libraryBrowser], 500)
    }
    
    func testAsAUserIWantToResetMyLayoutToDefaults() async {
        // Given: I customized my layout
        viewModel.togglePanelVisibility(.trackDetails)
        await viewModel.saveLayout()
        
        // When: I reset the layout
        await viewModel.resetLayout()
        
        // Then: It should match the defaults again
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.layoutMode, LayoutConfiguration.default.layoutMode)
        XCTAssertFalse(saved?.panelVisibility[.trackDetails] ?? true)
    }
}
