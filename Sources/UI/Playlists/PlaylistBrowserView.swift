//
//  PlaylistBrowserView.swift
//  Audientia - Playlist Browser View
//
//  Main view for browsing and managing playlists
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import os.log
import Shared
import SwiftUI

/// Main playlist browser view
/// BDD: As a user, I want to view all my playlists and manage them
@MainActor
public struct PlaylistBrowserView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: PlaylistViewModel
    @State private var showingCreateDialog = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylist: Shared.Playlist?
    @State private var showingDeleteConfirmation = false
    @State private var playlistToDelete: Shared.Playlist?
    @State private var showingRenameDialog = false
    @State private var renameText = ""
    
    // MARK: - Initialization
    
    /// Initialize with PlaylistManager
    /// - Parameter playlistManager: The playlist manager to use (optional, creates default if not provided)
    public init(playlistManager: (any PlaylistManagerProtocol)? = nil) {
        if let playlistManager = playlistManager {
            _viewModel = StateObject(wrappedValue: PlaylistViewModel(playlistManager: playlistManager))
        } else {
            // In a real app, this would get the PlaylistManager from a dependency injection container
            // For now, we'll require it to be provided
            fatalError("PlaylistManager must be provided")
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with create button
            headerView
            
            // Playlist list
            if viewModel.isLoading {
                loadingView
            } else if viewModel.playlists.isEmpty {
                emptyStateView
            } else {
                playlistListView
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            Logger.userInterface.info("PlaylistBrowserView appeared")
            Task {
                await viewModel.loadPlaylists()
            }
        }
        .onDisappear {
            Logger.userInterface.debug("PlaylistBrowserView disappeared")
        }
        .sheet(isPresented: $showingCreateDialog) {
            createPlaylistDialog
        }
        .alert("Delete Playlist", isPresented: $showingDeleteConfirmation, presenting: playlistToDelete) { playlist in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deletePlaylist(id: playlist.id)
                }
            }
        } message: { playlist in
            Text("Are you sure you want to delete \"\(playlist.name)\"? This action cannot be undone.")
        }
        .alert("Rename Playlist", isPresented: $showingRenameDialog) {
            TextField("Playlist Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let playlist = selectedPlaylist {
                    Task {
                        try? await viewModel.updatePlaylistName(id: playlist.id, name: renameText)
                    }
                }
            }
        } message: { _ in
            Text("Enter a new name for the playlist.")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Playlists")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: {
                newPlaylistName = ""
                showingCreateDialog = true
            }, label: {
                Label("New Playlist", systemImage: "plus")
            })
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading playlists...")
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
            
            Text("No Playlists")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Create your first playlist to get started")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                newPlaylistName = ""
                showingCreateDialog = true
            }, label: {
                Label("Create Playlist", systemImage: "plus")
            })
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Playlist List View
    
    private var playlistListView: some View {
        List {
            ForEach(viewModel.playlists) { playlist in
                PlaylistRowView(playlist: playlist)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPlaylist = playlist
                        // In a full implementation, this would navigate to playlist detail view
                    }
                    .contextMenu {
                        Button(action: {
                            selectedPlaylist = playlist
                            renameText = playlist.name
                            showingRenameDialog = true
                        }, label: {
                            Label("Rename", systemImage: "pencil")
                        })
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            playlistToDelete = playlist
                            showingDeleteConfirmation = true
                        }, label: {
                            Label("Delete", systemImage: "trash")
                        })
                    }
            }
        }
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
                _ = try await viewModel.createPlaylist(name: name)
                showingCreateDialog = false
                newPlaylistName = ""
            } catch {
                Logger.userInterface.error("Failed to create playlist: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Playlist Row View

private struct PlaylistRowView: View {
    let playlist: Shared.Playlist
    
    var body: some View {
        HStack {
            // Playlist icon
            Image(systemName: playlist.isSmart ? "gearshape.fill" : "music.note.list")
                .foregroundColor(playlist.isSmart ? .blue : .primary)
                .frame(width: 24)
            
            // Playlist info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.body)
                    .fontWeight(.medium)
                
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
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
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
