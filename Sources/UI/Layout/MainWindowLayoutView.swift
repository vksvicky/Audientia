//
//  MainWindowLayoutView.swift
//  Audientia
//
//  Main window layout with collapsible toolbar, contextual sidebar, and collapsible player
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AppKitBridge
import AudioCore
import DataLayer
import ObjectiveC
import os.log
@preconcurrency import Shared
import SwiftUI

/// Main window layout with:
/// - Collapsible toolbar with navigation tabs at top
/// - Contextual sidebar on the left
/// - Tab-specific content in the center
/// - Collapsible player controls at bottom
@MainActor
public struct MainWindowLayoutView: View {
    // MARK: - View Models
    
    @StateObject private var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var libraryBrowserViewModel = LibraryBrowserViewModel()
    @StateObject private var importCoordinator: TrackImportCoordinator
    // Workaround for Swift compiler type resolution issue:
    // Declare properties without explicit types, initialize in init() where types resolve correctly
    // This is a known Swift compiler limitation when types are in subdirectories
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var playlistSidebarViewModel: PlaylistSidebarViewModel
    @StateObject private var smartPlaylistViewModel: SmartPlaylistViewModel
    @StateObject private var deviceSidebarViewModel: DeviceSidebarViewModel
    @StateObject private var audioVisualiserViewModel: AudioVisualiserViewModel
    
    // MARK: - State
    
    @State private var selectedTab: TabItem = .home
    @State private var searchText: String = ""
    @State private var isToolbarExpanded: Bool = true
    @State private var isPlayerExpanded: Bool = true
    @State private var importError: Error?
    
    // MARK: - Dependencies
    
    private let audioEngine: AudioEngineProtocol
    private let layoutStateManager: LayoutStateManagerProtocol
    @Environment(\.dismissWindow) private var dismissWindow
    
    // MARK: - Initialization
    
