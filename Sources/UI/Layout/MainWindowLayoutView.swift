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
import os.log
@preconcurrency import Shared
import SwiftUI

/// Main window layout with:
/// - Collapsible toolbar with navigation tabs at top
/// - Contextual sidebar on the left
/// - Tab-specific content in the center
/// - Collapsible player controls at bottom
@MainActor
// swiftlint:disable:next type_body_length
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
    @StateObject private var keyboardNavigationManager = KeyboardNavigationManager()
    
    // MARK: - State
    
    @State private var selectedTab: TabItem = .home
    @State private var searchText: String = ""
    @State private var isToolbarExpanded: Bool = true
    @State private var isPlayerExpanded: Bool = true
    @State private var importError: Error?
    @State private var showingCreatePlaylistDialog: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var playlistCreationError: Error?
    @State private var showingCreateSmartPlaylistDialog: Bool = false
    @State private var isShiftPressed: Bool = false
    @State private var newSmartPlaylistName: String = ""
    @State private var smartPlaylistCreationError: Error?
    @StateObject private var smartPlaylistRuleBuilderViewModel = SmartPlaylistRuleBuilderViewModel()
    
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
        .onKeyPress(.tab) {
            // Handle Tab key navigation
            // Check if Shift modifier is currently pressed using NSEvent
            let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
            if isShiftPressed {
                // Shift+Tab: Move focus backward
                _ = keyboardNavigationManager.moveFocusBackward()
            } else {
                // Tab: Move focus forward
                _ = keyboardNavigationManager.moveFocusForward()
            }
            return .handled
        }
        .onKeyPress(.return) {
            // Handle Enter key activation
            handleEnterKeyActivation()
            return .handled
        }
        .onKeyPress(.space) {
            // Handle Space key activation (play/pause when player is focused)
            handleSpaceKeyActivation()
            return .handled
        }
        .task {
            await loadLayoutState()
        }
        .onChange(of: isToolbarExpanded) { oldValue, newValue in
            Logger.userInterface.debug("Toolbar expanded state changed: \(oldValue) -> \(newValue)")
            Task {
                await saveLayoutState()
            }
        }
        .onChange(of: isPlayerExpanded) { oldValue, newValue in
            Logger.userInterface.debug("Player expanded state changed: \(oldValue) -> \(newValue)")
            Task {
                await saveLayoutState()
            }
        }
        .onAppear {
            // Setup minimize button after a small delay to ensure window is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                setupMinimizeButtonInTitleBar()
            }
            // Restore minimized state if app was in minimized mode when it closed
            if let appDelegate = AppDelegate.shared ?? (NSApplication.shared.delegate as? AppDelegate) {
                Task {
                    await appDelegate.restoreMinimizedStateIfNeeded(nowPlayingViewModel: nowPlayingViewModel)
                }
            }
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
        .alert(LocalisationManager.shared[LocalisationManager.error], isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(LocalisationManager.shared[LocalisationManager.apply]) {
                importError = nil
            }
        } message: {
            if let error = importError {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $showingCreatePlaylistDialog) {
            CreatePlaylistDialog(
                isPresented: $showingCreatePlaylistDialog,
                playlistName: $newPlaylistName,
                error: $playlistCreationError,
                onCreate: createPlaylist
            )
        }
        .sheet(isPresented: $showingCreateSmartPlaylistDialog) {
            CreateSmartPlaylistDialog(
                isPresented: $showingCreateSmartPlaylistDialog,
                playlistName: $newSmartPlaylistName,
                error: $smartPlaylistCreationError,
                ruleBuilderViewModel: smartPlaylistRuleBuilderViewModel,
                onCreate: createSmartPlaylist
            )
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
                onCreateSmartPlaylist: handleCreateSmartPlaylist,
                libraryBrowserViewModel: libraryBrowserViewModel,
                playlistSidebarViewModel: playlistSidebarViewModel,
                smartPlaylistViewModel: smartPlaylistViewModel,
                deviceSidebarViewModel: deviceSidebarViewModel,
                audioVisualiserViewModel: audioVisualiserViewModel
            )
            .frame(width: ContextualSidebar.width)
            .fixedSize(horizontal: true, vertical: false)
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
            .onChange(of: selectedTab) { oldValue, newValue in
                let tabChangeMessage = "MainWindowLayoutView: Tab changed from \(oldValue.rawValue) " +
                    "to \(newValue.rawValue)"
                Logger.userInterface.info("\(tabChangeMessage)")
            }
            .onAppear {
                Logger.userInterface.info("MainWindowLayoutView: Appeared with selectedTab = \(selectedTab.rawValue)")
            }
            
            Divider()
            
            // Tab-specific Content
            MainWindowTabContentView(
                selectedTab: selectedTab,
                homeViewModel: homeViewModel,
                libraryBrowserViewModel: libraryBrowserViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                audioEngine: audioEngine,
                audioVisualiserViewModel: audioVisualiserViewModel
            )
            .id("tab-\(selectedTab.rawValue)") // Force view recreation when tab changes
            .animation(.default, value: selectedTab) // Animate tab changes
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .layoutPriority(1) // Give content area priority for space
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        newPlaylistName = ""
        playlistCreationError = nil
        showingCreatePlaylistDialog = true
    }
    
    private func handleCreateSmartPlaylist() {
        newSmartPlaylistName = ""
        smartPlaylistCreationError = nil
        smartPlaylistRuleBuilderViewModel.clearRules()
        showingCreateSmartPlaylistDialog = true
    }
    
    // MARK: - Create Playlist Dialog
    
    private func createPlaylist() {
        let name = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        Task {
            do {
                try await playlistSidebarViewModel.createPlaylist(name: name)
                showingCreatePlaylistDialog = false
                newPlaylistName = ""
                playlistCreationError = nil
            } catch {
                playlistCreationError = error
                Logger.userInterface.error("Failed to create playlist: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Create Smart Playlist Dialog
    
    private func createSmartPlaylist() {
        let name = newSmartPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard smartPlaylistRuleBuilderViewModel.isValid else { return }
        
        Task {
            do {
                let rules = smartPlaylistRuleBuilderViewModel.buildRules()
                try await playlistSidebarViewModel.createSmartPlaylist(name: name, rules: rules)
                
                showingCreateSmartPlaylistDialog = false
                newSmartPlaylistName = ""
                smartPlaylistCreationError = nil
                smartPlaylistRuleBuilderViewModel.clearRules()
                
                Logger.userInterface.info("Created smart playlist: \(name)")
            } catch {
                smartPlaylistCreationError = error
                Logger.userInterface.error("Failed to create smart playlist: \(error.localizedDescription)")
                }
            }
        }

    // MARK: - Keyboard Navigation Handlers
    
    /// Handle Enter key activation based on current focus
    private func handleEnterKeyActivation() {
        guard let currentFocus = keyboardNavigationManager.currentFocus else {
            return
        }
        
        switch currentFocus {
        case .toolbarTab(let tab):
            selectedTab = tab
        case .sidebarAction(let action):
            switch action {
            case "importFiles":
                handleImportFiles()
            case "settings":
                handleOpenSettings()
            case "createPlaylist":
                handleCreatePlaylist()
            default:
                break
            }
        case .playerPlayPause:
            Task {
                if nowPlayingViewModel.isPlaying {
                    await nowPlayingViewModel.pause()
                } else {
                    try? await nowPlayingViewModel.play()
                }
            }
        default:
            // For other elements, Enter key behavior is handled by SwiftUI
            break
        }
    }
    
    /// Handle Space key activation (primarily for play/pause)
    private func handleSpaceKeyActivation() {
        guard let currentFocus = keyboardNavigationManager.currentFocus else {
            // If no specific focus, toggle play/pause
            Task {
                if nowPlayingViewModel.isPlaying {
                    await nowPlayingViewModel.pause()
                } else {
                    try? await nowPlayingViewModel.play()
                }
            }
            return
        }
        
        // Space key activates play/pause when player controls are focused
        if case .playerPlayPause = currentFocus {
            Task {
                if nowPlayingViewModel.isPlaying {
                    await nowPlayingViewModel.pause()
                } else {
                    try? await nowPlayingViewModel.play()
                }
            }
        }
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
        TitleBarMinimizeButton.setupAsync(viewModel: nowPlayingViewModel)
    }
}
