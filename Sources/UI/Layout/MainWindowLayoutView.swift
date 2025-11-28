//
//  MainWindowLayoutView.swift
//  Audientia
//
//  Main window layout matching MediaMonkey's design
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AppKitBridge
import AudioCore
import DataLayer
import Shared
import SwiftUI

/// Main window layout with left navigation, toolbar, playlist panel, and player controls
@MainActor
// swiftlint:disable:next type_body_length
public struct MainWindowLayoutView: View {
    @StateObject private var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var playlistPanelViewModel = PlaylistPanelViewModel()
    @StateObject private var libraryBrowserViewModel = LibraryBrowserViewModel()
    @State private var selectedNavigationItem: NavigationItem = .home
    @State private var showingFilePicker = false
    @State private var importError: Error?
    
    private let audioEngine: AudioEngineProtocol
    @StateObject private var importCoordinator: TrackImportCoordinator
    
    public init(audioEngine: AudioEngineProtocol) {
        self.audioEngine = audioEngine
        _nowPlayingViewModel = StateObject(wrappedValue: NowPlayingViewModel(audioEngine: audioEngine))
        _importCoordinator = StateObject(
            wrappedValue: TrackImportCoordinator(
                audioEngine: audioEngine,
                indexer: LibraryIndexer()
            )
        )
    }
    
    public var body: some View {
        mainLayout
    }
    
    // MARK: - Layout Structure
    
