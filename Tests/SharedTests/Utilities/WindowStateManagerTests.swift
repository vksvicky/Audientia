//
//  WindowStateManagerTests.swift
//  SharedTests
//
//  TDD tests for WindowStateManager following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared
final class WindowStateManagerTests: XCTestCase {
    var manager: WindowStateManager!
    var mockStorage: MockSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockSettingsStorage()
        manager = WindowStateManager(storage: mockStorage)
    }
    
    override func tearDown() {
        manager = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testSaveAndLoadWindowState() async throws {
        // Given: A window state
        let state = WindowState(
            frame: CGRect(x: 50, y: 50, width: 1000, height: 700),
            isMaximized: false,
            isMinimised: false
        )
        
        // When: Saving and loading
        try await manager.saveWindowState(state)
        let loaded = await manager.loadWindowState()
        
        // Then: Should match
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.frame, state.frame)
        XCTAssertEqual(loaded?.isMaximized, state.isMaximized)
    }
    
    func testLoadNilWhenNoSavedState() async {
        // Given: No saved state
        // When: Loading
        let loaded = await manager.loadWindowState()
        
        // Then: Should be nil
        XCTAssertNil(loaded)
    }
    
    // MARK: - Inverse Relationships
    
    func testClearWindowState() async throws {
        // Given: A saved state
        try await manager.saveWindowState(WindowState())
        
        // When: Clearing
        try await manager.clearWindowState()
        let loaded = await manager.loadWindowState()
        
        // Then: Should be nil
        XCTAssertNil(loaded)
    }
}
