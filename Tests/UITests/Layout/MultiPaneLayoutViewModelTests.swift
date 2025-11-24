//
//  MultiPaneLayoutViewModelTests.swift
//  UITests
//
//  TDD tests for MultiPaneLayoutViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class MultiPaneLayoutViewModelTests: XCTestCase {
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
    
    // MARK: - Right Results
    
    func testLoadLayout() async {
        // Given: A saved layout
        var layout = LayoutConfiguration.default
        layout.layoutMode = .verticalSplit
        await mockLayoutManager.setLayout(layout)
        
        // When: Loading layout
        await viewModel.loadLayout()
        
        // Then: Should load saved layout
        XCTAssertEqual(viewModel.currentLayout.layoutMode, .verticalSplit)
    }
    
    func testTogglePanelVisibility() {
        // Given: Default layout with track details hidden
        // When: Toggling track details panel
        viewModel.togglePanelVisibility(.trackDetails)
        
        // Then: Panel should be visible
        XCTAssertTrue(viewModel.currentLayout.panelVisibility[.trackDetails] ?? false)
    }
    
    func testUpdatePanelSize() {
        // Given: Default layout
        // When: Updating panel size
        viewModel.updatePanelSize(.libraryBrowser, size: 400)
        
        // Then: Panel size should be updated
        XCTAssertEqual(viewModel.currentLayout.panelSizes[.libraryBrowser], 400)
    }
    
    func testSaveLayout() async {
        // Given: Modified layout
        viewModel.togglePanelVisibility(.trackDetails)
        
        // When: Saving
        await viewModel.saveLayout()
        
        // Then: Should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertTrue(saved?.panelVisibility[.trackDetails] ?? false)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    // MARK: - Boundary Conditions
    
    func testUpdatePanelSizeWithMinimum() {
        // Given: Default layout
        // When: Setting size below minimum
        viewModel.updatePanelSize(.libraryBrowser, size: 50)
        
        // Then: Should clamp to minimum (100)
        XCTAssertGreaterThanOrEqual(viewModel.currentLayout.panelSizes[.libraryBrowser] ?? 0, 100)
    }
    
    // MARK: - Inverse Relationships
    
    func testTogglePanelTwice() {
        // Given: Panel is hidden
        // When: Toggling twice
        viewModel.togglePanelVisibility(.trackDetails)
        viewModel.togglePanelVisibility(.trackDetails)
        
        // Then: Should be back to original state
        XCTAssertFalse(viewModel.currentLayout.panelVisibility[.trackDetails] ?? true)
    }
    
    // MARK: - Error Conditions
    
    func testSaveWithError() async {
        // Given: Manager that fails
        await mockLayoutManager.setShouldFail(true)
        viewModel.togglePanelVisibility(.trackDetails)
        
        // When: Saving
        await viewModel.saveLayout()
        
        // Then: Should have error
        XCTAssertNotNil(viewModel.lastError)
    }
}