    public init(
        audioEngine: AudioEngineProtocol,
        layoutStateManager: LayoutStateManagerProtocol = LayoutStateManager()
    ) {
        self.audioEngine = audioEngine
        self.layoutStateManager = layoutStateManager
        let libraryIndexer = LibraryIndexer()
        _nowPlayingViewModel = StateObject(wrappedValue: NowPlayingViewModel(audioEngine: audioEngine))
        _importCoordinator = StateObject(
            wrappedValue: TrackImportCoordinator(
                audioEngine: audioEngine,
                indexer: libraryIndexer
            )
        )
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(
                listeningHistory: nil, // NOTE: Wire up listening history when available
                libraryIndexer: libraryIndexer
            )
        )
        let playlistManager = PlaylistManager(indexer: libraryIndexer)
        _playlistSidebarViewModel = StateObject(
            wrappedValue: PlaylistSidebarViewModel(playlistManager: playlistManager)
        )
        _smartPlaylistViewModel = StateObject(
            wrappedValue: SmartPlaylistViewModel(libraryIndexer: libraryIndexer)
        )
        let deviceSyncManager = DeviceSyncComposer.makeDefaultManager()
        _deviceSidebarViewModel = StateObject(
            wrappedValue: DeviceSidebarViewModel(deviceSyncManager: deviceSyncManager)
        )
        _audioVisualiserViewModel = StateObject(
            wrappedValue: AudioVisualiserViewModel(
                nowPlayingViewModel: nil, // Will be set after initialization
                audioEngine: audioEngine as? AudioEngine
            )
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Collapsible Toolbar with Navigation Tabs
            CollapsibleToolbar(
                selectedTab: $selectedTab,
                isExpanded: $isToolbarExpanded
            )
            
            Divider()
            
            // Main Content Area (Sidebar + Content)
            mainContentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Collapsible Player Controls
            CollapsiblePlayerBar(
                nowPlayingViewModel: nowPlayingViewModel,
                isExpanded: $isPlayerExpanded,
                onMinimize: handleMinimize
            )
        }
        .frame(minWidth: 900, minHeight: 500)
        .task {
            await loadLayoutState()
        }
        .onChange(of: isToolbarExpanded) { _, _ in
            Task {
                await saveLayoutState()
            }
        }
        .onChange(of: isPlayerExpanded) { _, _ in
            Task {
                await saveLayoutState()
            }
        }
        .onAppear {
            setupMinimizeButtonInTitleBar()
        }
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
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        HStack(spacing: 0) {
            // Contextual Sidebar
            ContextualSidebar(
                selectedTab: $selectedTab,
                searchText: $searchText,
                onImportFiles: handleImportFiles,
                onOpenSettings: handleOpenSettings,
                onCreatePlaylist: handleCreatePlaylist,
                libraryBrowserViewModel: libraryBrowserViewModel,
                playlistSidebarViewModel: playlistSidebarViewModel,
                smartPlaylistViewModel: smartPlaylistViewModel,
                deviceSidebarViewModel: deviceSidebarViewModel,
                audioVisualiserViewModel: audioVisualiserViewModel
            )
            .onChange(of: searchText) { _, newValue in
                if selectedTab == .library {
                    Task {
                        await libraryBrowserViewModel.updateSearchText(newValue)
                    }
                } else if selectedTab == .playlists {
                    Task {
                        await playlistSidebarViewModel.updateSearchText(newValue)
                    }
                } else if selectedTab == .devices {
                    Task {
                        await deviceSidebarViewModel.updateSearchText(newValue)
                    }
                }
            }
            
            Divider()
            
            // Tab-specific Content
            tabContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Tab Content View
    
    @ViewBuilder
    private var tabContentView: some View {
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
    
    // MARK: - Actions
    
    private func handleMinimize() {
        if let appDelegate = AppDelegate.shared ?? (NSApplication.shared.delegate as? AppDelegate) {
            appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        }
    }
    
    private func handleImportFiles() {
        Task {
            let urls = AudioFileDialog.showOpenPanel(allowsMultipleSelection: true)
            if !urls.isEmpty {
                do {
                    try await importCoordinator.importFiles(urls: urls)
                } catch {
                    importError = error
                }
            }
        }
    }
    
    private func handleOpenSettings() {
        // Open macOS Settings window using standard menu action
        NSApplication.shared.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
    
    private func handleCreatePlaylist() {
        // NOTE: Playlist creation dialog will be implemented when playlist creation UI is ready
        // For now, this is a placeholder that logs the action
        Logger.userInterface.info("Create playlist action triggered")
    }

    // MARK: - Layout State Persistence
    
    private func loadLayoutState() async {
        let state = await layoutStateManager.loadLayoutState()
        isToolbarExpanded = state.isToolbarExpanded
        isPlayerExpanded = state.isPlayerExpanded
    }
    
    private func saveLayoutState() async {
        let state = LayoutState(
            isToolbarExpanded: isToolbarExpanded,
            isPlayerExpanded: isPlayerExpanded
        )
        
        do {
            try await layoutStateManager.saveLayoutState(state)
        } catch {
            Logger.userInterface.error("Failed to save layout state: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Minimize Button Setup
    
    private func setupMinimizeButtonInTitleBar() {
        let viewModel = nowPlayingViewModel
        
        DispatchQueue.main.async {
            var window: NSWindow?
            for attempt in 0..<5 {
                window = NSApplication.shared.windows.first(where: { $0.isMainWindow || $0.isKeyWindow })
                if window != nil { break }
                if attempt < 4 {
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            guard let window = window else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let retryWindow = NSApplication.shared.windows.first(where: { $0.isMainWindow || $0.isKeyWindow }) {
                        Self.setupMinimizeButton(in: retryWindow, viewModel: viewModel)
                    }
                }
                return
            }
            
            Self.setupMinimizeButton(in: window, viewModel: viewModel)
        }
    }
    
    private static func setupMinimizeButton(in window: NSWindow, viewModel: NowPlayingViewModel) {
        while !window.titlebarAccessoryViewControllers.isEmpty {
            window.removeTitlebarAccessoryViewController(at: 0)
        }
        
        let button = NSButton()
        if let image = NSImage(systemSymbolName: "minus.circle.fill", accessibilityDescription: nil) {
            button.image = image
        }
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.toolTip = "Minimize to Player"
        button.frame = NSRect(x: 0, y: 0, width: 20, height: 20)
        
        let target = MinimizeButtonTarget(viewModel: viewModel)
        button.target = target
        button.action = #selector(MinimizeButtonTarget.minimize)
        
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 80, height: 22))
        containerView.addSubview(button)
        button.frame.origin = NSPoint(x: 60, y: 1)
        
        objc_setAssociatedObject(containerView, "minimizeTarget", target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = containerView
        accessory.layoutAttribute = .leading
        
        window.addTitlebarAccessoryViewController(accessory)
    }
}
