//
//  MultiPaneLayoutViewTests.swift
//  UITests
//
//  TDD tests for MultiPaneLayoutView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared
@MainActor
final class MultiPaneLayoutViewTests: XCTestCase {
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
    
    func testViewInitialisation() {
        // Given: A view model
        // When: Creating view
        let view = MultiPaneLayoutView(viewModel: viewModel)
        
        // Then: View should be created
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testViewLoadsLayoutOnAppear() async {
        // Given: A view
        _ = MultiPaneLayoutView(viewModel: viewModel)
        
        // When: View appears (task runs)
        await viewModel.loadLayout()
        
        // Then: Layout should be loaded
        XCTAssertNotNil(viewModel.currentLayout)
    }
}
