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
import os.log
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
        ZStack {
            // Background to ensure view takes space
            Color(NSColor.windowBackgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    HomeContentView(viewModel: homeViewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            Logger.userInterface.info("MainWindowTabContentView: Home tab appeared")
                        }
                case .library:
                    LibraryBrowserView(viewModel: libraryBrowserViewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .task(id: selectedTab) {
                            if selectedTab == .library {
                                await libraryBrowserViewModel.loadLibraryIfNeeded()
                            }
                        }
                        .onAppear {
                            Logger.userInterface.info("MainWindowTabContentView: Library tab appeared")
                        }
                case .playlists:
                    PlaylistBrowserView(playlistManager: PlaylistManager(indexer: LibraryIndexer()))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            Logger.userInterface.info("MainWindowTabContentView: Playlists tab appeared")
                        }
                case .devices:
                    DeviceSyncView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            Logger.userInterface.info("MainWindowTabContentView: Devices tab appeared")
                        }
                case .visualiser:
                    AudioVisualiserView(
                        nowPlayingViewModel: nowPlayingViewModel,
                        audioEngine: audioEngine as? AudioEngine,
                        viewModel: audioVisualiserViewModel
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        Logger.userInterface.info("MainWindowTabContentView: Visualiser tab appeared")
                        // Update ViewModel with current nowPlayingViewModel reference
                        audioVisualiserViewModel.updateNowPlayingViewModel(nowPlayingViewModel)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onChange(of: selectedTab) { oldValue, newValue in
            let tabChangeMessage = "MainWindowTabContentView: Tab changed from \(oldValue.rawValue) " +
                "to \(newValue.rawValue)"
            Logger.userInterface.info("\(tabChangeMessage)")
        }
    }
}
