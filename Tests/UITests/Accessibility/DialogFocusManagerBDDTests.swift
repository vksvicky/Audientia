//
//  DialogFocusManagerBDDTests.swift
//  UITests
//
//  BDD tests for DialogFocusManager
//  User scenario tests for dialog focus management workflows
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// BDD tests for DialogFocusManager
/// Tests user scenarios for dialog focus management
@MainActor
final class DialogFocusManagerBDDTests: XCTestCase {
    
    private var manager: DialogFocusManager!
    
    override func setUp() {
        super.setUp()
        manager = DialogFocusManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Dialog Focus Trapping
    
    /// BDD: As a keyboard-only user, when I open a dialog,
    /// then focus should be trapped within the dialog
    func testScenario_KeyboardUserOpensDialog() {
        // Given: I am a keyboard-only user
        // And: I have a dialog with focusable elements
        manager.registerFocusableElement("text-field")
        manager.registerFocusableElement("cancel-button")
        manager.registerFocusableElement("submit-button")
        
        // When: I open the dialog
        manager.openDialog(previousFocus: "main-window-button")
        
        // Then: Focus should be trapped in the dialog
        XCTAssertTrue(manager.isFocusTrapped, "Focus should be trapped")
        XCTAssertNotNil(manager.dialogFocusIdentifier, "An element should be focused")
        XCTAssertEqual(manager.previousFocusIdentifier, "main-window-button", "Previous focus should be saved")
    }
    
    /// BDD: As a keyboard-only user, when I press Tab in a dialog,
    /// then focus should move to the next element within the dialog
    func testScenario_KeyboardUserNavigatesInDialog() {
        // Given: I am a keyboard-only user
        // And: I have a dialog with multiple elements
        manager.registerFocusableElement("text-field")
        manager.registerFocusableElement("cancel-button")
        manager.registerFocusableElement("submit-button")
        manager.openDialog(previousFocus: "main-window-button")
        manager.setFocus(to: "text-field")
        
        // When: I press Tab
        let next = manager.moveFocusForward()
        
        // Then: Focus should move to the next element
        XCTAssertEqual(next, "cancel-button", "Focus should move to next element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "cancel-button", "Focus should be on cancel button")
    }
    
    // MARK: - BDD Scenario 2: Focus Wrapping
    
    /// BDD: As a keyboard-only user, when I press Tab from the last element in a dialog,
    /// then focus should wrap to the first element
    func testScenario_KeyboardUserWrapsInDialog() {
        // Given: I am a keyboard-only user
        // And: I have a dialog with the last element focused
        manager.registerFocusableElement("text-field")
        manager.registerFocusableElement("cancel-button")
        manager.registerFocusableElement("submit-button")
        manager.openDialog(previousFocus: "main-window-button")
        manager.setFocus(to: "submit-button")
        
        // When: I press Tab
        let next = manager.moveFocusForward()
        
        // Then: Focus should wrap to the first element
        XCTAssertEqual(next, "text-field", "Focus should wrap to first element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "text-field", "Focus should be on first element")
    }
    
    /// BDD: As a keyboard-only user, when I press Shift+Tab from the first element in a dialog,
    /// then focus should wrap to the last element
    func testScenario_KeyboardUserWrapsBackwardInDialog() {
        // Given: I am a keyboard-only user
        // And: I have a dialog with the first element focused
        manager.registerFocusableElement("text-field")
        manager.registerFocusableElement("cancel-button")
        manager.registerFocusableElement("submit-button")
        manager.openDialog(previousFocus: "main-window-button")
        manager.setFocus(to: "text-field")
        
        // When: I press Shift+Tab
        let previous = manager.moveFocusBackward()
        
        // Then: Focus should wrap to the last element
        XCTAssertEqual(previous, "submit-button", "Focus should wrap to last element")
        XCTAssertEqual(manager.dialogFocusIdentifier, "submit-button", "Focus should be on last element")
    }
    
    // MARK: - BDD Scenario 3: Focus Restoration
    
    /// BDD: As a keyboard-only user, when I close a dialog,
    /// then focus should be restored to the previous element
    func testScenario_KeyboardUserClosesDialog() {
        // Given: I am a keyboard-only user
        // And: I have an open dialog
        manager.registerFocusableElement("text-field")
        manager.openDialog(previousFocus: "main-window-button")
        
        // When: I close the dialog
        manager.closeDialog()
        
        // Then: Focus trap should be cleared
        XCTAssertFalse(manager.isFocusTrapped, "Focus trap should be cleared")
        XCTAssertNil(manager.dialogFocusIdentifier, "Dialog focus should be cleared")
        // Note: Actual focus restoration would be handled by the view
    }
    
    // MARK: - BDD Scenario 4: Initial Focus
    
    /// BDD: As a keyboard-only user, when I open a dialog,
    /// then the first element should be focused automatically
    func testScenario_KeyboardUserOpensDialogFirstElementFocused() {
        // Given: I am a keyboard-only user
        // And: I have a dialog with elements
        manager.registerFocusableElement("text-field")
        manager.registerFocusableElement("cancel-button")
        manager.registerFocusableElement("submit-button")
        
        // When: I open the dialog
        manager.openDialog(previousFocus: "main-window-button")
        
        // Then: The first element should be focused
        XCTAssertEqual(manager.dialogFocusIdentifier, "text-field", "First element should be focused")
    }
}
