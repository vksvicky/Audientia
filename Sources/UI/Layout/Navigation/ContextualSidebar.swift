//
//  ContextualSidebar.swift
//  Audientia
//
//  Contextual sidebar that changes content based on selected tab
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AudioCore
import DataLayer
@preconcurrency import Shared
import SwiftUI

/// Contextual sidebar with:
/// - Search field at top
/// - Tab-specific navigation in the middle
/// - Library statistics at the bottom
struct ContextualSidebar: View {
    @Binding var selectedTab: TabItem
    @Binding var searchText: String
    
    @StateObject private var statisticsViewModel: LibraryStatisticsViewModel
    
    /// Action callbacks
    var onImportFiles: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onCreatePlaylist: (() -> Void)?
    
    /// Library browser ViewModel for filtering (optional, only for Library tab)
    var libraryBrowserViewModel: LibraryBrowserViewModel?
    
    /// Playlist sidebar ViewModel (optional, only for Playlists tab)
    var playlistSidebarViewModel: PlaylistSidebarViewModel?
    
    /// Smart playlist ViewModel (optional, only for Playlists tab)
    var smartPlaylistViewModel: SmartPlaylistViewModel?
    
    /// Device sidebar ViewModel (optional, only for Devices tab)
    var deviceSidebarViewModel: DeviceSidebarViewModel?
    
    /// Audio visualiser ViewModel (optional, only for Visualiser tab)
    var audioVisualiserViewModel: AudioVisualiserViewModel?
    
    /// Width of the sidebar
    static let width: CGFloat = 180
    
    init(
        selectedTab: Binding<TabItem>,
        searchText: Binding<String>,
        onImportFiles: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onCreatePlaylist: (() -> Void)? = nil,
        libraryBrowserViewModel: LibraryBrowserViewModel? = nil,
        playlistSidebarViewModel: PlaylistSidebarViewModel? = nil,
        smartPlaylistViewModel: SmartPlaylistViewModel? = nil,
        deviceSidebarViewModel: DeviceSidebarViewModel? = nil,
        audioVisualiserViewModel: AudioVisualiserViewModel? = nil
    ) {
        self._selectedTab = selectedTab
        self._searchText = searchText
        self.onImportFiles = onImportFiles
        self.onOpenSettings = onOpenSettings
        self.onCreatePlaylist = onCreatePlaylist
        self.libraryBrowserViewModel = libraryBrowserViewModel
        self.playlistSidebarViewModel = playlistSidebarViewModel
        self.smartPlaylistViewModel = smartPlaylistViewModel
        self.deviceSidebarViewModel = deviceSidebarViewModel
        self.audioVisualiserViewModel = audioVisualiserViewModel
        let indexer = LibraryIndexer()
        let calculator = LibraryStatisticsCalculator(indexer: indexer)
        _statisticsViewModel = StateObject(
            wrappedValue: LibraryStatisticsViewModel(statisticsCalculator: calculator)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            searchFieldView
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            
            Divider()
            
            // Contextual navigation based on selected tab
            ScrollView {
                contextualNavigationView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            
            Divider()
            
            // Library statistics at the bottom
            libraryStatsView
        }
        .background(Color(NSColor.controlBackgroundColor))
        .frame(width: Self.width)
        .frame(maxHeight: .infinity)
        .task {
            await statisticsViewModel.loadStatistics()
        }
    }
    
    // MARK: - Search Field
    
    private var searchFieldView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            
            TextField(selectedTab.searchPlaceholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
    
    // MARK: - Contextual Navigation
    
    @ViewBuilder
    private var contextualNavigationView: some View {
        switch selectedTab {
        case .home:
            homeNavigationContent
        case .library:
            libraryNavigationContent
        case .playlists:
            playlistsNavigationContent
        case .devices:
            devicesNavigationContent
        case .visualiser:
            visualiserNavigationContent
        }
    }
    
    // MARK: - Home Tab Navigation
    
    private var homeNavigationContent: some View {
        HomeNavigationContent(
            onImportFiles: onImportFiles,
            onOpenSettings: onOpenSettings
        )
    }
    
    // MARK: - Library Tab Navigation
    
    private var libraryNavigationContent: some View {
        Group {
            if let viewModel = libraryBrowserViewModel {
                LibraryNavigationContent(
                    libraryBrowserViewModel: viewModel,
                    statisticsViewModel: statisticsViewModel
                )
            } else {
                Text("No library loaded")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Playlists Tab Navigation
    
    private var playlistsNavigationContent: some View {
        Group {
            if let playlistViewModel = playlistSidebarViewModel,
               let smartViewModel = smartPlaylistViewModel {
                PlaylistsNavigationContent(
                    playlistSidebarViewModel: playlistViewModel,
                    smartPlaylistViewModel: smartViewModel,
                    onCreatePlaylist: onCreatePlaylist
                )
            } else {
                Text("No playlists")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Devices Tab Navigation
    
    private var devicesNavigationContent: some View {
        Group {
            if let viewModel = deviceSidebarViewModel {
                DevicesNavigationContent(deviceSidebarViewModel: viewModel)
            } else {
                Text("No devices")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Visualiser Tab Navigation
    
    private var visualiserNavigationContent: some View {
        Group {
            if let viewModel = audioVisualiserViewModel {
                VisualiserNavigationContent(audioVisualiserViewModel: viewModel)
            } else {
                Text("No visualiser loaded")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Library Statistics
    
    private var libraryStatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let stats = statisticsViewModel.statistics {
                Text("LIBRARY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    StatRow(icon: "music.note", value: "\(stats.trackCount)", label: "tracks")
                    StatRow(icon: "person.2", value: "\(stats.artistCount)", label: "artists")
                    StatRow(icon: "opticaldisc", value: "\(stats.albumCount)", label: "albums")
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    StatRow(icon: "clock", value: formatDuration(stats.totalDuration), label: nil)
                    StatRow(icon: "externaldrive", value: formatFileSize(stats.totalFileSize), label: nil)
                }
            } else if statisticsViewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No library data")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#if DEBUG
struct ContextualSidebar_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 0) {
            ContextualSidebar(selectedTab: .constant(.home), searchText: .constant(""))
            ContextualSidebar(selectedTab: .constant(.library), searchText: .constant(""))
            ContextualSidebar(selectedTab: .constant(.visualiser), searchText: .constant(""))
        }
    }
}
#endif
