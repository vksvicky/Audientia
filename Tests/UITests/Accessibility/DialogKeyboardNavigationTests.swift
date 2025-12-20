//
//  DialogKeyboardNavigationTests.swift
//  UITests
//
//  Integration tests for dialog keyboard navigation
//  Tests keyboard navigation in dialogs with DialogFocusManager
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// Integration tests for dialog keyboard navigation
/// Tests keyboard navigation workflows in dialogs
@MainActor
final class DialogKeyboardNavigationTests: XCTestCase {
    
    private var focusManager: DialogFocusManager!
    
    override func setUp() {
        super.setUp()
        focusManager = DialogFocusManager()
    }
    
    override func tearDown() {
        focusManager = nil
        super.tearDown()
    }
    
    // MARK: - Integration Test 1: CreatePlaylistDialog Navigation
    
    /// Test: Tab navigation should work in CreatePlaylistDialog
    func testCreatePlaylistDialogTabNavigation() {
        // Given: CreatePlaylistDialog is set up with focusable elements
        focusManager.registerFocusableElement("text-field")
        focusManager.registerFocusableElement("cancel-button")
        focusManager.registerFocusableElement("create-button")
        focusManager.openDialog(previousFocus: "main-window-button")
        focusManager.setFocus(to: "text-field")
        
        // When: User presses Tab
        let next = focusManager.moveFocusForward()
        
        // Then: Focus should move to cancel button
        XCTAssertEqual(next, "cancel-button", "Focus should move to cancel button")
        XCTAssertEqual(focusManager.dialogFocusIdentifier, "cancel-button", "Focus should be on cancel button")
    }
    
    /// Test: Shift+Tab navigation should work in CreatePlaylistDialog
    func testCreatePlaylistDialogShiftTabNavigation() {
        // Given: CreatePlaylistDialog with create button focused
        focusManager.registerFocusableElement("text-field")
        focusManager.registerFocusableElement("cancel-button")
        focusManager.registerFocusableElement("create-button")
        focusManager.openDialog(previousFocus: "main-window-button")
        focusManager.setFocus(to: "create-button")
        
        // When: User presses Shift+Tab
        let previous = focusManager.moveFocusBackward()
        
        // Then: Focus should move to cancel button
        XCTAssertEqual(previous, "cancel-button", "Focus should move to cancel button")
        XCTAssertEqual(focusManager.dialogFocusIdentifier, "cancel-button", "Focus should be on cancel button")
    }
    
    /// Test: Tab from last element should wrap to first
    func testCreatePlaylistDialogTabWrapping() {
        // Given: CreatePlaylistDialog with create button focused
        focusManager.registerFocusableElement("text-field")
        focusManager.registerFocusableElement("cancel-button")
        focusManager.registerFocusableElement("create-button")
        focusManager.openDialog(previousFocus: "main-window-button")
        focusManager.setFocus(to: "create-button")
        
        // When: User presses Tab
        let next = focusManager.moveFocusForward()
        
        // Then: Focus should wrap to text field
        XCTAssertEqual(next, "text-field", "Focus should wrap to text field")
        XCTAssertEqual(focusManager.dialogFocusIdentifier, "text-field", "Focus should be on text field")
    }
    
    // MARK: - Integration Test 2: Focus Trapping
    
    /// Test: Focus should be trapped within dialog
    func testFocusTrappingInDialog() {
        // Given: Dialog is open
        focusManager.registerFocusableElement("text-field")
        focusManager.registerFocusableElement("cancel-button")
        focusManager.openDialog(previousFocus: "main-window-button")
        
        // When: User navigates
        // Then: Focus should remain trapped
        XCTAssertTrue(focusManager.isFocusTrapped, "Focus should be trapped")
        
        // When: Dialog is closed
        focusManager.closeDialog()
        
        // Then: Focus trap should be cleared
        XCTAssertFalse(focusManager.isFocusTrapped, "Focus trap should be cleared")
    }
    
    // MARK: - Integration Test 3: Focus Restoration
    
    /// Test: Previous focus should be saved when opening dialog
    func testPreviousFocusSaved() {
        // Given: Main window has a focused element
        // When: Dialog is opened
        focusManager.registerFocusableElement("text-field")
        focusManager.openDialog(previousFocus: "main-window-button")
        
        // Then: Previous focus should be saved
        XCTAssertEqual(focusManager.previousFocusIdentifier, "main-window-button", "Previous focus should be saved")
    }
    
    // MARK: - Integration Test 4: Multiple Dialogs
    
    /// Test: Multiple dialogs should handle focus correctly
    func testMultipleDialogsFocusManagement() {
        // Given: First dialog
        let dialog1 = DialogFocusManager()
        dialog1.registerFocusableElement("dialog1-element")
        dialog1.openDialog(previousFocus: "main-window-button")
        
        // When: Second dialog opens
        let dialog2 = DialogFocusManager()
        dialog2.registerFocusableElement("dialog2-element")
        dialog2.openDialog(previousFocus: dialog1.dialogFocusIdentifier)
        
        // Then: Second dialog should have its own focus
        XCTAssertTrue(dialog2.isFocusTrapped, "Second dialog should trap focus")
        XCTAssertNotNil(dialog2.dialogFocusIdentifier, "Second dialog should have focus")
        
        // When: Second dialog closes
        dialog2.closeDialog()
        
        // Then: First dialog should still be open
        XCTAssertTrue(dialog1.isFocusTrapped, "First dialog should still trap focus")
    }
}
