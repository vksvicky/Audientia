//
//  LayoutStateTests.swift
//  AudientiaTests
//
//  TDD and BDD tests for LayoutState and LayoutStateManager
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import Shared
import XCTest

// MARK: - TDD Tests
final class LayoutStateTests: XCTestCase {
    
    // MARK: - Right-BICEP: Are the Results Right?
    
    func testDefaultLayoutState() {
        let state = LayoutState.default
        
        XCTAssertTrue(state.isToolbarExpanded, "Default toolbar should be expanded")
        XCTAssertTrue(state.isPlayerExpanded, "Default player should be expanded")
    }
    
    func testCustomLayoutState() {
        let state = LayoutState(
            isToolbarExpanded: false,
            isPlayerExpanded: false
        )
        
        XCTAssertFalse(state.isToolbarExpanded, "Toolbar should be collapsed")
        XCTAssertFalse(state.isPlayerExpanded, "Player should be collapsed")
    }
    
    func testLayoutStateEquality() {
        let state1 = LayoutState(isToolbarExpanded: true, isPlayerExpanded: false)
        let state2 = LayoutState(isToolbarExpanded: true, isPlayerExpanded: false)
        let state3 = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        
        XCTAssertEqual(state1, state2, "States with same values should be equal")
        XCTAssertNotEqual(state1, state3, "States with different values should not be equal")
    }
    
    // MARK: - Right-BICEP: Boundary Conditions
    
    func testLayoutStateCodable() throws {
        let state = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        
        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(LayoutState.self, from: data)
        
        XCTAssertEqual(state, decodedState, "Encoded and decoded state should match")
    }
}

final class LayoutStateManagerTests: XCTestCase {
    
    // MARK: - Right-BICEP: Are the Results Right?
    
    func testSaveAndLoadLayoutState() async throws {
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let state = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        
        try await manager.saveLayoutState(state)
        let loadedState = await manager.loadLayoutState()
        
        XCTAssertEqual(state, loadedState, "Loaded state should match saved state")
    }
    
    func testLoadDefaultStateWhenNoSavedState() async {
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let loadedState = await manager.loadLayoutState()
        
        XCTAssertEqual(loadedState, LayoutState.default, "Should return default state when no saved state exists")
    }
    
    func testResetToDefault() async throws {
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let customState = LayoutState(isToolbarExpanded: false, isPlayerExpanded: false)
        try await manager.saveLayoutState(customState)
        
        try await manager.resetToDefault()
        let loadedState = await manager.loadLayoutState()
        
        XCTAssertEqual(loadedState, LayoutState.default, "Reset should restore default state")
    }
    
    // MARK: - Right-BICEP: Boundary Conditions
    
    func testSaveMultipleStates() async throws {
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let state1 = LayoutState(isToolbarExpanded: true, isPlayerExpanded: false)
        try await manager.saveLayoutState(state1)
        
        let state2 = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        try await manager.saveLayoutState(state2)
        
        let loadedState = await manager.loadLayoutState()
        XCTAssertEqual(loadedState, state2, "Should load the most recently saved state")
    }
    
    // MARK: - Right-BICEP: Forcing Error Conditions
    
    func testSaveStateWithError() async {
        let mockStorage = MockSettingsStorage()
        await mockStorage.setShouldThrowError(true, error: NSError(domain: "TestError", code: 1))
        let manager = LayoutStateManager(storage: mockStorage)
        
        let state = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        
        do {
            try await manager.saveLayoutState(state)
            XCTFail("Should throw error when storage fails")
        } catch {
            XCTAssertNotNil(error, "Should propagate storage error")
        }
    }
    
    func testLoadStateWithError() async {
        let mockStorage = MockSettingsStorage()
        await mockStorage.setShouldThrowError(true, error: NSError(domain: "TestError", code: 1))
        let manager = LayoutStateManager(storage: mockStorage)
        
        // Should return default state even when storage throws error
        let loadedState = await manager.loadLayoutState()
        XCTAssertEqual(loadedState, LayoutState.default, "Should return default state when load fails")
    }
    
