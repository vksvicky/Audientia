//
//  KeyboardActivationManagerTests.swift
//  UITests
//
//  TDD tests for KeyboardActivationManager
//  Following Right-BICEP principles for comprehensive test coverage
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia

/// Mock activatable element for testing
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
/// TDD tests for KeyboardActivationManager
/// Tests activation handling, registration, and focus management
@MainActor
final class KeyboardActivationManagerTests: XCTestCase {
    
    private var manager: KeyboardActivationManager!
    
    override func setUp() {
        super.setUp()
        manager = KeyboardActivationManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - [Right]: Registration and Focus
    
    /// Test: Registering an element should work
    func testRegisterElement() {
        // Given: A mock activatable element
        let element = MockActivatable()
        
        // When: We register it
        manager.register(element, identifier: "test-element")
        
        // Then: Element should be registered
        manager.setFocus(to: "test-element")
        XCTAssertNotNil(manager.focusedElement, "Element should be registered")
    }
    
    /// Test: Setting focus should work
    func testSetFocus() {
        // Given: A registered element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        
        // When: We set focus
        manager.setFocus(to: "test-element")
        
        // Then: Element should be focused
        XCTAssertNotNil(manager.focusedElement, "Element should be focused")
    }
    
    /// Test: Clearing focus should work
    func testClearFocus() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We clear focus
        manager.clearFocus()
        
        // Then: Focus should be cleared
        XCTAssertNil(manager.focusedElement, "Focus should be cleared")
    }
    
    // MARK: - [B]: Boundary Conditions
    
    /// Test: Activating with no focused element should return false
    func testActivateWithNoFocus() {
        // Given: No focused element
        // When: We try to activate
        let result = manager.handleEnter()
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false when no element is focused")
    }
    
    /// Test: Setting focus to non-existent element should handle gracefully
    func testSetFocusToNonExistentElement() {
        // Given: No registered elements
        // When: We set focus to non-existent element
        manager.setFocus(to: "non-existent")
        
        // Then: Focus should be nil
        XCTAssertNil(manager.focusedElement, "Focus should be nil for non-existent element")
    }
    
    /// Test: Unregistering focused element should clear focus
    func testUnregisterFocusedElement() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We unregister it
        manager.unregister(identifier: "test-element")
        
        // Then: Focus should be cleared
        XCTAssertNil(manager.focusedElement, "Focus should be cleared when element is unregistered")
    }
    
    // MARK: - [I]: Inverse Relationships
    
    /// Test: Setting focus then clearing should work
    func testSetFocusThenClear() {
        // Given: A registered element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        
        // When: We set focus then clear
        manager.setFocus(to: "test-element")
        manager.clearFocus()
        
        // Then: Focus should be cleared
        XCTAssertNil(manager.focusedElement, "Focus should be cleared")
    }
    
    // MARK: - [C]: Cross-Check
    
    /// Test: Activation should call correct method on element
    func testActivationCallsCorrectMethod() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We activate with Enter
        _ = manager.handleEnter()
        
        // Then: activate() should be called
        XCTAssertTrue(element.activateCalled, "activate() should be called")
        XCTAssertFalse(element.toggleCalled, "toggle() should not be called")
        XCTAssertFalse(element.cancelCalled, "cancel() should not be called")
    }
    
    /// Test: Toggle should call toggle method
    func testToggleCallsToggleMethod() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We activate with Space
        _ = manager.handleSpace()
        
        // Then: toggle() should be called
        XCTAssertTrue(element.toggleCalled, "toggle() should be called")
        XCTAssertFalse(element.activateCalled, "activate() should not be called")
        XCTAssertFalse(element.cancelCalled, "cancel() should not be called")
    }
    
    /// Test: Escape should call cancel method
    func testEscapeCallsCancelMethod() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We activate with Escape
        _ = manager.handleEscape()
        
        // Then: cancel() should be called
        XCTAssertTrue(element.cancelCalled, "cancel() should be called")
        XCTAssertFalse(element.activateCalled, "activate() should not be called")
        XCTAssertFalse(element.toggleCalled, "toggle() should not be called")
    }
    
    // MARK: - [E]: Error Conditions
    
    /// Test: Unregistering non-existent element should handle gracefully
    func testUnregisterNonExistentElement() {
        // Given: No registered elements
        // When: We unregister a non-existent element
        manager.unregister(identifier: "non-existent")
        
        // Then: Should handle gracefully (no crash)
        XCTAssertNil(manager.focusedElement, "Focus should remain nil")
    }
    
    /// Test: Registering multiple elements should work
    func testRegisterMultipleElements() {
        // Given: Multiple elements
        let element1 = MockActivatable()
        let element2 = MockActivatable()
        
        // When: We register both
        manager.register(element1, identifier: "element-1")
        manager.register(element2, identifier: "element-2")
        
        // Then: Both should be registered
        manager.setFocus(to: "element-1")
        XCTAssertNotNil(manager.focusedElement, "First element should be focused")
        
        manager.setFocus(to: "element-2")
        XCTAssertNotNil(manager.focusedElement, "Second element should be focused")
    }
    
    // MARK: - [P]: Performance
    
    /// Test: Activation operations should be fast
    func testActivationPerformance() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We perform multiple activation operations
        measure {
            for _ in 0..<1000 {
                _ = manager.handleEnter()
                _ = manager.handleSpace()
                _ = manager.handleEscape()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// Test: handleActivation with type should work
    func testHandleActivationWithType() {
        // Given: A focused element
        let element = MockActivatable()
        manager.register(element, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We handle activation with Enter type
        let result = manager.handleActivation(.enter)
        
        // Then: Should activate and return true
        XCTAssertTrue(result, "Should return true")
        XCTAssertTrue(element.activateCalled, "activate() should be called")
    }
    
    /// Test: Multiple registrations with same identifier should replace
    func testMultipleRegistrationsReplace() {
        // Given: An element registered
        let element1 = MockActivatable()
        manager.register(element1, identifier: "test-element")
        manager.setFocus(to: "test-element")
        
        // When: We register another element with same identifier
        let element2 = MockActivatable()
        manager.register(element2, identifier: "test-element")
        
        // Then: New element should replace old one
        manager.setFocus(to: "test-element")
        // Note: We can't directly compare, but activation should work on new element
        _ = manager.handleEnter()
        XCTAssertTrue(element2.activateCalled, "New element should be activated")
    }
}
