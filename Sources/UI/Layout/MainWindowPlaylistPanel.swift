//
//  MainWindowPlaylistPanel.swift
//  Audientia
//
//  Playlist panel component for the main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import DataLayer
import Shared
import SwiftUI

struct MainWindowPlaylistPanel: View {
    @StateObject private var viewModel = PlaylistPanelViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("'Playing' list")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Menu {
                    Button("Selected") {}
                } label: {
                    Text("")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 16, height: 16)
                .overlay(
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Playlist content - show playlists list
            if viewModel.playlists.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Select a Playlist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Show playlist list
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
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.secondary)
                            Text(playlist.name)
                        }
                        .tag(playlist)
                    }
                }
                .listStyle(.sidebar)
                .frame(maxHeight: .infinity)
            }
            
            Divider()
            
            // Track list for selected playlist
            if let selectedPlaylist = viewModel.selectedPlaylist {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(selectedPlaylist.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(selectedPlaylist.trackCount) tracks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    if viewModel.tracks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("No Playlist Select")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.tracks) { track in
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .font(.system(size: 11))
                                            .lineLimit(1)
                                        Text(track.artist)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("No Playlist Select")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Select a playlist from the list to vi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .task {
            await viewModel.loadPlaylists()
        }
    }
}