    // MARK: - Right-BICEP: Performance Characteristics
    
    func testSaveStatePerformance() async throws {
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        let state = LayoutState(isToolbarExpanded: true, isPlayerExpanded: false)
        
        measure {
            Task {
                try? await manager.saveLayoutState(state)
            }
        }
    }
    
    func testLoadStatePerformance() async {
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        let state = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        try? await manager.saveLayoutState(state)
        
        measure {
            Task {
                _ = await manager.loadLayoutState()
            }
        }
    }
}

// MARK: - BDD Tests

final class LayoutStateManagerBDDTests: XCTestCase {
    
    func testScenarioUserCollapsesToolbarAndRestartsApp() async throws {
        // Given: User collapses the toolbar
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let collapsedState = LayoutState(isToolbarExpanded: false, isPlayerExpanded: true)
        try await manager.saveLayoutState(collapsedState)
        
        // When: App restarts and loads state
        let loadedState = await manager.loadLayoutState()
        
        // Then: Toolbar should remain collapsed
        XCTAssertFalse(loadedState.isToolbarExpanded, "Toolbar should remain collapsed after restart")
        XCTAssertTrue(loadedState.isPlayerExpanded, "Player should remain expanded")
    }
    
    func testScenarioUserCollapsesPlayerAndRestartsApp() async throws {
        // Given: User collapses the player
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let collapsedState = LayoutState(isToolbarExpanded: true, isPlayerExpanded: false)
        try await manager.saveLayoutState(collapsedState)
        
        // When: App restarts and loads state
        let loadedState = await manager.loadLayoutState()
        
        // Then: Player should remain collapsed
        XCTAssertTrue(loadedState.isToolbarExpanded, "Toolbar should remain expanded")
        XCTAssertFalse(loadedState.isPlayerExpanded, "Player should remain collapsed after restart")
    }
    
    func testScenarioUserCollapsesBothAndRestartsApp() async throws {
        // Given: User collapses both toolbar and player
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let collapsedState = LayoutState(isToolbarExpanded: false, isPlayerExpanded: false)
        try await manager.saveLayoutState(collapsedState)
        
        // When: App restarts and loads state
        let loadedState = await manager.loadLayoutState()
        
        // Then: Both should remain collapsed
        XCTAssertFalse(loadedState.isToolbarExpanded, "Toolbar should remain collapsed")
        XCTAssertFalse(loadedState.isPlayerExpanded, "Player should remain collapsed")
    }
    
    func testScenarioUserResetsToDefault() async throws {
        // Given: User has custom layout state
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        let customState = LayoutState(isToolbarExpanded: false, isPlayerExpanded: false)
        try await manager.saveLayoutState(customState)
        
        // When: User resets to default
        try await manager.resetToDefault()
        
        // Then: State should be restored to default
        let loadedState = await manager.loadLayoutState()
        XCTAssertEqual(loadedState, LayoutState.default, "State should be restored to default")
        XCTAssertTrue(loadedState.isToolbarExpanded, "Toolbar should be expanded by default")
        XCTAssertTrue(loadedState.isPlayerExpanded, "Player should be expanded by default")
    }
    
    func testScenarioFirstTimeUser() async {
        // Given: First time user (no saved state)
        let mockStorage = MockSettingsStorage()
        let manager = LayoutStateManager(storage: mockStorage)
        
        // When: App loads state
        let loadedState = await manager.loadLayoutState()
        
        // Then: Should use default state
        XCTAssertEqual(loadedState, LayoutState.default, "Should use default state for first-time user")
        XCTAssertTrue(loadedState.isToolbarExpanded, "Toolbar should be expanded by default")
        XCTAssertTrue(loadedState.isPlayerExpanded, "Player should be expanded by default")
    }
}
