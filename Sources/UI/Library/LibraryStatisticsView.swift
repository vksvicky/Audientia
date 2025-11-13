//
//  LibraryStatisticsView.swift
//  Audientia
//
//  Library statistics display view
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import Shared
import SwiftUI

/// View displaying library statistics
public struct LibraryStatisticsView: View {
    
    @StateObject private var viewModel: LibraryStatisticsViewModel
    
    /// Initialize the library statistics view
    /// - Parameter calculator: Library statistics calculator
    public init(calculator: LibraryStatisticsCalculator) {
        _viewModel = StateObject(
            wrappedValue: LibraryStatisticsViewModel(calculator: calculator)
        )
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Library Statistics")
                    .font(.largeTitle)
                    .padding(.horizontal)
                
                // Statistics grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatisticCard(
                        title: "Tracks",
                        value: "\(viewModel.statistics?.trackCount ?? 0)",
                        icon: "music.note.list"
                    )
                    
                    StatisticCard(
                        title: "Artists",
                        value: "\(viewModel.statistics?.artistCount ?? 0)",
                        icon: "person.2.fill"
                    )
                    
                    StatisticCard(
                        title: "Albums",
                        value: "\(viewModel.statistics?.albumCount ?? 0)",
                        icon: "square.stack.fill"
                    )
                    
                    StatisticCard(
                        title: "Total Duration",
                        value: formatDuration(viewModel.statistics?.totalDuration ?? 0),
                        icon: "clock.fill"
                    )
                    
                    StatisticCard(
                        title: "Total Size",
                        value: formatFileSize(viewModel.statistics?.totalFileSize ?? 0),
                        icon: "internaldrive.fill"
                    )
                    
                    StatisticCard(
                        title: "Average Bitrate",
                        value: String(format: "%.0f kbps", viewModel.statistics?.averageBitrate ?? 0),
                        icon: "waveform"
                    )
                }
                .padding(.horizontal)
                
                // Refresh button
                Button(action: viewModel.refresh) {
                    Label("Refresh Statistics", systemImage: "arrow.clockwise")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            viewModel.refresh()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Statistic Card

private struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - ViewModel

@MainActor
private final class LibraryStatisticsViewModel: ObservableObject {
    @Published var statistics: LibraryStatistics?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let calculator: LibraryStatisticsCalculator
    
    init(calculator: LibraryStatisticsCalculator) {
        self.calculator = calculator
    }
    
    func refresh() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let stats = try await calculator.calculateStatistics()
                statistics = stats
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}

#Preview {
    LibraryStatisticsView(calculator: LibraryStatisticsCalculator(indexer: nil))
}
