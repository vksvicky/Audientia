//
//  MainWindowToolbar.swift
//  Audientia
//
//  Toolbar component for the main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import SwiftUI

struct MainWindowToolbar: View {
    var body: some View {
        HStack(spacing: 12) {
            // Left side: App-specific icons
            Button(action: {}, label: {
                Image(systemName: "music.note.house.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
            })
            .buttonStyle(.plain)
            .help("Home")
            
            Button(action: {}, label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
            })
            .buttonStyle(.plain)
            .help("Search")
            
            Spacer()
            
            // Right side: Additional controls
            Button(action: {}, label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            })
            .buttonStyle(.plain)
            .help("More Options")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
