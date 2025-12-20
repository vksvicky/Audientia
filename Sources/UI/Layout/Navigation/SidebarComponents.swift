//
//  SidebarComponents.swift
//  Audientia
//
//  Reusable sidebar UI components
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

// MARK: - Sidebar Section

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            
            content()
        }
    }
}

// MARK: - Sidebar Nav Item

struct SidebarNavItem: View {
    let icon: String
    let title: String
    var count: Int?
    var action: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isPressed = false
    @FocusState private var isFocused: Bool
    
    init(icon: String, title: String, count: Int? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.count = count
        self.action = action
    }
    
    var body: some View {
        Button(
            action: { action?() },
            label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let count = count {
                        Text("(\(count))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundFill)
                )
            }
        )
        .buttonStyle(.plain)
        .focused($isFocused)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    isFocused ? Color.accentColor : Color.clear,
                    lineWidth: isFocused ? 2 : 0
                )
                .padding(-2)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
    }
    
    private var backgroundFill: Color {
        if isPressed {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Sidebar Action Button

struct SidebarActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundFill)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    isFocused ? Color.accentColor : Color.clear,
                    lineWidth: isFocused ? 2 : 0
                )
                .padding(-2)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
        .accessibilityLabel(title)
        .accessibilityHint("Press to \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
    
    private var foregroundColor: Color {
        if isPressed {
            return Color.accentColor.opacity(0.8)
        } else {
            return Color.accentColor
        }
    }
    
    private var backgroundFill: Color {
        if isPressed {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Sidebar Filter Item

struct SidebarFilterItem: View {
    let title: String
    @Binding var isChecked: Bool
    let action: ((Bool) -> Void)?
    
    init(title: String, isChecked: Binding<Bool>, action: ((Bool) -> Void)? = nil) {
        self.title = title
        self._isChecked = isChecked
        self.action = action
    }
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isChecked },
            set: { newValue in
                isChecked = newValue
                action?(newValue)
            }
        )) {
            Text(title)
                .font(.system(size: 12))
        }
        .toggleStyle(.checkbox)
        .padding(.vertical, 1)
    }
}

// MARK: - Sidebar Radio Item

struct SidebarRadioItem: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundFill)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Selected option. Press to change selection." : "Press to select \(title)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(isSelected ? "Selected" : "")
    }
    
    private var backgroundFill: Color {
        if isPressed {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let value: String
    let label: String?
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 11))
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
            
            if let label = label {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
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
