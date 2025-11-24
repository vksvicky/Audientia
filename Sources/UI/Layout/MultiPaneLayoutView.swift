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
    
    public init(viewModel: MultiPaneLayoutViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: MultiPaneLayoutViewModel())
        }
    }
    
    public var body: some View {
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
        .task {
            await viewModel.loadLayout()
        }
    }
    
    // MARK: - Layout Variants
    
    @ViewBuilder
    private var horizontalSplitLayout: some View {
        HSplitView {
            // Left panel: Library Browser
            if viewModel.currentLayout.panelVisibility[.libraryBrowser] ?? false {
                LibraryBrowserPanel()
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
                LibraryBrowserPanel()
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
                LibraryBrowserPanel()
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
                LibraryBrowserPanel()
            }
            
            // Floating panels (would need additional positioning logic)
            // For now, just show main panel
        }
    }
}

// MARK: - Panel Placeholders

@MainActor
private struct LibraryBrowserPanel: View {
    var body: some View {
        VStack {
            Text("Library Browser")
                .font(.headline)
            Text("Library content will appear here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
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
