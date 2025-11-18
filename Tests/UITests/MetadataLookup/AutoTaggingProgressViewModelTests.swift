//
//  AutoTaggingProgressViewModelTests.swift
//  UITests
//
//  TDD tests for AutoTaggingProgressViewModel
//

import XCTest

@MainActor
final class AutoTaggingProgressViewModelTests: XCTestCase {
    
    func testStartInitializesState() {
        let viewModel = AutoTaggingProgressViewModel()
        viewModel.start(total: 5)
        XCTAssertEqual(viewModel.total, 5)
        XCTAssertEqual(viewModel.completed, 0)
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertEqual(viewModel.statusMessage, "Starting auto-tagging...")
    }
    
    func testUpdateAdvancesProgress() {
        let viewModel = AutoTaggingProgressViewModel()
        viewModel.start(total: 5)
        viewModel.update(completed: 2, trackName: "Test Track")
        XCTAssertEqual(viewModel.completed, 2)
        XCTAssertEqual(viewModel.currentTrackName, "Test Track")
        XCTAssertTrue(viewModel.progress > 0)
    }
    
    func testCompleteFinishesProgress() {
        let viewModel = AutoTaggingProgressViewModel()
        viewModel.start(total: 2)
        viewModel.update(completed: 2, trackName: "Test")
        viewModel.complete()
        XCTAssertEqual(viewModel.completed, 2)
        XCTAssertEqual(viewModel.statusMessage, "Auto-tagging complete")
        XCTAssertFalse(viewModel.isRunning)
    }
    
    func testResetClearsState() {
        let viewModel = AutoTaggingProgressViewModel()
        viewModel.start(total: 2)
        viewModel.reset()
        XCTAssertEqual(viewModel.total, 0)
        XCTAssertEqual(viewModel.completed, 0)
        XCTAssertEqual(viewModel.statusMessage, "Idle")
    }
}
