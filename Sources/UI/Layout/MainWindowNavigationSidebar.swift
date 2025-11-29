//
//  MainWindowNavigationSidebar.swift
//  Audientia
//
//  Navigation sidebar component for the main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import DataLayer
import SwiftUI

struct MainWindowNavigationSidebar: View {
    @Binding var selectedNavigationItem: NavigationItem
    @StateObject private var statisticsViewModel: LibraryStatisticsViewModel
    
    private var visibleNavigationItems: [NavigationItem] {
        NavigationItem.allCases.filter { $0.isVisible }
    }
    
    init(selectedNavigationItem: Binding<NavigationItem>) {
        self._selectedNavigationItem = selectedNavigationItem
        let indexer = LibraryIndexer()
        let calculator = LibraryStatisticsCalculator(indexer: indexer)
        _statisticsViewModel = StateObject(
            wrappedValue: LibraryStatisticsViewModel(statisticsCalculator: calculator)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation items
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(visibleNavigationItems, id: \.self) { item in
                        navigationItemButton(for: item)
                    }
                }
            }
            
            Divider()
            
            // Library statistics at the bottom
            libraryStatsView
        }
        .background(Color(NSColor.controlBackgroundColor))
        .frame(width: 200)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .task {
            await statisticsViewModel.loadStatistics()
        }
    }
    
    private var libraryStatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let stats = statisticsViewModel.statistics {
                VStack(alignment: .leading, spacing: 6) {
                    // Track count
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 11))
                        Text("\(stats.trackCount)")
                            .font(.system(size: 12, weight: .semibold))
                        Text("tracks")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Artist count
                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 11))
                        Text("\(stats.artistCount)")
                            .font(.system(size: 12, weight: .semibold))
                        Text("artists")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Album count
                    HStack(spacing: 6) {
                        Image(systemName: "opticaldisc")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 11))
                        Text("\(stats.albumCount)")
                            .font(.system(size: 12, weight: .semibold))
                        Text("albums")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Total duration
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 11))
                        Text(formatDuration(stats.totalDuration))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Total size
                    HStack(spacing: 6) {
                        Image(systemName: "externaldrive")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 11))
                        Text(formatFileSize(stats.totalFileSize))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
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
    
    @ViewBuilder
    private func navigationItemButton(for item: NavigationItem) -> some View {
        let isSelected = item == selectedNavigationItem
        let iconColor = isSelected ? Color("AccentColor") : Color.secondary
        let textColor = isSelected ? Color("AccentColor") : Color.secondary
        let iconWeight: Font.Weight = isSelected ? .semibold : .regular
        let textWeight: Font.Weight = isSelected ? .medium : .regular
        
        Button {
            selectedNavigationItem = item
        } label: {
            HStack(spacing: 12) {
                // Left border indicator for selected item
                Rectangle()
                    .fill(isSelected ? Color("AccentColor") : Color.clear)
                    .frame(width: isSelected ? 3 : 0)
                
                Image(systemName: item.iconName)
                    .renderingMode(.template)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: iconWeight))
                    .frame(width: 20)
                
                Text(item.displayName)
                    .foregroundColor(textColor)
                    .font(.system(size: 14, weight: textWeight))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