    private var mainLayout: some View {
        VStack(spacing: 0) {
            // Main content area (navigation, content, playlist)
            horizontalLayout
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Player Controls at Bottom (spans full width)
            playerControls
                .frame(height: 80)
                .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 1000, minHeight: 600)
        .onAudioFilesDropped { urls in
            Task {
                do {
                    try await importCoordinator.importFiles(urls: urls)
                } catch {
                    importError = error
                }
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") {
                importError = nil
            }
        } message: {
            if let error = importError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left Navigation Sidebar - FIXED WIDTH (highest priority)
            navigationSidebar
                .frame(width: 200)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1000)
            
            Divider()
                .frame(width: 1)
                .layoutPriority(1000)
            
            // Main Content Area - FLEXIBLE (lowest priority, fills remaining space)
            mainContentArea
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .layoutPriority(0)
                .clipped()
            
            Divider()
                .frame(width: 1)
                .layoutPriority(1000)
            
            // Right Playlist Panel - FIXED WIDTH (highest priority)
            playlistPanel
                .frame(width: 300)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1000)
        }
    }
    
    private var mainContentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar
            toolbar
                .frame(height: 44)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content Area (Library Browser or other views)
            contentArea
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
    }
    
    // MARK: - Navigation Sidebar
    
    private var navigationSidebar: some View {
        List(selection: $selectedNavigationItem) {
            ForEach(NavigationItem.allCases, id: \.self) { item in
                NavigationLink(value: item) {
                    HStack {
                        Image(systemName: item.iconName)
                            .foregroundColor(item == selectedNavigationItem ? .orange : .secondary)
                            .frame(width: 20, alignment: .leading)
                        Text(item.displayName)
                            .foregroundColor(item == selectedNavigationItem ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .background(Color(NSColor.controlBackgroundColor))
        .frame(width: 200)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Left side: App-specific icons
            Button(action: {}, label: {
                Image(systemName: "music.note.house.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
            })
            .buttonStyle(.plain)
            .help("Home")
            
            Button(action: {}, label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
            })
            .buttonStyle(.plain)
            .help("Search")
            
            Spacer()
            
            // Right side: Additional controls
            Button(action: {}, label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            })
            .buttonStyle(.plain)
            .help("More Options")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Content Area
    
    @ViewBuilder
    private var contentArea: some View {
        switch selectedNavigationItem {
        case .home:
            homeView
        case .playing:
            playingView
        case .entireLibrary:
            LibraryBrowserView(viewModel: libraryBrowserViewModel)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        case .music:
            LibraryBrowserView(viewModel: libraryBrowserViewModel)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        case .playlists:
            PlaylistBrowserView(playlistManager: PlaylistManager(indexer: LibraryIndexer()))
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        case .devices:
            DeviceSyncView()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        case .folders:
            LibraryBrowserView(viewModel: libraryBrowserViewModel)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        case .web:
            Text("Web")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .pinned:
            Text("Pinned")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var homeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome to Audientia")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                Text("Audientia is a powerful media library manager for your music collection.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    if let url = URL(string: "https://github.com/vksvicky/Audientia") {
                        Link(">> What's New?", destination: url)
                        Link(">> Introduction", destination: url)
                        Link(">> Add files to the library", destination: url)
                        Link(">> Play files", destination: url)
                        Link(">> Update/Edit your files", destination: url)
                        Link(">> Sync your files", destination: url)
                    }
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(30)
        }
    }
    
    private var playingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let track = nowPlayingViewModel.currentTrack {
                    Text("Now Playing")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.top, 20)
                    
                    Text("\(track.title) - \(track.artist)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    Text("No track playing")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(30)
        }
    }
    
    // MARK: - Playlist Panel
    
    private var playlistPanel: some View {
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
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Playlist content - show playlists list
            if playlistPanelViewModel.playlists.isEmpty {
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
                    get: { playlistPanelViewModel.selectedPlaylist },
                    set: { playlist in
                        if let playlist = playlist {
                            Task {
                                await playlistPanelViewModel.selectPlaylist(playlist)
                            }
                        }
                    }
                )) {
                    ForEach(playlistPanelViewModel.playlists) { playlist in
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
            if let selectedPlaylist = playlistPanelViewModel.selectedPlaylist {
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
                    
                    if playlistPanelViewModel.tracks.isEmpty {
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
                            ForEach(playlistPanelViewModel.tracks) { track in
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
            await playlistPanelViewModel.loadPlaylists()
        }
    }
    
    // MARK: - Player Controls
    
    private var playerControls: some View {
        HStack(spacing: 16) {
            // Track Info
            if let track = nowPlayingViewModel.currentTrack {
                HStack(spacing: 12) {
                    // Album art placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No track selected")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Playback Controls
            HStack(spacing: 8) {
                Button(action: { Task { try? await nowPlayingViewModel.playPrevious() } }, label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                .disabled(nowPlayingViewModel.queue.count <= 1)
                
                Button(action: {
                    Task {
                        if nowPlayingViewModel.isPlaying {
                            await nowPlayingViewModel.pause()
                        } else {
                            try? await nowPlayingViewModel.play()
                        }
                    }
                }, label: {
                    Image(systemName: nowPlayingViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                })
                .buttonStyle(.plain)
                
                Button(action: { Task { await nowPlayingViewModel.stop() } }, label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                Button(action: { Task { try? await nowPlayingViewModel.playNext() } }, label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                .disabled(nowPlayingViewModel.queue.count <= 1)
            }
            
            Spacer()
            
            // Additional Controls
            HStack(spacing: 8) {
                Button(action: {}, label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                Button(action: {}, label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                Button(action: {}, label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                // Volume control
                HStack(spacing: 4) {
                    Button(action: {}, label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                    })
                    .buttonStyle(.plain)
                    
                    Slider(value: Binding(
                        get: { Double(nowPlayingViewModel.volume) },
                        set: { nowPlayingViewModel.volume = Float($0) }
                    ), in: 0...1)
                    .frame(width: 100)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Navigation Items

enum NavigationItem: String, CaseIterable {
    case home
    case playing
    case entireLibrary
    case music
    case playlists
    case devices
    case folders
    case web
    case pinned
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .playing: return "Playing"
        case .entireLibrary: return "Entire Library"
        case .music: return "Music"
        case .playlists: return "Playlists"
        case .devices: return "Devices & Services"
        case .folders: return "Folders"
        case .web: return "Web"
        case .pinned: return "Pinned"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .playing: return "music.note"
        case .entireLibrary: return "building.2.fill"
        case .music: return "headphones"
        case .playlists: return "list.bullet"
        case .devices: return "iphone"
        case .folders: return "folder.fill"
        case .web: return "globe"
        case .pinned: return "pin.fill"
        }
    }
}
