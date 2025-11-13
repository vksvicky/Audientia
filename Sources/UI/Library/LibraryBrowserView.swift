//
//  LibraryBrowserView.swift
//  Audientia
//
//  Library browser view with list and grid modes
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Library browser view with list and grid display modes
public struct LibraryBrowserView: View {
    
    @StateObject private var viewModel: LibraryViewModel
    @State private var selectedDirectory: URL?
    
    /// Initialize the library browser view
    /// - Parameters:
    ///   - scanner: Library scanner instance (conforms to LibraryScannerProtocol)
    ///   - indexer: Library indexer instance (conforms to LibraryIndexerProtocol)
    ///   - search: Library search instance
    public init(
        scanner: any LibraryScannerProtocol,
        indexer: any LibraryIndexerProtocol,
        search: LibrarySearch
    ) {
        _viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                scanner: scanner,
                indexer: indexer,
                search: search
            )
        )
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
            
            // Content
            if viewModel.isScanning {
                scanProgressView
            } else if viewModel.filteredTracks.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack {
            // View mode picker
            Picker("View Mode", selection: $viewModel.viewMode) {
                ForEach(LibraryViewModel.ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            
            Spacer()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search library...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                if !viewModel.searchQuery.isEmpty {
                    Button(action: viewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .frame(width: 300)
            
            Spacer()
            
            // Scan button
            Button(action: selectDirectory) {
                Label("Scan Library", systemImage: "folder")
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewMode {
        case .list:
            listView
        case .grid:
            gridView
        }
    }
    
    private var listView: some View {
        List(viewModel.filteredTracks, id: \.id) { track in
            TrackRowView(track: track)
        }
        .listStyle(.plain)
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.filteredTracks, id: \.id) { track in
                    TrackGridItemView(track: track)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No tracks found")
                .font(.title2)
                .foregroundColor(.secondary)
            if viewModel.searchQuery.isEmpty {
                Text("Click 'Scan Library' to add music to your library")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text("Try a different search query")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Scan Progress
    
    private var scanProgressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.scanProgress)
                .progressViewStyle(.linear)
            Text("Scanning library...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            selectedDirectory = url
            Task {
                await viewModel.scanDirectory(url)
            }
        }
    }
}

// MARK: - Track Row View

private struct TrackRowView: View {
    let track: Track
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                Text("\(track.artist) • \(track.album)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatDuration(track.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Track Grid Item View

private struct TrackGridItemView: View {
    let track: Track
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder for artwork
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(track.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 150)
    }
}

#Preview {
    LibraryBrowserView(
        scanner: LibraryScanner(),
        indexer: LibraryIndexer(),
        search: LibrarySearch(indexer: LibraryIndexer())
    )
}
