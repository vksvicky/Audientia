//
//  LibraryBrowserView.swift
//  Audientia
//
//  Enhanced library browser UI
//
//  Copyright © 2025 CycleRunCode Club
//

import AppKit
import Shared
import SwiftUI

@MainActor
public struct LibraryBrowserView: View {
    @ObservedObject var viewModel: LibraryBrowserViewModel
    @EnvironmentObject private var trackSelection: TrackSelectionStore
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @StateObject private var listNavigationManager = ListNavigationManager<Track>()
    
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
        .onChange(of: viewModel.filteredTracks) { _, newValue in
            // Update list navigation manager when tracks change
            listNavigationManager.updateItems(newValue)
        }
        .onKeyPress(.upArrow) {
            // Handle Up arrow key
            handleArrowKeyNavigation(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            // Handle Down arrow key
            handleArrowKeyNavigation(direction: .down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            // Handle Left arrow key (for grid view)
            if viewModel.viewMode == .grid {
                handleArrowKeyNavigation(direction: .left)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            // Handle Right arrow key (for grid view)
            if viewModel.viewMode == .grid {
                handleArrowKeyNavigation(direction: .right)
                return .handled
            }
            return .ignored
        }
        .onChange(of: listNavigationManager.selectedIndex) { _, newValue in
            // Update track selection when navigation manager selection changes
            if let index = newValue,
               index >= 0,
               index < viewModel.filteredTracks.count {
                trackSelection.select(viewModel.filteredTracks[index])
            }
        }
        .onChange(of: trackSelection.selectedTrack) { _, newValue in
            // Sync navigation manager when selection changes from outside (e.g., mouse click)
            if let track = newValue,
               let index = viewModel.filteredTracks.firstIndex(of: track) {
                listNavigationManager.selectIndex(index)
            }
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
                LibraryTrackRow(
                    track: track,
                    compact: viewModel.viewMode == .compact,
                    artwork: artworkImage(for: track)
                )
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
                    .onAppear {
                        Task { await viewModel.loadArtwork(for: track) }
                    }
            }
        }
        .listStyle(.inset)
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.filteredTracks) { track in
                    gridItem(for: track, artwork: artworkImage(for: track))
                        .onAppear {
                            Task { await viewModel.loadArtwork(for: track) }
                        }
                }
            }
            .padding()
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
    
    private func artworkImage(for track: Track) -> NSImage? {
        guard let artwork = viewModel.artwork(for: track) else {
            return nil
        }
        return NSImage(data: artwork.data)
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
    
    // MARK: - Keyboard Navigation
    
    /// Arrow key navigation directions
    private enum ArrowDirection {
        case up
        case down
        case left
        case right
    }
    
    /// Handle arrow key navigation
    /// - Parameter direction: The arrow key direction
    private func handleArrowKeyNavigation(direction: ArrowDirection) {
        switch direction {
        case .up:
            _ = listNavigationManager.moveUp()
        case .down:
            _ = listNavigationManager.moveDown()
        case .left:
            // Calculate columns per row for grid (approximate based on view width)
            // For now, use a default of 3 columns for grid navigation
            let columnsPerRow = viewModel.viewMode == .grid ? 3 : 1
            _ = listNavigationManager.moveLeft(columnsPerRow: columnsPerRow)
        case .right:
            // Calculate columns per row for grid
            let columnsPerRow = viewModel.viewMode == .grid ? 3 : 1
            _ = listNavigationManager.moveRight(columnsPerRow: columnsPerRow)
        }
    }
}

// MARK: - Grid View Helpers
private extension LibraryBrowserView {
    func gridItem(for track: Track, artwork: NSImage?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            artworkGridView(for: artwork)
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
    func gridItemContextMenu(for track: Track) -> some View {
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
    
    func artworkGridView(for artwork: NSImage?) -> some View {
        Group {
            if let artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(NSColor.windowBackgroundColor)
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 120)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

@MainActor
private struct LibraryTrackRow: View {
    let track: Track
    let compact: Bool
    let artwork: NSImage?
    
    var body: some View {
        HStack(spacing: 12) {
            artworkThumbnail
            
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

    private var artworkThumbnail: some View {
        Group {
            if let artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: compact ? 32 : 44, height: compact ? 32 : 44)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.gray.opacity(0.2))
        )
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
