//
//  PlaylistEditorView.swift
//  Audientia - Playlist Editor View
//
//  View for editing individual playlists
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import os.log
import Shared
import SwiftUI

/// Playlist editor view
/// BDD: As a user, I want to edit a playlist and manage its tracks
@MainActor
public struct PlaylistEditorView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: PlaylistEditorViewModel
    @State private var showingRenameDialog = false
    @State private var renameText = ""
    @State private var showingAddTrackDialog = false
    
    private let playlistId: UUID
    
    // MARK: - Initialisation
    
    /// Initialise with PlaylistManager and playlist ID
    /// - Parameters:
    ///   - playlistManager: The playlist manager to use
    ///   - playlistId: The ID of the playlist to edit
    public init(playlistManager: any PlaylistManagerProtocol, playlistId: UUID) {
        self.playlistId = playlistId
        _viewModel = StateObject(wrappedValue: PlaylistEditorViewModel(playlistManager: playlistManager))
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with playlist name and rename button
            headerView
            
            // Track list
            if viewModel.isLoading {
                loadingView
            } else if viewModel.tracks.isEmpty {
                emptyStateView
            } else {
                trackListView
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            Logger.userInterface.info("PlaylistEditorView appeared for playlist: \(playlistId)")
            Task {
                await viewModel.loadPlaylist(id: playlistId)
            }
        }
        .onDisappear {
            Logger.userInterface.debug("PlaylistEditorView disappeared")
        }
        .alert("Rename Playlist", isPresented: $showingRenameDialog) {
            TextField("Playlist Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                Task {
                    try? await viewModel.updatePlaylistName(renameText)
                }
            }
        } message: {
            Text("Enter a new name for the playlist.")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            if let playlist = viewModel.playlist {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Label("\(playlist.trackCount) tracks", systemImage: "music.note")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if playlist.totalDuration > 0 {
                            Label(formatDuration(playlist.totalDuration), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if playlist.isSmart {
                            Label("Smart", systemImage: "gearshape")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                Text("Loading...")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.playlist != nil {
                Button(action: {
                    if let playlist = viewModel.playlist {
                        renameText = playlist.name
                        showingRenameDialog = true
                    }
                }, label: {
                    Label("Rename", systemImage: "pencil")
                })
                
                Button(action: {
                    showingAddTrackDialog = true
                }, label: {
                    Label("Add Track", systemImage: "plus")
                })
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading playlist...")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Tracks")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add tracks to this playlist to get started")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingAddTrackDialog = true
            }, label: {
                Label("Add Track", systemImage: "plus")
            })
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Track List View
    
    private var trackListView: some View {
        List {
            ForEach(viewModel.tracks) { track in
                TrackRowView(track: track)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button(role: .destructive, action: {
                            Task {
                                try? await viewModel.removeTrack(track)
                            }
                        }, label: {
                            Label("Remove", systemImage: "trash")
                        })
                    }
            }
            .onMove { source, destination in
                handleMove(from: source, to: destination)
            }
        }
    }
    
    // MARK: - Drag and Drop Handler
    
    private func handleMove(from source: IndexSet, to destination: Int) {
        var reorderedTracks = viewModel.tracks
        reorderedTracks.move(fromOffsets: source, toOffset: destination)
        
        let trackIds = reorderedTracks.map { $0.id }
        Task {
            try? await viewModel.reorderTracks(trackIds)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Track Row View

private struct TrackRowView: View {
    let track: Shared.Track
    
    var body: some View {
        HStack {
            // Track number placeholder
            Text("•")
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(track.artist) • \(track.album)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Duration
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
