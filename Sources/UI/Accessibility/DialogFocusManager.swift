//
//  DialogFocusManager.swift
//  Audientia
//
//  Manages focus trapping and restoration for dialogs and modals
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI

/// Manages focus trapping and restoration for dialogs and modals
@MainActor
public final class DialogFocusManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Currently focused element identifier before dialog opened
    @Published public private(set) var previousFocusIdentifier: String?
    
    /// Currently focused element identifier in dialog
    @Published public private(set) var dialogFocusIdentifier: String?
    
    /// First focusable element in dialog
    @Published public private(set) var firstFocusableIdentifier: String?
    
    /// Last focusable element in dialog
    @Published public private(set) var lastFocusableIdentifier: String?
    
    /// Whether focus is trapped in dialog
    @Published public private(set) var isFocusTrapped: Bool = false
    
    /// Registered focusable elements in dialog
    private var focusableElements: [String] = []
    
    // MARK: - Focus Management
    
    /// Register a focusable element in the dialog
    /// - Parameter identifier: Unique identifier for the element
    public func registerFocusableElement(_ identifier: String) {
        if !focusableElements.contains(identifier) {
            focusableElements.append(identifier)
            updateFirstAndLast()
        }
    }
    
    /// Unregister a focusable element
    /// - Parameter identifier: The identifier of the element to unregister
    public func unregisterFocusableElement(_ identifier: String) {
        focusableElements.removeAll { $0 == identifier }
        updateFirstAndLast()
    }
    
    /// Open dialog and save previous focus
    /// - Parameter previousFocus: The identifier of the previously focused element
    public func openDialog(previousFocus: String?) {
        previousFocusIdentifier = previousFocus
        isFocusTrapped = true
        // Focus first element if available
        if let first = firstFocusableIdentifier {
            dialogFocusIdentifier = first
        }
    }
    
    /// Close dialog and restore previous focus
    public func closeDialog() {
        isFocusTrapped = false
        dialogFocusIdentifier = nil
        // Previous focus will be restored by the view
    }
    
    /// Move focus to next element in dialog
    /// - Returns: The identifier of the next focused element, or nil if at end
    @discardableResult
    public func moveFocusForward() -> String? {
        guard isFocusTrapped, let current = dialogFocusIdentifier else {
            return nil
        }
        
        if let currentIndex = focusableElements.firstIndex(of: current) {
            if currentIndex < focusableElements.count - 1 {
                dialogFocusIdentifier = focusableElements[currentIndex + 1]
                return dialogFocusIdentifier
            } else {
                // Wrap to first
                dialogFocusIdentifier = firstFocusableIdentifier
                return dialogFocusIdentifier
            }
        } else if let first = firstFocusableIdentifier {
            dialogFocusIdentifier = first
            return dialogFocusIdentifier
        }
        
        return nil
    }
    
    /// Move focus to previous element in dialog
    /// - Returns: The identifier of the previous focused element, or nil if at start
    @discardableResult
    public func moveFocusBackward() -> String? {
        guard isFocusTrapped, let current = dialogFocusIdentifier else {
            return nil
        }
        
        if let currentIndex = focusableElements.firstIndex(of: current) {
            if currentIndex > 0 {
                dialogFocusIdentifier = focusableElements[currentIndex - 1]
                return dialogFocusIdentifier
            } else {
                // Wrap to last
                dialogFocusIdentifier = lastFocusableIdentifier
                return dialogFocusIdentifier
            }
        } else if let first = firstFocusableIdentifier {
            dialogFocusIdentifier = first
            return dialogFocusIdentifier
        }
        
        return nil
    }
    
    /// Set focus to a specific element
    /// - Parameter identifier: The identifier of the element to focus
    public func setFocus(to identifier: String) {
        guard focusableElements.contains(identifier) else {
            // If trying to set focus to non-existent element, don't change focus
            // This ensures focus remains on current element (or nil if none set)
            return
        }
        dialogFocusIdentifier = identifier
    }
    
    /// Clear all registered elements (for cleanup)
    public func clear() {
        focusableElements.removeAll()
        firstFocusableIdentifier = nil
        lastFocusableIdentifier = nil
        dialogFocusIdentifier = nil
    }
    
    // MARK: - Private Methods
    
    private func updateFirstAndLast() {
        firstFocusableIdentifier = focusableElements.first
        lastFocusableIdentifier = focusableElements.last
    }
}
