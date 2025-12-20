//
//  KeyboardNavigationModifier.swift
//  Audientia
//
//  View modifier for keyboard navigation support
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI

/// View modifier that adds keyboard navigation support to a view
struct KeyboardNavigationModifier: ViewModifier {
    @ObservedObject var navigationManager: KeyboardNavigationManager
    let element: KeyboardNavigationElement
    @FocusState.Binding var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            // Note: Tab key navigation is handled at the MainWindowLayoutView level
            // This modifier only handles focus state synchronization
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    navigationManager.setFocus(to: element)
                }
            }
            .onChange(of: navigationManager.currentFocus) { oldValue, newValue in
                // Update focus state when navigation manager changes
                if newValue == element {
                    isFocused = true
                } else if oldValue == element {
                    isFocused = false
                }
            }
    }
}

extension View {
    /// Adds keyboard navigation support to a view
    /// - Parameters:
    ///   - navigationManager: The keyboard navigation manager
    ///   - element: The navigation element this view represents
    ///   - isFocused: Binding to track focus state
    /// - Returns: Modified view with keyboard navigation
    func keyboardNavigation(
        manager: KeyboardNavigationManager,
        element: KeyboardNavigationElement,
        isFocused: FocusState<Bool>.Binding
    ) -> some View {
        modifier(KeyboardNavigationModifier(
            navigationManager: manager,
            element: element,
            isFocused: isFocused
        ))
    }
}
