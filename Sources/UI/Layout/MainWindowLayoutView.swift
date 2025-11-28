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
public struct MainWindowLayoutView: View {
    @StateObject private var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var libraryBrowserViewModel = LibraryBrowserViewModel()
    @State private var selectedNavigationItem: NavigationItem = .home
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
            MainWindowPlayerControls(nowPlayingViewModel: nowPlayingViewModel)
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
            MainWindowNavigationSidebar(selectedNavigationItem: $selectedNavigationItem)
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
            MainWindowPlaylistPanel()
                .frame(width: 300)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1000)
        }
    }
    
    private var mainContentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar
            MainWindowToolbar()
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
}
