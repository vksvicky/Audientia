//
//  KeyboardActivationModifier.swift
//  Audientia
//
//  View modifier for adding Enter/Space/Escape activation to views
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

/// View modifier that adds keyboard activation support (Enter/Space/Escape)
struct KeyboardActivationModifier: ViewModifier {
    let onEnter: (() -> Void)?
    let onSpace: (() -> Void)?
    let onEscape: (() -> Void)?
    @FocusState.Binding var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onKeyPress(.return) {
                if let onEnter = onEnter {
                    onEnter()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.space) {
                if let onSpace = onSpace {
                    onSpace()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.escape) {
                if let onEscape = onEscape {
                    onEscape()
                    return .handled
                }
                return .ignored
            }
    }
}

extension View {
    /// Adds keyboard activation support to a view
    /// - Parameters:
    ///   - isFocused: Binding to track focus state
    ///   - onEnter: Action to perform when Enter key is pressed
    ///   - onSpace: Action to perform when Space key is pressed
    ///   - onEscape: Action to perform when Escape key is pressed
    func keyboardActivation(
        isFocused: FocusState<Bool>.Binding,
        onEnter: (() -> Void)? = nil,
        onSpace: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardActivationModifier(
            onEnter: onEnter,
            onSpace: onSpace,
            onEscape: onEscape,
            isFocused: isFocused
        ))
    }
}
