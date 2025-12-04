//
//  MainWindowTabContentView.swift
//  Audientia
//
//  Tab content view builder for main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import DataLayer
import SwiftUI

/// Tab content view builder for main window
struct MainWindowTabContentView: View {
    let selectedTab: TabItem
    let homeViewModel: HomeViewModel
    let libraryBrowserViewModel: LibraryBrowserViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let audioEngine: AudioEngineProtocol
    let audioVisualiserViewModel: AudioVisualiserViewModel
    
    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeContentView(viewModel: homeViewModel)
            case .library:
                LibraryBrowserView(viewModel: libraryBrowserViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task(id: selectedTab) {
                        if selectedTab == .library {
                            await libraryBrowserViewModel.loadLibraryIfNeeded()
                        }
                    }
            case .playlists:
                PlaylistBrowserView(playlistManager: PlaylistManager(indexer: LibraryIndexer()))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .devices:
                DeviceSyncView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .visualiser:
                AudioVisualiserView(
                    nowPlayingViewModel: nowPlayingViewModel,
                    audioEngine: audioEngine as? AudioEngine,
                    viewModel: audioVisualiserViewModel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // Update ViewModel with current nowPlayingViewModel reference
                    audioVisualiserViewModel.updateNowPlayingViewModel(nowPlayingViewModel)
                }
            }
        }
    }
}
