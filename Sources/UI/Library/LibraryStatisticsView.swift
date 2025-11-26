//
//  LibraryStatisticsView.swift
//  Audientia
//
//  Library statistics panel view
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Shared
import SwiftUI

/// View displaying library statistics
@MainActor
public struct LibraryStatisticsView: View {
    @StateObject private var viewModel: LibraryStatisticsViewModel
    
    public init(statisticsCalculator: (any LibraryStatisticsProtocol)? = nil, indexer: LibraryIndexerProtocol? = nil) {
        let calculator = statisticsCalculator ?? LibraryStatisticsCalculator(indexer: indexer)
        _viewModel = StateObject(
            wrappedValue: LibraryStatisticsViewModel(statisticsCalculator: calculator)
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library Statistics")
                .font(.headline)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let stats = viewModel.statistics {
                statisticsContent(stats)
            } else {
                Text("No statistics available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 250, idealWidth: 300)
        .task {
            await viewModel.loadStatistics()
        }
    }
    
    @ViewBuilder
    private func statisticsContent(_ stats: LibraryStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            StatisticRow(
                label: "Total Tracks",
                value: "\(stats.trackCount)",
                icon: "music.note"
            )
            
            StatisticRow(
                label: "Unique Artists",
                value: "\(stats.artistCount)",
                icon: "person.2"
            )
            
            StatisticRow(
                label: "Unique Albums",
                value: "\(stats.albumCount)",
                icon: "opticaldisc"
            )
            
            StatisticRow(
                label: "Total Duration",
                value: formatDuration(stats.totalDuration),
                icon: "clock"
            )
            
            StatisticRow(
                label: "Total Size",
                value: formatFileSize(stats.totalFileSize),
                icon: "externaldrive"
            )
        }
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
}

private struct StatisticRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

/// ViewModel for library statistics
@MainActor
final class LibraryStatisticsViewModel: ObservableObject {
    @Published private(set) var statistics: LibraryStatistics?
    @Published private(set) var isLoading = false
    
    private let statisticsCalculator: any LibraryStatisticsProtocol
    
    init(statisticsCalculator: any LibraryStatisticsProtocol) {
        self.statisticsCalculator = statisticsCalculator
    }
    
    func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            statistics = try await statisticsCalculator.calculateStatistics()
        } catch {
            // Handle error silently for now - could add error state if needed
            statistics = nil
        }
    }
}
