//
//  KeyboardActivationManager.swift
//  Audientia
//
//  Manages Enter/Space key activation for focused elements
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Types of keyboard activation
public enum KeyboardActivationType {
    case enter
    case space
    case escape
}

/// Protocol for elements that can be activated via keyboard
public protocol KeyboardActivatable {
    /// Activate the element (Enter key)
    func activate()
    
    /// Toggle the element (Space key)
    func toggle()
    
    /// Cancel/close the element (Esc key)
    func cancel()
}

/// Manages keyboard activation for focused elements
@MainActor
public final class KeyboardActivationManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Currently focused activatable element
    @Published public private(set) var focusedElement: (any KeyboardActivatable)?
    
    /// Registered activatable elements by identifier
    private var registeredElements: [String: any KeyboardActivatable] = [:]
    
    // MARK: - Registration
    
    /// Register an activatable element
    /// - Parameters:
    ///   - element: The activatable element
    ///   - identifier: Unique identifier for the element
    public func register(_ element: any KeyboardActivatable, identifier: String) {
        registeredElements[identifier] = element
    }
    
    /// Unregister an activatable element
    /// - Parameter identifier: The identifier of the element to unregister
    public func unregister(identifier: String) {
        registeredElements.removeValue(forKey: identifier)
        if focusedElement != nil {
            // Clear focus if the focused element was unregistered
            focusedElement = nil
        }
    }
    
    /// Set the focused element
    /// - Parameter identifier: The identifier of the element to focus
    public func setFocus(to identifier: String) {
        focusedElement = registeredElements[identifier]
    }
    
    /// Clear focus
    public func clearFocus() {
        focusedElement = nil
    }
    
    // MARK: - Activation
    
    /// Handle Enter key activation
    /// - Returns: True if activation was handled, false otherwise
    @discardableResult
    public func handleEnter() -> Bool {
        guard let element = focusedElement else {
            return false
        }
        element.activate()
        return true
    }
    
    /// Handle Space key activation
    /// - Returns: True if activation was handled, false otherwise
    @discardableResult
    public func handleSpace() -> Bool {
        guard let element = focusedElement else {
            return false
        }
        element.toggle()
        return true
    }
    
    /// Handle Escape key activation
    /// - Returns: True if activation was handled, false otherwise
    @discardableResult
    public func handleEscape() -> Bool {
        guard let element = focusedElement else {
            return false
        }
        element.cancel()
        return true
    }
    
    /// Handle activation by type
    /// - Parameter type: The activation type
    /// - Returns: True if activation was handled, false otherwise
    @discardableResult
    public func handleActivation(_ type: KeyboardActivationType) -> Bool {
        switch type {
        case .enter:
            return handleEnter()
        case .space:
            return handleSpace()
        case .escape:
            return handleEscape()
        }
    }
}
