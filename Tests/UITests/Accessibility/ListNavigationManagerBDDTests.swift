//
//  ListNavigationManagerBDDTests.swift
//  UITests
//
//  BDD tests for ListNavigationManager
//  User scenario tests for arrow key navigation workflows
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// BDD tests for ListNavigationManager
/// Tests user scenarios for arrow key navigation
@MainActor
final class ListNavigationManagerBDDTests: XCTestCase {
    
    private var manager: ListNavigationManager<String>!
    
    override func setUp() {
        super.setUp()
        manager = ListNavigationManager<String>()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Basic Arrow Key Navigation
    
    /// BDD: As a keyboard-only user, when I press Down arrow in a list,
    /// then selection should move to the next item
    func testScenario_KeyboardUserNavigatesDownInList() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        manager.selectIndex(0)
        
        // When: I press the Down arrow key
        let newIndex = manager.moveDown()
        
        // Then: Selection should move to the next item
        XCTAssertEqual(newIndex, 1, "Down arrow should move to next item")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should be 1")
        XCTAssertEqual(manager.selectedItem, "Track 2", "Selected item should be Track 2")
    }
    
    /// BDD: As a keyboard-only user, when I press Up arrow in a list,
    /// then selection should move to the previous item
    func testScenario_KeyboardUserNavigatesUpInList() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks with Track 2 selected
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        manager.selectIndex(1)
        
        // When: I press the Up arrow key
        let newIndex = manager.moveUp()
        
