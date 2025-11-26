//
//  LibraryBrowserView.swift
//  Audientia
//
//  Enhanced library browser UI
//
//  Copyright © 2025 CycleRunCode Club
//

import Shared
import SwiftUI

@MainActor
public struct LibraryBrowserView: View {
    @ObservedObject var viewModel: LibraryBrowserViewModel
    @EnvironmentObject private var trackSelection: TrackSelectionStore
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 16, alignment: .top)
    ]
    
    public init(viewModel: LibraryBrowserViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
            footer
        }
        .background(Color(NSColor.controlBackgroundColor))
        .task {
            await viewModel.loadLibraryIfNeeded()
        }
        .alert("Error", isPresented: .constant(viewModel.lastError != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(
                    "Search library",
                    text: Binding(
                        get: { viewModel.searchText },
                        set: { newValue in
                            Task {
                                await viewModel.updateSearchText(newValue)
                            }
                        }
                    )
                )
                .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            Picker("View Mode", selection: Binding(
                get: { viewModel.viewMode },
                set: { newValue in Task { await viewModel.setViewMode(newValue) } }
            )) {
                ForEach(LibraryViewMode.allCases, id: \.self) { mode in
                    Text(mode.displayTitle).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            
            Menu("Sort") {
                ForEach(LibrarySortOrder.allCases, id: \.self) { order in
                    Button(order.displayTitle) {
                        Task {
                            await viewModel.setSortOrder(order)
                        }
                    }
                }
                Divider()
                Button("Ascending") {
                    Task { await viewModel.setSortOrder(viewModel.sortOrder, direction: .ascending) }
                }
                Button("Descending") {
                    Task { await viewModel.setSortOrder(viewModel.sortOrder, direction: .descending) }
                }
            }
            
            Menu("Group") {
                ForEach(LibraryGrouping.allCases, id: \.self) { grouping in
                    Button(grouping.displayTitle) {
                        Task { await viewModel.setGrouping(grouping) }
                    }
                }
            }
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button {
                Task { await viewModel.refreshLibrary() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)

            Button {
                Task {
                    await playbackCoordinator.queueTracks(viewModel.filteredTracks)
                }
            } label: {
                Label("Queue All", systemImage: "list.bullet.rectangle")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.filteredTracks.isEmpty || viewModel.isLoading)
        }
        .padding()
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading library…")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredTracks.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No tracks to show")
                    .font(.title3)
                Text(
                    viewModel.searchText.isEmpty ?
                        "Import music or run a library scan to get started." :
                        "Try a different search or clear the filter."
                )
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch viewModel.viewMode {
            case .list, .compact:
                listView
            case .grid:
                gridView
            }
        }
    }
    
    private var listView: some View {
        List(selection: trackSelectionBinding) {
            ForEach(viewModel.filteredTracks) { track in
                LibraryTrackRow(track: track, compact: viewModel.viewMode == .compact)
                    .tag(track as Track?)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        trackSelection.select(track)
                    }
                    .onTapGesture(count: 2) {
                        trackSelection.select(track)
                        Task {
                            try? await playbackCoordinator.playSelectedTrack()
                        }
                    }
                    .contextMenu {
                        Button {
                            trackSelection.select(track)
                            Task {
                                try? await playbackCoordinator.playSelectedTrack()
                            }
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }

                        Button {
                            trackSelection.select(track)
                            Task {
                                await playbackCoordinator.queueSelectedTrack()
                            }
                        } label: {
                            Label("Add to Queue", systemImage: "plus.circle")
                        }
                    }
            }
        }
        .listStyle(.inset)
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.filteredTracks) { track in
                    gridItem(for: track)
                }
            }
            .padding()
        }
    }

    private func gridItem(for track: Track) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(track.title)
                .font(.headline)
                .lineLimit(2)
            Text(track.artist)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(track.album)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatDuration(track.duration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    trackSelection.selectedTrack?.id == track.id ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .onTapGesture {
            trackSelection.select(track)
        }
        .onTapGesture(count: 2) {
            trackSelection.select(track)
            Task {
                try? await playbackCoordinator.playSelectedTrack()
            }
        }
        .contextMenu { gridItemContextMenu(for: track) }
    }

    @ViewBuilder
    private func gridItemContextMenu(for track: Track) -> some View {
        Button {
            trackSelection.select(track)
            Task {
                try? await playbackCoordinator.playSelectedTrack()
            }
        } label: {
            Label("Play", systemImage: "play.fill")
        }

        Button {
            trackSelection.select(track)
            Task {
                await playbackCoordinator.queueSelectedTrack()
            }
        } label: {
            Label("Add to Queue", systemImage: "plus.circle")
        }
    }
    
    private var footer: some View {
        HStack {
            Text("\(viewModel.filteredTracks.count) of \(viewModel.totalTrackCount) tracks")
                .foregroundColor(.secondary)
            Spacer()
            if !viewModel.searchText.isEmpty {
                Button("Clear Search") {
                    Task { await viewModel.updateSearchText("") }
                }
            }
        }
        .padding([.horizontal, .bottom])
    }
    
    private var trackSelectionBinding: Binding<Track?> {
        Binding(
            get: { trackSelection.selectedTrack },
            set: { newValue in trackSelection.select(newValue) }
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
@MainActor
private struct LibraryTrackRow: View {
    let track: Track
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.title3)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                Text(track.title)
                    .font(compact ? .subheadline : .headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text(track.artist)
                    Text("•")
                    Text(track.album)
                    if let year = track.year {
                        Text("•")
                        Text(String(year))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            Text(formatDuration(track.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, compact ? 2 : 6)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private extension LibraryViewMode {
    var displayTitle: String {
        switch self {
        case .list:
            return "List"
        case .grid:
            return "Grid"
        case .compact:
            return "Compact"
        }
    }
}

private extension LibraryGrouping {
    var displayTitle: String {
        switch self {
        case .none:
            return "None"
        case .artist:
            return "Artist"
        case .album:
            return "Album"
        case .genre:
            return "Genre"
        case .year:
            return "Year"
        case .rating:
            return "Rating"
        }
    }
}

private extension LibrarySortOrder {
    var displayTitle: String {
        switch self {
        case .title:
            return "Title"
        case .artist:
            return "Artist"
        case .album:
            return "Album"
        case .year:
            return "Year"
        case .rating:
            return "Rating"
        case .duration:
            return "Duration"
        case .dateAdded:
            return "Date Added"
        }
    }
}
