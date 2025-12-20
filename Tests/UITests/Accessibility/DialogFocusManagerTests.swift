//
//  DialogFocusManagerTests.swift
//  UITests
//
//  TDD tests for DialogFocusManager
//  Following Right-BICEP principles for comprehensive test coverage
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// TDD tests for DialogFocusManager
/// Tests focus trapping, restoration, and navigation within dialogs
@MainActor
final class DialogFocusManagerTests: XCTestCase {
    
    private var manager: DialogFocusManager!
    
    override func setUp() {
        super.setUp()
        manager = DialogFocusManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - [Right]: Focus Registration
    
    /// Test: Registering focusable elements should work
    func testRegisterFocusableElement() {
        // Given: DialogFocusManager is initialized
        // When: We register focusable elements
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        
        // Then: Elements should be registered
        manager.setFocus(to: "element-1")
        XCTAssertEqual(manager.dialogFocusIdentifier, "element-1", "Element 1 should be focusable")
    }
    
    /// Test: First and last elements should be tracked
    func testFirstAndLastElementsTracked() {
        // Given: DialogFocusManager with registered elements
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        manager.registerFocusableElement("element-3")
        
        // When: We check first and last
        // Then: Should be tracked correctly
        XCTAssertEqual(manager.firstFocusableIdentifier, "element-1", "First element should be tracked")
        XCTAssertEqual(manager.lastFocusableIdentifier, "element-3", "Last element should be tracked")
    }
    
    // MARK: - [B]: Boundary Conditions
    
    /// Test: Opening dialog with no elements should handle gracefully
    func testOpenDialogWithNoElements() {
        // Given: DialogFocusManager with no registered elements
        // When: We open dialog
        manager.openDialog(previousFocus: "previous-element")
        
        // Then: Should handle gracefully
        XCTAssertTrue(manager.isFocusTrapped, "Focus should be trapped")
        XCTAssertNil(manager.dialogFocusIdentifier, "No focus if no elements")
    }
    
    /// Test: Moving focus with no elements should return nil
    func testMoveFocusWithNoElements() {
        // Given: DialogFocusManager with no elements
        manager.openDialog(previousFocus: "previous-element")
        
        // When: We try to move focus
        let next = manager.moveFocusForward()
        
        // Then: Should return nil
        XCTAssertNil(next, "Should return nil with no elements")
    }
    
    /// Test: Moving forward from last element should wrap to first
    func testMoveForwardFromLastWraps() {
        // Given: DialogFocusManager with elements, last element focused
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        manager.openDialog(previousFocus: "previous-element")
        manager.setFocus(to: "element-2")
        
        // When: We move forward
        let next = manager.moveFocusForward()
        
        // Then: Should wrap to first
        XCTAssertEqual(next, "element-1", "Should wrap to first element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "element-1", "Focus should be on first")
    }
    
    /// Test: Moving backward from first element should wrap to last
    func testMoveBackwardFromFirstWraps() {
        // Given: DialogFocusManager with elements, first element focused
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        manager.openDialog(previousFocus: "previous-element")
        manager.setFocus(to: "element-1")
        
        // When: We move backward
        let previous = manager.moveFocusBackward()
        
        // Then: Should wrap to last
        XCTAssertEqual(previous, "element-2", "Should wrap to last element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "element-2", "Focus should be on last")
    }
    
    // MARK: - [I]: Inverse Relationships
    
    /// Test: Moving forward then backward should return to original
    func testMoveForwardThenBackward() {
        // Given: DialogFocusManager with elements, middle element focused
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        manager.registerFocusableElement("element-3")
        manager.openDialog(previousFocus: "previous-element")
        manager.setFocus(to: "element-2")
        
        // When: We move forward then backward
        _ = manager.moveFocusForward()
        let final = manager.moveFocusBackward()
        
        // Then: Should return to original
        XCTAssertEqual(final, "element-2", "Should return to original element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "element-2", "Focus should be on original")
    }
    
    // MARK: - [C]: Cross-Check
    
    /// Test: Previous focus should be saved when opening dialog
    func testPreviousFocusSaved() {
        // Given: DialogFocusManager
        // When: We open dialog with previous focus
        manager.openDialog(previousFocus: "previous-element")
        
        // Then: Previous focus should be saved
        XCTAssertEqual(manager.previousFocusIdentifier, "previous-element", "Previous focus should be saved")
    }
    
    /// Test: Closing dialog should clear focus trap
    func testCloseDialogClearsTrap() {
        // Given: DialogFocusManager with open dialog
        manager.registerFocusableElement("element-1")
        manager.openDialog(previousFocus: "previous-element")
        
        // When: We close dialog
        manager.closeDialog()
        
        // Then: Focus trap should be cleared
        XCTAssertFalse(manager.isFocusTrapped, "Focus trap should be cleared")
        XCTAssertNil(manager.dialogFocusIdentifier, "Dialog focus should be cleared")
    }
    
    // MARK: - [E]: Error Conditions
    
    /// Test: Setting focus to non-existent element should handle gracefully
    func testSetFocusToNonExistentElement() {
        // Given: DialogFocusManager with elements
        manager.registerFocusableElement("element-1")
        manager.openDialog(previousFocus: "previous-element")
        
        // When: We set focus to non-existent element
        let focusBefore = manager.dialogFocusIdentifier
        manager.setFocus(to: "non-existent")
        
        // Then: Should handle gracefully (no change from current focus)
        XCTAssertEqual(manager.dialogFocusIdentifier, focusBefore, "Focus should not change when setting to non-existent element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "element-1", "Focus should remain on first element")
    }
    
    /// Test: Unregistering element should update first/last
    func testUnregisterElementUpdatesFirstLast() {
        // Given: DialogFocusManager with elements
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        manager.registerFocusableElement("element-3")
        
        // When: We unregister first element
        manager.unregisterFocusableElement("element-1")
        
        // Then: First should be updated
        XCTAssertEqual(manager.firstFocusableIdentifier, "element-2", "First should be updated")
        XCTAssertEqual(manager.lastFocusableIdentifier, "element-3", "Last should remain")
    }
    
    // MARK: - [P]: Performance
    
    /// Test: Focus operations should be fast
    func testFocusOperationsPerformance() {
        // Given: DialogFocusManager with many elements
        for i in 0..<100 {
            manager.registerFocusableElement("element-\(i)")
        }
        manager.openDialog(previousFocus: "previous-element")
        manager.setFocus(to: "element-50")
        
        // When: We perform multiple focus operations
        measure {
            for _ in 0..<100 {
                _ = manager.moveFocusForward()
                _ = manager.moveFocusBackward()
            }
    }
}
    // MARK: - Edge Cases
    
    /// Test: Clear should remove all elements
    func testClearRemovesAllElements() {
        // Given: DialogFocusManager with elements
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        manager.openDialog(previousFocus: "previous-element")
        
        // When: We clear
        manager.clear()
        
        // Then: All elements should be removed
        XCTAssertNil(manager.firstFocusableIdentifier, "First should be nil")
        XCTAssertNil(manager.lastFocusableIdentifier, "Last should be nil")
        XCTAssertNil(manager.dialogFocusIdentifier, "Focus should be nil")
    }
    
    /// Test: Opening dialog should focus first element
    func testOpenDialogFocusesFirst() {
        // Given: DialogFocusManager with elements
        manager.registerFocusableElement("element-1")
        manager.registerFocusableElement("element-2")
        
        // When: We open dialog
        manager.openDialog(previousFocus: "previous-element")
        
        // Then: First element should be focused
        XCTAssertEqual(manager.dialogFocusIdentifier, "element-1", "First element should be focused")
    }
}
