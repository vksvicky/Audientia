//
//  ViewExtensions.swift
//  Audientia
//
//  SwiftUI view extensions
//

import SwiftUI

public extension View {
    /// Namespaced double-click handler to avoid symbol collisions across targets.
    func onPrimaryDoubleClick(_ action: @escaping () -> Void) -> some View {
        gesture(
            TapGesture(count: 2)
                .onEnded { _ in action() }
        )
    }
}
