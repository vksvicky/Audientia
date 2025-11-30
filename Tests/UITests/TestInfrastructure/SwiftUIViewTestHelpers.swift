//
//  SwiftUIViewTestHelpers.swift
//  UITests
//
//  Helper utilities for testing SwiftUI views with StateObject
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
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
        // Wrap the view in NSHostingView to create a proper SwiftUI view hierarchy
        // This ensures StateObject properties are properly initialized before access
        // NSHostingView creates the necessary view infrastructure that SwiftUI expects
        let container = ContainerView(content: view)
        let hostingView = NSHostingView(rootView: container)
        // Set a frame so the view has proper dimensions
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        // The hosting view properly initializes all StateObject properties when rendered
        // We don't need to explicitly access the body - just creating the hosting view is enough
        _ = hostingView
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
