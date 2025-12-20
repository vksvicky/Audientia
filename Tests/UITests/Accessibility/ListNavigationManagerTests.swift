//
//  ListNavigationManagerTests.swift
//  UITests
//
//  TDD tests for ListNavigationManager
//  Following Right-BICEP principles for comprehensive test coverage
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// TDD tests for ListNavigationManager
/// Tests arrow key navigation, selection management, and list operations
@MainActor
final class ListNavigationManagerTests: XCTestCase {
    
    private var manager: ListNavigationManager<String>!
    
    override func setUp() {
        super.setUp()
        manager = ListNavigationManager<String>()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - [Right]: Selection Management
    
    /// Test: Selected index should be nil initially
    func testSelectedIndexIsNilInitially() {
        // Given: ListNavigationManager is initialized
        // When: We check selected index
        // Then: Selected index should be nil
        
        XCTAssertNil(manager.selectedIndex, "Selected index should be nil initially")
    }
    
    /// Test: Selecting an index should work
    func testSelectIndex() {
        // Given: Manager has items
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        
        // When: We select an index
        manager.selectIndex(1)
        
        // Then: Selected index should be set
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should be set")
        XCTAssertEqual(manager.selectedItem, "Item 2", "Selected item should match")
    }
    
    /// Test: Selecting an item by value should work
    func testSelectItem() {
        // Given: Manager has items
        let items = ["Item 1", "Item 2", "Item 3"]
        manager.updateItems(items)
        
        // When: We select an item by value
        manager.selectItem("Item 2")
        
        // Then: Selected index should be set correctly
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should be set to item's index")
        XCTAssertEqual(manager.selectedItem, "Item 2", "Selected item should match")
    }
    
    // MARK: - [B]: Boundary Conditions
    
    /// Test: Selecting index out of bounds should handle gracefully
    func testSelectIndexOutOfBounds() {
        // Given: Manager has 3 items
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        
        // When: We select an index out of bounds
        manager.selectIndex(10)
        
        // Then: Should handle gracefully (no crash, index adjusted or nil)
        // The implementation adjusts to last valid index
        XCTAssertNotNil(manager.selectedIndex, "Should adjust to valid index")
        if let index = manager.selectedIndex {
            XCTAssertLessThan(index, 3, "Index should be within bounds")
        }
    }
    
    /// Test: Moving up from first item should wrap to last
    func testMoveUpFromFirstWraps() {
        // Given: Manager has items and first item is selected
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        manager.selectIndex(0)
        
        // When: We move up
        let newIndex = manager.moveUp()
        
        // Then: Should wrap to last item
        XCTAssertEqual(newIndex, 2, "Should wrap to last item")
        XCTAssertEqual(manager.selectedIndex, 2, "Selected index should be last")
    }
    
    /// Test: Moving down from last item should wrap to first
    func testMoveDownFromLastWraps() {
        // Given: Manager has items and last item is selected
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        manager.selectIndex(2)
        
        // When: We move down
        let newIndex = manager.moveDown()
        
        // Then: Should wrap to first item
        XCTAssertEqual(newIndex, 0, "Should wrap to first item")
        XCTAssertEqual(manager.selectedIndex, 0, "Selected index should be first")
    }
    
    /// Test: Moving up with no selection should select last item
    func testMoveUpWithNoSelection() {
        // Given: Manager has items but no selection
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        
        // When: We move up
        let newIndex = manager.moveUp()
        
        // Then: Should select last item
        XCTAssertEqual(newIndex, 2, "Should select last item")
        XCTAssertEqual(manager.selectedIndex, 2, "Selected index should be last")
    }
    
    /// Test: Moving down with no selection should select first item
    func testMoveDownWithNoSelection() {
        // Given: Manager has items but no selection
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        
        // When: We move down
        let newIndex = manager.moveDown()
        
        // Then: Should select first item
        XCTAssertEqual(newIndex, 0, "Should select first item")
        XCTAssertEqual(manager.selectedIndex, 0, "Selected index should be first")
    }
    
    /// Test: Moving with empty list should return nil
    func testMoveWithEmptyList() {
        // Given: Manager has no items
        manager.updateItems([])
        
        // When: We try to move
        let upIndex = manager.moveUp()
        let downIndex = manager.moveDown()
        
        // Then: Should return nil
        XCTAssertNil(upIndex, "Moving up with empty list should return nil")
        XCTAssertNil(downIndex, "Moving down with empty list should return nil")
    }
    
    // MARK: - [I]: Inverse Relationships
    
    /// Test: Moving up then down should return to original
    func testMoveUpThenDown() {
        // Given: Manager has items and item at index 1 is selected
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        manager.selectIndex(1)
        
        // When: We move up then down
        _ = manager.moveUp()
        let finalIndex = manager.moveDown()
        
        // Then: Should return to original index
        XCTAssertEqual(finalIndex, 1, "Should return to original index")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should match original")
    }
    
    /// Test: Moving down then up should return to original
    func testMoveDownThenUp() {
        // Given: Manager has items and item at index 1 is selected
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        manager.selectIndex(1)
        
        // When: We move down then up
        _ = manager.moveDown()
        let finalIndex = manager.moveUp()
        
        // Then: Should return to original index
        XCTAssertEqual(finalIndex, 1, "Should return to original index")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should match original")
    }
    
    // MARK: - [C]: Cross-Check
    
    /// Test: Selected item should match items array
    func testSelectedItemMatchesArray() {
        // Given: Manager has items
        let items = ["Item 1", "Item 2", "Item 3"]
        manager.updateItems(items)
        
        // When: We select index 1
        manager.selectIndex(1)
        
        // Then: Selected item should match array item at that index
        XCTAssertEqual(manager.selectedItem, items[1], "Selected item should match array")
    }
    
    // MARK: - [E]: Error Conditions
    
    /// Test: Selecting negative index should handle gracefully
    func testSelectNegativeIndex() {
        // Given: Manager has items
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        
        // When: We select a negative index
        manager.selectIndex(-1)
        
        // Then: Should handle gracefully (set to nil or adjust)
        // Implementation sets to nil for negative indices
        XCTAssertNil(manager.selectedIndex, "Negative index should result in nil selection")
    }
    
    /// Test: Updating items should adjust selection if out of bounds
    func testUpdateItemsAdjustsSelection() {
        // Given: Manager has 5 items and index 3 is selected
        manager.updateItems(["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"])
        manager.selectIndex(3)
        
        // When: We update to 2 items
        manager.updateItems(["Item 1", "Item 2"])
        
        // Then: Selection should be adjusted
        XCTAssertNotNil(manager.selectedIndex, "Selection should be adjusted")
        if let index = manager.selectedIndex {
            XCTAssertLessThan(index, 2, "Index should be within new bounds")
        }
    }
    
    // MARK: - [P]: Performance
    
    /// Test: Navigation operations should be fast
    func testNavigationPerformance() {
        // Given: Manager has many items
        let items = (0..<1000).map { "Item \($0)" }
        manager.updateItems(items)
        manager.selectIndex(500)
        
        // When: We perform multiple navigation operations
        measure {
            for _ in 0..<100 {
                _ = manager.moveDown()
                _ = manager.moveUp()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// Test: Single item list navigation
    func testSingleItemList() {
        // Given: Manager has one item
        manager.updateItems(["Item 1"])
        manager.selectIndex(0)
        
        // When: We move up or down
        let upIndex = manager.moveUp()
        let downIndex = manager.moveDown()
        
        // Then: Should stay on the same item (wraps to itself)
        XCTAssertEqual(upIndex, 0, "Moving up from single item should wrap to itself")
        XCTAssertEqual(downIndex, 0, "Moving down from single item should wrap to itself")
    }
    
    /// Test: Clear selection should work
    func testClearSelection() {
        // Given: Manager has items and an item is selected
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        manager.selectIndex(1)
        
        // When: We clear selection
        manager.clearSelection()
        
        // Then: Selection should be nil
        XCTAssertNil(manager.selectedIndex, "Selection should be cleared")
        XCTAssertNil(manager.selectedItem, "Selected item should be nil")
    }
    
    /// Test: Select first and last should work
    func testSelectFirstAndLast() {
        // Given: Manager has items
        manager.updateItems(["Item 1", "Item 2", "Item 3"])
        
        // When: We select first
        manager.selectFirst()
        XCTAssertEqual(manager.selectedIndex, 0, "Select first should select index 0")
        
        // And: We select last
        manager.selectLast()
        XCTAssertEqual(manager.selectedIndex, 2, "Select last should select last index")
    }
    
    // MARK: - Grid Navigation
    
    /// Test: Move left in grid should work
    func testMoveLeftInGrid() {
        // Given: Manager has items in a 3-column grid
        let items = (0..<9).map { "Item \($0)" }
        manager.updateItems(items)
        manager.selectIndex(4) // Middle of second row
        
        // When: We move left
        let newIndex = manager.moveLeft(columnsPerRow: 3)
        
        // Then: Should move to previous row
        XCTAssertEqual(newIndex, 1, "Should move to previous row")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should be in previous row")
    }
    
    /// Test: Move right in grid should work
    func testMoveRightInGrid() {
        // Given: Manager has items in a 3-column grid
        let items = (0..<9).map { "Item \($0)" }
        manager.updateItems(items)
        manager.selectIndex(1) // Middle of first row
        
        // When: We move right
        let newIndex = manager.moveRight(columnsPerRow: 3)
        
        // Then: Should move to next row
        XCTAssertEqual(newIndex, 4, "Should move to next row")
        XCTAssertEqual(manager.selectedIndex, 4, "Selected index should be in next row")
    }
    
    /// Test: Move left from first row should wrap
    func testMoveLeftFromFirstRowWraps() {
        // Given: Manager has items in a 3-column grid, first row selected
        let items = (0..<9).map { "Item \($0)" }
        manager.updateItems(items)
        manager.selectIndex(1) // First row
        
        // When: We move left
        let newIndex = manager.moveLeft(columnsPerRow: 3)
        
        // Then: Should wrap to last row
        XCTAssertEqual(newIndex, 7, "Should wrap to last row, same column")
        XCTAssertEqual(manager.selectedIndex, 7, "Selected index should be in last row")
    }
    
    /// Test: Move right from last row should wrap
    func testMoveRightFromLastRowWraps() {
        // Given: Manager has items in a 3-column grid, last row selected
        let items = (0..<9).map { "Item \($0)" }
        manager.updateItems(items)
        manager.selectIndex(7) // Last row
        
        // When: We move right
        let newIndex = manager.moveRight(columnsPerRow: 3)
        
        // Then: Should wrap to first row
        XCTAssertEqual(newIndex, 1, "Should wrap to first row, same column")
        XCTAssertEqual(manager.selectedIndex, 1, "Selected index should be in first row")
    }
}
