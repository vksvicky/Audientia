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
            } else {
                collapsedContent
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
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
