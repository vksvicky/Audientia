//
//  LayoutCustomisationViewModelTests.swift
//  UITests
//
//  TDD tests for LayoutCustomisationViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class LayoutCustomisationViewModelTests: XCTestCase {
    var viewModel: LayoutCustomisationViewModel!
    var mockLayoutManager: MockLayoutConfigurationManager!
    
    override func setUp() {
        super.setUp()
        mockLayoutManager = MockLayoutConfigurationManager()
        viewModel = LayoutCustomisationViewModel(layoutManager: mockLayoutManager)
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
    
    func testSetPanelVisibility() {
        // Given: Default layout
        // When: Setting panel visibility
        viewModel.setPanelVisibility(.trackDetails, visible: true)
        
        // Then: Panel should be visible
        XCTAssertTrue(viewModel.currentLayout.panelVisibility[.trackDetails] ?? false)
    }
    
    func testSetPanelSize() {
        // Given: Default layout
        // When: Setting panel size
        viewModel.setPanelSize(.libraryBrowser, size: 400)
        
        // Then: Panel size should be updated
        XCTAssertEqual(viewModel.currentLayout.panelSizes[.libraryBrowser], 400)
    }
    
    func testSetLayoutMode() {
        // Given: Default layout
        // When: Setting layout mode
        viewModel.setLayoutMode(.verticalSplit)
        
        // Then: Layout mode should be updated
        XCTAssertEqual(viewModel.currentLayout.layoutMode, .verticalSplit)
    }
    
    func testSaveLayout() async {
        // Given: Modified layout
        viewModel.setLayoutMode(.tabbed)
        
        // When: Saving
        await viewModel.saveLayout()
        
        // Then: Should be saved
        let saved = await mockLayoutManager.getLayout()
        XCTAssertEqual(saved?.layoutMode, .tabbed)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    // MARK: - Inverse Relationships
    
    func testResetToDefault() async {
        // Given: Modified layout
        viewModel.setLayoutMode(.tabbed)
        await viewModel.saveLayout()
        
        // When: Resetting
        await viewModel.resetToDefault()
        
        // Then: Should be default
        XCTAssertEqual(viewModel.currentLayout.layoutMode, LayoutConfiguration.default.layoutMode)
        XCTAssertNotNil(viewModel.successMessage)
    }
    
    // MARK: - Error Conditions
    
    func testSaveWithError() async {
        // Given: Manager that fails
        await mockLayoutManager.setShouldFail(true)
        viewModel.setLayoutMode(.tabbed)
        
        // When: Saving
        await viewModel.saveLayout()
        
        // Then: Should have error
        XCTAssertNotNil(viewModel.lastError)
    }
}
