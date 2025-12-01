//
//  AutoTaggingProgressViewTests.swift
//  UITests
//
//  TDD tests for AutoTaggingProgressView
//

import SwiftUI
import XCTest

@MainActor
final class AutoTaggingProgressViewTests: XCTestCase {
    
    func testViewInitialises() {
        let viewModel = AutoTaggingProgressViewModel()
        let view = AutoTaggingProgressView(viewModel: viewModel)
        XCTAssertNotNil(view)
    }
}
