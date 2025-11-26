//
//  PlaylistPanelView.swift
//  Audientia - Playlist Panel View
//
//  SwiftUI view for the playlist panel in the multi-pane layout
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
import Shared
import SwiftUI

/// Playlist panel view for multi-pane layout
/// Shows playlists and their tracks
@MainActor
public struct PlaylistPanelView: View {
    @StateObject private var viewModel: PlaylistPanelViewModel
    @EnvironmentObject private var trackSelection: TrackSelectionStore
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @State private var showingCreateDialog = false
    @State private var newPlaylistName = ""
    @State private var showingDeleteConfirmation = false
    @State private var playlistToDelete: Playlist?

    public init(viewModel: PlaylistPanelViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: PlaylistPanelViewModel())
        }
    }

    public var body: some View {
        HSplitView {
            // Playlist list
            playlistList
                .frame(minWidth: 200, idealWidth: 250)

            Divider()

            // Track list
            trackList
                .frame(minWidth: 300)
        }
        .task {
            await viewModel.loadPlaylists()
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
        .sheet(isPresented: $showingCreateDialog) {
            createPlaylistDialog
        }
        .alert("Delete Playlist", isPresented: $showingDeleteConfirmation, presenting: playlistToDelete) { playlist in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deletePlaylist(playlist)
                }
            }
        } message: { playlist in
            Text("Are you sure you want to delete \"\(playlist.name)\"? This action cannot be undone.")
        }
    }

    // MARK: - Playlist List

    private var playlistList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
                    .font(.headline)
                Spacer()
                Button(action: {
                    newPlaylistName = ""
                    showingCreateDialog = true
                }, label: {
                    Image(systemName: "plus")
                })
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // Playlist list content
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.playlists.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No Playlists")
                        .font(.headline)
                    Text("Create a playlist to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: Binding(
                    get: { viewModel.selectedPlaylist },
                    set: { playlist in
                        if let playlist = playlist {
                            Task {
                                await viewModel.selectPlaylist(playlist)
                            }
                        }
                    }
                )) {
                    ForEach(viewModel.playlists) { playlist in
                        PlaylistRow(playlist: playlist)
                            .tag(playlist)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    playlistToDelete = playlist
                                    showingDeleteConfirmation = true
                                }, label: {
                                    Label("Delete", systemImage: "trash")
                                })
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    // MARK: - Track List

    private var trackList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let playlist = viewModel.selectedPlaylist {
                    Text(playlist.name)
                        .font(.headline)
                } else {
                    Text("Select a Playlist")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let playlist = viewModel.selectedPlaylist {
                    Text("\(playlist.trackCount) tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        Task {
                            await playbackCoordinator.queueTracks(viewModel.tracks)
                        }
                    } label: {
                        Label("Queue All", systemImage: "list.bullet.rectangle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.tracks.isEmpty)
                }
            }
            .padding()

            Divider()

            // Track list content
            if viewModel.selectedPlaylist == nil {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No Playlist Selected")
                        .font(.headline)
                    Text("Select a playlist from the list to view its tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.tracks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No Tracks")
                        .font(.headline)
                    Text("This playlist is empty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: trackSelectionBinding) {
                    ForEach(viewModel.tracks) { track in
                        TrackRow(track: track)
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

                                Divider()

                                Button(role: .destructive, action: {
                                    Task {
                                        try? await viewModel.removeTrack(track)
                                    }
                                }, label: {
                                    Label("Remove from Playlist", systemImage: "minus.circle")
                                })
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private var trackSelectionBinding: Binding<Track?> {
        Binding(
            get: { trackSelection.selectedTrack },
            set: { newValue in trackSelection.select(newValue) }
        )
    }

    // MARK: - Create Playlist Dialog

    private var createPlaylistDialog: some View {
        VStack(spacing: 20) {
            Text("New Playlist")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("Playlist Name", text: $newPlaylistName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    createPlaylist()
                }

            HStack {
                Button("Cancel") {
                    showingCreateDialog = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    createPlaylist()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Helper Methods

    private func createPlaylist() {
        let name = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        Task {
            do {
                let playlist = try await viewModel.createPlaylist(name: name)
                showingCreateDialog = false
                newPlaylistName = ""
                await viewModel.selectPlaylist(playlist)
            } catch {
                // Error is handled by viewModel.lastError
            }
        }
    }
}

// MARK: - Subviews

@MainActor
private struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack {
            Image(systemName: playlist.isSmart ? "gearshape.fill" : "music.note.list")
                .foregroundColor(playlist.isSmart ? .blue : .primary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.body)
                Text("\(playlist.trackCount) tracks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

@MainActor
private struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.body)
                Text(track.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatDuration(track.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
