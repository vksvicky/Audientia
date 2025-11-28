//
//  MainWindowNavigationSidebar.swift
//  Audientia
//
//  Navigation sidebar component for the main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import SwiftUI

struct MainWindowNavigationSidebar: View {
    @Binding var selectedNavigationItem: NavigationItem
    
    var body: some View {
        List(selection: $selectedNavigationItem) {
            ForEach(NavigationItem.allCases, id: \.self) { item in
                NavigationLink(value: item) {
                    HStack {
                        Image(systemName: item.iconName)
                            .foregroundColor(item == selectedNavigationItem ? .orange : .secondary)
                            .frame(width: 20, alignment: .leading)
                        Text(item.displayName)
                            .foregroundColor(item == selectedNavigationItem ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .background(Color(NSColor.controlBackgroundColor))
        .frame(width: 200)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
    }
}
