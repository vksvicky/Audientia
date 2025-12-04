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
            }
        )
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }
}

// MARK: - Sidebar Action Button

struct SidebarActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
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
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
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
