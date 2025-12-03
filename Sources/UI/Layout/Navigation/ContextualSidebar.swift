//
//  ContextualSidebar.swift
//  Audientia
//
//  Contextual sidebar that changes content based on selected tab
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import DataLayer
import SwiftUI

/// Contextual sidebar with:
/// - Search field at top
/// - Tab-specific navigation in the middle
/// - Library statistics at the bottom
struct ContextualSidebar: View {
    @Binding var selectedTab: TabItem
    @Binding var searchText: String
    
    @StateObject private var statisticsViewModel: LibraryStatisticsViewModel
    
    /// Width of the sidebar
    static let width: CGFloat = 180
    
    init(selectedTab: Binding<TabItem>, searchText: Binding<String>) {
        self._selectedTab = selectedTab
        self._searchText = searchText
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
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "QUICK ACCESS") {
                SidebarNavItem(icon: "clock.arrow.circlepath", title: "Recently Played")
                SidebarNavItem(icon: "plus.circle", title: "Recently Added")
                SidebarNavItem(icon: "chart.bar", title: "Most Played")
                SidebarNavItem(icon: "heart", title: "Favourites")
            }
            
            SidebarSection(title: "ACTIONS") {
                SidebarActionButton(icon: "plus", title: "Import Files") {
                    // TODO: Trigger file import
                }
                SidebarActionButton(icon: "gearshape", title: "Settings") {
                    // TODO: Open settings
                }
            }
        }
    }
    
    // MARK: - Library Tab Navigation
    
    private var libraryNavigationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "BROWSE BY") {
                SidebarNavItem(
                    icon: "music.note.list",
                    title: "All Tracks",
                    count: statisticsViewModel.statistics?.trackCount
                )
                SidebarNavItem(
                    icon: "person.2",
                    title: "Artists",
                    count: statisticsViewModel.statistics?.artistCount
                )
                SidebarNavItem(
                    icon: "opticaldisc",
                    title: "Albums",
                    count: statisticsViewModel.statistics?.albumCount
                )
                SidebarNavItem(icon: "guitars", title: "Genres")
                SidebarNavItem(icon: "calendar", title: "Years")
                SidebarNavItem(icon: "folder", title: "Folders")
            }
            
            SidebarSection(title: "FILTER BY GENRE") {
                SidebarFilterItem(title: "Rock")
                SidebarFilterItem(title: "Jazz")
                SidebarFilterItem(title: "Classical")
                SidebarFilterItem(title: "Electronic")
            }
        }
    }
    
    // MARK: - Playlists Tab Navigation
    
    private var playlistsNavigationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "PLAYLISTS") {
                // Placeholder - will be populated from PlaylistManager
                Text("No playlists")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            SidebarActionButton(icon: "plus", title: "New Playlist") {
                // TODO: Create new playlist
            }
            
            SidebarSection(title: "SMART PLAYLISTS") {
                SidebarNavItem(icon: "bolt", title: "Recently Added")
                SidebarNavItem(icon: "bolt", title: "Top Rated")
                SidebarNavItem(icon: "bolt", title: "5-Star Tracks")
            }
        }
    }
    
    // MARK: - Devices Tab Navigation
    
    private var devicesNavigationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "CONNECTED") {
                Text("No devices")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            SidebarSection(title: "SYNC OPTIONS") {
                SidebarRadioItem(title: "Entire Library", isSelected: true)
                SidebarRadioItem(title: "Selected Playlists", isSelected: false)
                SidebarRadioItem(title: "Checked Tracks Only", isSelected: false)
            }
        }
    }
    
    // MARK: - Visualiser Tab Navigation
    
    private var visualiserNavigationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "VISUALISATION STYLE") {
                SidebarRadioItem(title: "LED Bars", isSelected: true)
                SidebarRadioItem(title: "Lumi Bars", isSelected: false)
                SidebarRadioItem(title: "Radial Spectrum", isSelected: false)
                SidebarRadioItem(title: "Dual Channel", isSelected: false)
                SidebarRadioItem(title: "Discrete Frequencies", isSelected: false)
                SidebarRadioItem(title: "Round Bars Reflex", isSelected: false)
            }
            
            SidebarSection(title: "SETTINGS") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sensitivity")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Slider(value: .constant(0.5), in: 0...1)
                        .controlSize(.small)
                    
                    HStack {
                        Text("Smoothing")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Slider(value: .constant(0.3), in: 0...1)
                        .controlSize(.small)
                }
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

// MARK: - Sidebar Components

private struct SidebarSection<Content: View>: View {
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

private struct SidebarNavItem: View {
    let icon: String
    let title: String
    var count: Int?
    
    init(icon: String, title: String, count: Int? = nil) {
        self.icon = icon
        self.title = title
        self.count = count
    }
    
    var body: some View {
        Button(
            action: {},
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

private struct SidebarActionButton: View {
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

private struct SidebarFilterItem: View {
    let title: String
    @State private var isChecked = false
    
    var body: some View {
        Toggle(isOn: $isChecked) {
            Text(title)
                .font(.system(size: 12))
        }
        .toggleStyle(.checkbox)
        .padding(.vertical, 1)
    }
}

private struct SidebarRadioItem: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
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
}

private struct StatRow: View {
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
