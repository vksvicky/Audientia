//
//  CollapsibleToolbar.swift
//  Audientia
//
//  Collapsible toolbar containing navigation tabs
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import SwiftUI

/// Collapsible toolbar containing navigation tabs
/// - Expanded: Shows full tab bar (44px)
/// - Collapsed: Hidden with only expand button visible (minimal height)
struct CollapsibleToolbar: View {
    @Binding var selectedTab: TabItem
    @Binding var isExpanded: Bool
    
    /// Height when expanded
    static let expandedHeight: CGFloat = 44
    
    /// Height when collapsed (just the toggle button area)
    static let collapsedHeight: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                collapsedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .clipped()
    }
    
    private var expandedContent: some View {
        HStack(spacing: 0) {
            NavigationTabBar(selectedTab: $selectedTab)
            
            Spacer()
            
            collapseButton
                .padding(.trailing, 8)
        }
        .frame(height: Self.expandedHeight)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var collapsedContent: some View {
        HStack {
            Spacer()
            
            expandButton
                .padding(.trailing, 8)
        }
        .frame(height: Self.collapsedHeight)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    private var collapseButton: some View {
        Button(
            action: { isExpanded = false },
            label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
        .keyboardShortcut("t", modifiers: .command)
        .help("Collapse toolbar (⌘T)")
        .accessibilityLabel("Collapse toolbar")
        .accessibilityHint("Collapses the toolbar to maximise content area. Press ⌘T to toggle.")
        .onChange(of: isExpanded) { _, newValue in
            if !newValue {
                // Announce when toolbar is collapsed
                NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested, userInfo: [
                    .announcement: "Toolbar collapsed"
                ])
            }
        }
    }
    
    private var expandButton: some View {
        Button(
            action: { isExpanded = true },
            label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
        .keyboardShortcut("t", modifiers: .command)
        .help("Expand toolbar (⌘T)")
        .accessibilityLabel("Expand toolbar")
        .accessibilityHint("Expands the toolbar to show navigation tabs. Press ⌘T to toggle.")
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                // Announce when toolbar is expanded
                NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested, userInfo: [
                    .announcement: "Toolbar expanded"
                ])
            }
        }
    }
}

#if DEBUG
struct CollapsibleToolbar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CollapsibleToolbar(selectedTab: .constant(.home), isExpanded: .constant(true))
                .frame(width: 600)
            
            CollapsibleToolbar(selectedTab: .constant(.library), isExpanded: .constant(false))
                .frame(width: 600)
        }
        .padding()
    }
}
#endif
