//
//  MultiPaneLayoutView.swift
//  Audientia
//
//  Multi-pane Layout System UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Multi-pane layout view with resizable panels
/// BDD: As a user, I want a MediaMonkey-style multi-pane interface with resizable panels
@MainActor
public struct MultiPaneLayoutView: View {
    @StateObject private var viewModel: MultiPaneLayoutViewModel
    @StateObject private var libraryViewModel = LibraryBrowserViewModel()
    
    public init(viewModel: MultiPaneLayoutViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: MultiPaneLayoutViewModel())
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            controlBar
            Divider()
            layoutContainer
        }
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await viewModel.loadLayout()
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.clearSuccessMessage()
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.lastError != nil)) {
            Button("OK") {
                viewModel.clearLastError()
            }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var layoutContainer: some View {
        Group {
            switch viewModel.currentLayout.layoutMode {
            case .horizontalSplit:
                horizontalSplitLayout
            case .verticalSplit:
                verticalSplitLayout
            case .tabbed:
                tabbedLayout
            case .floating:
                floatingLayout
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
    
    // MARK: - Layout Variants
    
    @ViewBuilder
    private var horizontalSplitLayout: some View {
        HSplitView {
            // Left panel: Library Browser
            if viewModel.currentLayout.panelVisibility[.libraryBrowser] ?? false {
                LibraryBrowserView(viewModel: libraryViewModel)
                    .frame(width: viewModel.currentLayout.panelSizes[.libraryBrowser] ?? 300)
            }
            
            // Center: Main content
            VStack {
                // Now Playing
                if viewModel.currentLayout.panelVisibility[.nowPlaying] ?? false {
                    NowPlayingPanel()
                        .frame(height: viewModel.currentLayout.panelSizes[.nowPlaying] ?? 200)
                }
                
                // Playlist Panel
                if viewModel.currentLayout.panelVisibility[.playlistPanel] ?? false {
                    PlaylistPanel()
                }
            }
            
            // Right panel: Track Details
            if viewModel.currentLayout.panelVisibility[.trackDetails] ?? false {
                TrackDetailsPanel()
                    .frame(width: viewModel.currentLayout.panelSizes[.trackDetails] ?? 300)
            }
        }
    }
    
    @ViewBuilder
    private var verticalSplitLayout: some View {
        VSplitView {
            // Top: Library Browser
            if viewModel.currentLayout.panelVisibility[.libraryBrowser] ?? false {
                LibraryBrowserView(viewModel: libraryViewModel)
                    .frame(height: viewModel.currentLayout.panelSizes[.libraryBrowser] ?? 300)
            }
            
            // Bottom: Main content
            HSplitView {
                // Now Playing
                if viewModel.currentLayout.panelVisibility[.nowPlaying] ?? false {
                    NowPlayingPanel()
                }
                
                // Playlist Panel
                if viewModel.currentLayout.panelVisibility[.playlistPanel] ?? false {
                    PlaylistPanel()
                }
                
                // Track Details
                if viewModel.currentLayout.panelVisibility[.trackDetails] ?? false {
                    TrackDetailsPanel()
                        .frame(width: viewModel.currentLayout.panelSizes[.trackDetails] ?? 300)
                }
            }
        }
    }
    
    @ViewBuilder
    private var tabbedLayout: some View {
        TabView {
            if viewModel.currentLayout.panelVisibility[.libraryBrowser] ?? false {
                LibraryBrowserView(viewModel: libraryViewModel)
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }
            }
            
            if viewModel.currentLayout.panelVisibility[.playlistPanel] ?? false {
                PlaylistPanel()
                    .tabItem {
                        Label("Playlist", systemImage: "list.bullet")
                    }
            }
            
            if viewModel.currentLayout.panelVisibility[.nowPlaying] ?? false {
                NowPlayingPanel()
                    .tabItem {
                        Label("Now Playing", systemImage: "play.circle")
                    }
            }
            
            if viewModel.currentLayout.panelVisibility[.trackDetails] ?? false {
                TrackDetailsPanel()
                    .tabItem {
                        Label("Details", systemImage: "info.circle")
                    }
            }
        }
    }
    
    @ViewBuilder
    private var floatingLayout: some View {
        ZStack {
            // Main content area
            if viewModel.currentLayout.panelVisibility[.libraryBrowser] ?? false {
                LibraryBrowserView(viewModel: libraryViewModel)
            }
            
            // Floating panels (would need additional positioning logic)
            // For now, just show main panel
        }
    }
}

// MARK: - Panel Placeholders

private extension MultiPaneLayoutView {
    var controlBar: some View {
        HStack(spacing: 12) {
            Picker("Layout Mode", selection: Binding(
                get: { viewModel.currentLayout.layoutMode },
                set: { viewModel.setLayoutMode($0) }
            )) {
                ForEach(LayoutMode.allCases, id: \.self) { mode in
                    Text(mode.displayTitle).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)
            
            Menu("Panels") {
                ForEach(LayoutPanel.allCases, id: \.self) { panel in
                    let isVisible = viewModel.currentLayout.panelVisibility[panel] ?? false
                    Button {
                        viewModel.togglePanelVisibility(panel)
                    } label: {
                        Label(panel.displayName, systemImage: isVisible ? "checkmark.circle.fill" : "circle")
                    }
                }
            }
            
            Spacer()
            
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button("Save") {
                Task {
                    await viewModel.saveLayout()
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.isSaving)
            
            Button("Reset") {
                Task {
                    await viewModel.resetLayout()
                }
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

@MainActor
private struct PlaylistPanel: View {
    var body: some View {
        VStack {
            Text("Playlist Panel")
                .font(.headline)
            Text("Playlist content will appear here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

@MainActor
private struct NowPlayingPanel: View {
    var body: some View {
        VStack {
            Text("Now Playing")
                .font(.headline)
            Text("Now playing content will appear here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

@MainActor
private struct TrackDetailsPanel: View {
    var body: some View {
        VStack {
            Text("Track Details")
                .font(.headline)
            Text("Track details will appear here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

private extension LayoutMode {
    var displayTitle: String {
        switch self {
        case .horizontalSplit:
            return "Horizontal"
        case .verticalSplit:
            return "Vertical"
        case .tabbed:
            return "Tabbed"
        case .floating:
            return "Floating"
        }
    }
}
