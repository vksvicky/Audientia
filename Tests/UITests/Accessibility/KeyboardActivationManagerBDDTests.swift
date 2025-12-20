//
//  KeyboardActivationManagerBDDTests.swift
//  UITests
//
//  BDD tests for KeyboardActivationManager
//  User scenario tests for Enter/Space/Escape activation workflows
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// Mock activatable element for BDD testing
private final class MockActivatable: KeyboardActivatable {
    var activateCalled = false
    var toggleCalled = false
    var cancelCalled = false
    
    func activate() {
        activateCalled = true
    }
    
    func toggle() {
        toggleCalled = true
    }
    
    func cancel() {
        cancelCalled = true
    }
}

/// BDD tests for KeyboardActivationManager
/// Tests user scenarios for keyboard activation
@MainActor
final class KeyboardActivationManagerBDDTests: XCTestCase {
    
    private var manager: KeyboardActivationManager!
    private var mockElement: MockActivatable!
    
    override func setUp() {
        super.setUp()
        manager = KeyboardActivationManager()
        mockElement = MockActivatable()
    }
    
    override func tearDown() {
        mockElement = nil
        manager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Enter Key Activation
    
    /// BDD: As a keyboard-only user, when I press Enter on a focused button,
    /// then the button should be activated
    func testScenario_KeyboardUserActivatesWithEnter() {
        // Given: I am a keyboard-only user
        // And: I have a focused button
        manager.register(mockElement, identifier: "test-button")
        manager.setFocus(to: "test-button")
        
        // When: I press the Enter key
        let handled = manager.handleEnter()
        
        // Then: The button should be activated
        XCTAssertTrue(handled, "Enter key should be handled")
        XCTAssertTrue(mockElement.activateCalled, "Button should be activated")
        XCTAssertFalse(mockElement.toggleCalled, "Toggle should not be called")
        XCTAssertFalse(mockElement.cancelCalled, "Cancel should not be called")
    }
    
    // MARK: - BDD Scenario 2: Space Key Toggle
    
    /// BDD: As a keyboard-only user, when I press Space on a focused toggle button,
    /// then the toggle state should change
    func testScenario_KeyboardUserTogglesWithSpace() {
        // Given: I am a keyboard-only user
        // And: I have a focused toggle button
        manager.register(mockElement, identifier: "test-toggle")
        manager.setFocus(to: "test-toggle")
        
        // When: I press the Space key
        let handled = manager.handleSpace()
        
        // Then: The toggle state should change
        XCTAssertTrue(handled, "Space key should be handled")
        XCTAssertTrue(mockElement.toggleCalled, "Toggle should be called")
        XCTAssertFalse(mockElement.activateCalled, "Activate should not be called")
        XCTAssertFalse(mockElement.cancelCalled, "Cancel should not be called")
    }
    
    // MARK: - BDD Scenario 3: Escape Key Cancel
    
    /// BDD: As a keyboard-only user, when I press Escape on a focused dialog,
    /// then the dialog should be closed
    func testScenario_KeyboardUserCancelsWithEscape() {
        // Given: I am a keyboard-only user
        // And: I have a focused dialog
        manager.register(mockElement, identifier: "test-dialog")
        manager.setFocus(to: "test-dialog")
        
        // When: I press the Escape key
        let handled = manager.handleEscape()
        
        // Then: The dialog should be closed
        XCTAssertTrue(handled, "Escape key should be handled")
        XCTAssertTrue(mockElement.cancelCalled, "Cancel should be called")
        XCTAssertFalse(mockElement.activateCalled, "Activate should not be called")
        XCTAssertFalse(mockElement.toggleCalled, "Toggle should not be called")
    }
    
    // MARK: - BDD Scenario 4: No Focus Handling
    
    /// BDD: As a keyboard-only user, when I press Enter with no focused element,
    /// then nothing should happen
    func testScenario_KeyboardUserPressesEnterWithNoFocus() {
        // Given: I am a keyboard-only user
        // And: I have no focused element
        
        // When: I press the Enter key
        let handled = manager.handleEnter()
        
        // Then: Nothing should happen
        XCTAssertFalse(handled, "Enter key should not be handled")
    }
    
    /// BDD: As a keyboard-only user, when I press Space with no focused element,
    /// then nothing should happen
    func testScenario_KeyboardUserPressesSpaceWithNoFocus() {
        // Given: I am a keyboard-only user
        // And: I have no focused element
        
        // When: I press the Space key
        let handled = manager.handleSpace()
        
        // Then: Nothing should happen
        XCTAssertFalse(handled, "Space key should not be handled")
    }
    
    // MARK: - BDD Scenario 5: Focus Management
    
    /// BDD: As a keyboard-only user, when I focus on an element,
    /// then I can activate it with Enter
    func testScenario_KeyboardUserFocusesThenActivates() {
        // Given: I am a keyboard-only user
        // And: I have a registered element
        manager.register(mockElement, identifier: "test-element")
        
        // When: I focus on the element
        manager.setFocus(to: "test-element")
        
        // And: I press Enter
        let handled = manager.handleEnter()
        
        // Then: The element should be activated
        XCTAssertTrue(handled, "Enter key should be handled")
        XCTAssertTrue(mockElement.activateCalled, "Element should be activated")
    }
    
    /// BDD: As a keyboard-only user, when I clear focus,
    /// then I cannot activate elements
    func testScenario_KeyboardUserClearsFocus() {
        // Given: I am a keyboard-only user
        // And: I have a focused element
        manager.register(mockElement, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: I clear focus
        manager.clearFocus()
        
        // And: I press Enter
        let handled = manager.handleEnter()
        
        // Then: Nothing should happen
        XCTAssertFalse(handled, "Enter key should not be handled")
        XCTAssertFalse(mockElement.activateCalled, "Element should not be activated")
    }
    
    // MARK: - BDD Scenario 6: Multiple Elements
    
    /// BDD: As a keyboard-only user, when I have multiple elements,
    /// then I can focus and activate each one independently
    func testScenario_KeyboardUserManagesMultipleElements() {
        // Given: I am a keyboard-only user
        // And: I have multiple elements
        let element1 = MockActivatable()
        let element2 = MockActivatable()
        manager.register(element1, identifier: "element-1")
        manager.register(element2, identifier: "element-2")
        
        // When: I focus on element 1 and activate it
        manager.setFocus(to: "element-1")
        _ = manager.handleEnter()
        
        // Then: Element 1 should be activated
        XCTAssertTrue(element1.activateCalled, "Element 1 should be activated")
        XCTAssertFalse(element2.activateCalled, "Element 2 should not be activated")
        
        // When: I focus on element 2 and activate it
        manager.setFocus(to: "element-2")
        _ = manager.handleEnter()
        
        // Then: Element 2 should be activated
        XCTAssertTrue(element2.activateCalled, "Element 2 should be activated")
    }
}
