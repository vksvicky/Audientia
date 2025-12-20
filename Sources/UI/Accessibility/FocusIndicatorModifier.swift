//
//  FocusIndicatorModifier.swift
//  Audientia
//
//  View modifier for adding focus indicators to keyboard-navigable elements
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

/// View modifier that adds a focus ring indicator for keyboard navigation
struct FocusIndicatorModifier: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    let cornerRadius: CGFloat
    
    init(isFocused: FocusState<Bool>.Binding, cornerRadius: CGFloat = 4) {
        self._isFocused = isFocused
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isFocused ? Color.accentColor : Color.clear,
                        lineWidth: isFocused ? 2 : 0
                    )
                    .padding(-2)
            )
    }
}

extension View {
    /// Adds a focus indicator ring that appears when the view is focused
    /// - Parameters:
    ///   - isFocused: Binding to track focus state
    ///   - cornerRadius: Corner radius for the focus ring
    /// - Returns: Modified view with focus indicator
    func focusIndicator(
        isFocused: FocusState<Bool>.Binding,
        cornerRadius: CGFloat = 4
    ) -> some View {
        modifier(FocusIndicatorModifier(
            isFocused: isFocused,
            cornerRadius: cornerRadius
        ))
    }
}
