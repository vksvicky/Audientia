//
//  NavigationTabBar.swift
//  Audientia
//
//  Horizontal navigation tab bar for main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

/// Horizontal tab bar for main window navigation
struct NavigationTabBar: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// Individual tab button in the navigation bar
private struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                
                Text(tab.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? Color.accentColor : Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(tab.keyEquivalent, modifiers: .command)
        .help("\(tab.displayName) (⌘\(tab.keyboardShortcutNumber))")
    }
}

#if DEBUG
struct NavigationTabBar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationTabBar(selectedTab: .constant(.home))
            .frame(width: 600)
    }
}
#endif
