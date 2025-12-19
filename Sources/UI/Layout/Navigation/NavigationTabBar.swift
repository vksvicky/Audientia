//
//  NavigationTabBar.swift
//  Audientia
//
//  Horizontal navigation tab bar for main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import os.log
import Shared
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
                    action: {
                        Logger.userInterface.info("NavigationTabBar: Tab button clicked - \(tab.rawValue)")
                        selectedTab = tab
                        Logger.userInterface.info("NavigationTabBar: selectedTab set to - \(selectedTab.rawValue)")
                    }
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
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        let buttonContent = HStack(spacing: 6) {
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
                    .fill(backgroundFill)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
        
        return Button(action: {
            Logger.userInterface.info("TabButton: Button action triggered for tab - \(tab.rawValue)")
            action()
        }, label: {
            buttonContent
        })
        .buttonStyle(.plain)
        .keyboardShortcut(tab.keyEquivalent, modifiers: .command)
        .help("\(tab.displayName) (⌘\(tab.keyboardShortcutNumber))")
        .accessibilityLabel(tab.displayName)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(isSelected ? "Selected" : "")
    }
    
    private var backgroundFill: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isPressed {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var accessibilityHint: String {
        if isSelected {
            return "Selected tab. Press to switch tabs."
        } else {
            return "Press to switch to \(tab.displayName) tab"
        }
    }
}

// MARK: - Press Events Modifier
private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
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