        // Then: Selection should move to the previous item
        XCTAssertEqual(newIndex, 0, "Up arrow should move to previous item")
        XCTAssertEqual(manager.selectedIndex, 0, "Selected index should be 0")
        XCTAssertEqual(manager.selectedItem, "Track 1", "Selected item should be Track 1")
    }
    
    // MARK: - BDD Scenario 2: Arrow Key Wrapping
    
    /// BDD: As a keyboard-only user, when I press Down arrow from the last item,
    /// then selection should wrap to the first item
    func testScenario_KeyboardUserWrapsFromLastToFirst() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks with the last track selected
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        manager.selectIndex(2)
        
        // When: I press the Down arrow key
        let newIndex = manager.moveDown()
        
        // Then: Selection should wrap to the first item
        XCTAssertEqual(newIndex, 0, "Down arrow from last should wrap to first")
        XCTAssertEqual(manager.selectedIndex, 0, "Selected index should be 0")
        XCTAssertEqual(manager.selectedItem, "Track 1", "Selected item should be Track 1")
    }
    
    /// BDD: As a keyboard-only user, when I press Up arrow from the first item,
    /// then selection should wrap to the last item
    func testScenario_KeyboardUserWrapsFromFirstToLast() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks with the first track selected
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        manager.selectIndex(0)
        
        // When: I press the Up arrow key
        let newIndex = manager.moveUp()
        
        // Then: Selection should wrap to the last item
        XCTAssertEqual(newIndex, 2, "Up arrow from first should wrap to last")
        XCTAssertEqual(manager.selectedIndex, 2, "Selected index should be 2")
        XCTAssertEqual(manager.selectedItem, "Track 3", "Selected item should be Track 3")
    }
    
    // MARK: - BDD Scenario 3: Initial Selection
    
    /// BDD: As a keyboard-only user, when I press Down arrow with no selection,
    /// then the first item should be selected
    func testScenario_KeyboardUserStartsNavigationWithDownArrow() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks with no selection
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        
        // When: I press the Down arrow key
        let newIndex = manager.moveDown()
        
        // Then: The first item should be selected
        XCTAssertEqual(newIndex, 0, "Down arrow with no selection should select first item")
        XCTAssertEqual(manager.selectedIndex, 0, "Selected index should be 0")
        XCTAssertEqual(manager.selectedItem, "Track 1", "Selected item should be Track 1")
    }
    
    /// BDD: As a keyboard-only user, when I press Up arrow with no selection,
    /// then the last item should be selected
    func testScenario_KeyboardUserStartsNavigationWithUpArrow() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks with no selection
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        
        // When: I press the Up arrow key
        let newIndex = manager.moveUp()
        
        // Then: The last item should be selected
        XCTAssertEqual(newIndex, 2, "Up arrow with no selection should select last item")
        XCTAssertEqual(manager.selectedIndex, 2, "Selected index should be 2")
        XCTAssertEqual(manager.selectedItem, "Track 3", "Selected item should be Track 3")
    }
    
    // MARK: - BDD Scenario 4: Grid Navigation
    
    /// BDD: As a keyboard-only user, when I press Right arrow in a grid,
    /// then selection should move to the next row
    func testScenario_KeyboardUserNavigatesRightInGrid() {
        // Given: I am a keyboard-only user
        // And: I have a 3-column grid of tracks
        let items = (0..<9).map { "Track \($0)" }
        manager.updateItems(items)
        manager.selectIndex(1) // First row, middle column
        
        // When: I press the Right arrow key
        let newIndex = manager.moveRight(columnsPerRow: 3)
        
        // Then: Selection should move to the next row, same column
        XCTAssertEqual(newIndex, 4, "Right arrow should move to next row")
        XCTAssertEqual(manager.selectedIndex, 4, "Selected index should be in next row")
    }
    
    /// BDD: As a keyboard-only user, when I press Left arrow in a grid,
    /// then selection should move to the previous row
    func testScenario_KeyboardUserNavigatesLeftInGrid() {
        // Given: I am a keyboard-only user
        // And: I have a 3-column grid of tracks
        let items = (0..<9).map { "Track \($0)" }
        manager.updateItems(items)
        manager.selectIndex(4) // Second row, middle column
        
        // When: I press the Left arrow key
        let newIndex = manager.moveLeft(columnsPerRow: 3)
        
        // Then: Selection should move to the previous row, same column
        XCTAssertEqual(newIndex, 1, "Left arrow should move to previous row")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should be in previous row")
    }
    
    // MARK: - BDD Scenario 5: Selection Roundtrip
    
    /// BDD: As a keyboard-only user, when I navigate down then up,
    /// then I should return to my original selection
    func testScenario_KeyboardUserReturnsToOriginalSelection() {
        // Given: I am a keyboard-only user
        // And: I have a list with Track 2 selected
        manager.updateItems(["Track 1", "Track 2", "Track 3"])
        manager.selectIndex(1)
        
        // When: I press Down arrow, then Up arrow
        _ = manager.moveDown()
        let finalIndex = manager.moveUp()
        
        // Then: I should return to Track 2
        XCTAssertEqual(finalIndex, 1, "Should return to original selection")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should match original")
        XCTAssertEqual(manager.selectedItem, "Track 2", "Selected item should match original")
    }
    
    // MARK: - BDD Scenario 6: Item Selection
    
    /// BDD: As a keyboard-only user, when I want to select a specific track,
    /// then I can select it by value
    func testScenario_KeyboardUserSelectsSpecificItem() {
        // Given: I am a keyboard-only user
        // And: I have a list of tracks
        let items = ["Track 1", "Track 2", "Track 3"]
        manager.updateItems(items)
        
        // When: I want to select "Track 2"
        manager.selectItem("Track 2")
        
        // Then: Track 2 should be selected
        XCTAssertEqual(manager.selectedIndex, 1, "Track 2 should be at index 1")
        XCTAssertEqual(manager.selectedItem, "Track 2", "Selected item should be Track 2")
    }
    
    // MARK: - BDD Scenario 7: Empty List Handling
    
    /// BDD: As a keyboard-only user, when I press arrow keys in an empty list,
    /// then nothing should happen
    func testScenario_KeyboardUserNavigatesEmptyList() {
        // Given: I am a keyboard-only user
        // And: I have an empty list
        manager.updateItems([])
        
        // When: I press Down or Up arrow keys
        let downIndex = manager.moveDown()
        let upIndex = manager.moveUp()
        
        // Then: Nothing should happen (no selection)
        XCTAssertNil(downIndex, "Down arrow in empty list should return nil")
        XCTAssertNil(upIndex, "Up arrow in empty list should return nil")
        XCTAssertNil(manager.selectedIndex, "No selection in empty list")
    }
}
