//
//  ContextualSidebarSections.swift
//  Audientia
//
//  Specialized sections for contextual sidebar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import DataLayer
@preconcurrency import Shared
import SwiftUI

// MARK: - Genre Filter Section

struct GenreFilterSection: View {
    @ObservedObject var viewModel: LibraryBrowserViewModel
    @State private var availableGenres: [String] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.vertical, 4)
            } else if availableGenres.isEmpty {
                Text("No genres found")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(availableGenres.sorted(), id: \.self) { genre in
                    SidebarFilterItem(
                        title: genre,
                        isChecked: Binding(
                            get: { viewModel.selectedGenres.contains(genre) },
                            set: { _ in
                                // Binding setter not needed, action handles the toggle
                            }
                        ),
                        action: { _ in
                            Task {
                                await viewModel.toggleGenre(genre)
                            }
                        }
                    )
                }
            }
        }
        .task {
            await loadAvailableGenres()
        }
    }
    
    private func loadAvailableGenres() async {
        isLoading = true
        await viewModel.loadLibraryIfNeeded()
        let allTracks = viewModel.tracks
        let genres = Set(allTracks.compactMap { $0.genre })
        availableGenres = Array(genres)
        isLoading = false
    }
}

// MARK: - Playlist List Section

struct PlaylistListSection: View {
    @ObservedObject var viewModel: PlaylistSidebarViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.vertical, 4)
            } else if viewModel.playlists.isEmpty {
                Text("No playlists")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(viewModel.playlists) { playlist in
                    SidebarNavItem(
                        icon: playlist.isSmart ? "bolt.fill" : "music.note.list",
                        title: playlist.name,
                        action: {
                            // NOTE: Navigate to playlist detail view when implemented
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadPlaylists()
        }
    }
}

// MARK: - Smart Playlist Section

struct SmartPlaylistSection: View {
    @ObservedObject var viewModel: SmartPlaylistViewModel
    @State private var selectedType: SmartPlaylistType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarNavItem(
                icon: "bolt",
                title: SmartPlaylistType.recentlyAdded.displayName,
                action: {
                    selectedType = .recentlyAdded
                    Task {
                        await viewModel.loadTracks(for: .recentlyAdded)
                    }
                }
            )
            SidebarNavItem(
                icon: "bolt",
                title: SmartPlaylistType.topRated.displayName,
                action: {
                    selectedType = .topRated
                    Task {
                        await viewModel.loadTracks(for: .topRated)
                    }
                }
            )
            SidebarNavItem(
                icon: "bolt",
                title: SmartPlaylistType.fiveStarTracks.displayName,
                action: {
                    selectedType = .fiveStarTracks
                    Task {
                        await viewModel.loadTracks(for: .fiveStarTracks)
                    }
                }
            )
        }
    }
}

// MARK: - Device List Section

struct DeviceListSection: View {
    @ObservedObject var viewModel: DeviceSidebarViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.vertical, 4)
            } else if viewModel.devices.isEmpty {
                Text("No devices")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(viewModel.devices) { device in
                    SidebarNavItem(
                        icon: deviceIcon(for: device.type),
                        title: device.name,
                        action: {
                            // NOTE: Navigate to device detail view when implemented
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadDevices()
        }
    }
    
    private func deviceIcon(for type: DeviceType) -> String {
        switch type {
        case .usb: return "externaldrive"
        case .mtp: return "iphone"
        case .smb: return "network"
        }
    }
}

// MARK: - Sync Options Section

struct SyncOptionsSection: View {
    @ObservedObject var viewModel: DeviceSidebarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SyncContentType.allCases) { contentType in
                SidebarRadioItem(
                    title: contentType.displayName,
                    isSelected: viewModel.syncContentType == contentType,
                    action: {
                        viewModel.setSyncContentType(contentType)
                    }
                )
            }
        }
    }
}

// MARK: - Visualisation Style Section

struct VisualisationStyleSection: View {
    @ObservedObject var viewModel: AudioVisualiserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(VisualisationMode.allCases) { mode in
                SidebarRadioItem(
                    title: mode.displayName,
                    isSelected: viewModel.visualisationMode == mode,
                    action: {
                        viewModel.visualisationMode = mode
                    }
                )
            }
        }
    }
}

// MARK: - Visualisation Settings Section

struct VisualisationSettingsSection: View {
    @ObservedObject var viewModel: AudioVisualiserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sensitivity")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            Slider(value: Binding(
                get: { Double(viewModel.sensitivity) },
                set: { viewModel.sensitivity = Float($0) }
            ), in: 0...1)
            .controlSize(.small)
            
            HStack {
                Text("Smoothing")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            Slider(value: Binding(
                get: { Double(viewModel.smoothing) },
                set: { viewModel.smoothing = Float($0) }
            ), in: 0...1)
            .controlSize(.small)
        }
    }
}
