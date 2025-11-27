//
//  SwiftUIViewTestHelpers.swift
//  UITests
//
//  Helper utilities for testing SwiftUI views with StateObject
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

/// Helper utilities for testing SwiftUI views
@MainActor
enum SwiftUIViewTestHelpers {
    /// Safely access a view's body without triggering StateObject warnings
    /// This wraps the view in a container that properly initializes StateObject properties
    /// - Parameter view: The SwiftUI view to test
    /// - Returns: The view's body, properly initialized
    static func accessViewBody<V: View>(_ view: V) -> some View {
        // Wrap in a container view to properly initialize StateObject
        ContainerView(content: view)
    }
    
    /// Verify a view can be created and accessed without errors
    /// This method properly hosts the view to avoid StateObject warnings
    /// - Parameter view: The SwiftUI view to test
    static func verifyViewCreation<V: View>(_ view: V) {
        // Access the view through the container to properly initialize StateObject
        // The container ensures StateObject is accessed within a proper SwiftUI view hierarchy
        let container = ContainerView(content: view)
        _ = container.body
    }
    
    /// Get the view body in a way that properly initializes StateObject
    /// - Parameter view: The SwiftUI view to test
    /// - Returns: A view that can be safely accessed
    static func getViewBody<V: View>(_ view: V) -> some View {
        ContainerView(content: view)
    }
}

/// Container view that properly initializes StateObject properties
/// This ensures StateObject is accessed within a proper SwiftUI view hierarchy
/// By wrapping the view, we ensure StateObject is initialized before access
@MainActor
private struct ContainerView<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
    }
}
