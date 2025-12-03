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
import Shared
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
    
    // MARK: - State
    
    @State private var selectedTab: TabItem = .home
    @State private var searchText: String = ""
    @State private var isToolbarExpanded: Bool = true
    @State private var isPlayerExpanded: Bool = true
    @State private var importError: Error?
    
    // MARK: - Dependencies
    
    private let audioEngine: AudioEngineProtocol
    @Environment(\.dismissWindow) private var dismissWindow
    
    // MARK: - Initialization
    
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
                searchText: $searchText
            )
            
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
            HomeContentView()
        case .library:
            LibraryBrowserView(viewModel: libraryBrowserViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .playlists:
            PlaylistBrowserView(playlistManager: PlaylistManager(indexer: LibraryIndexer()))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .devices:
            DeviceSyncView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .visualiser:
            AudioVisualiserView(
                nowPlayingViewModel: nowPlayingViewModel,
                audioEngine: audioEngine as? AudioEngine
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Actions
    
    private func handleMinimize() {
        if let appDelegate = AppDelegate.shared ?? (NSApplication.shared.delegate as? AppDelegate) {
            appDelegate.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
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

// MARK: - Home Content View

private struct HomeContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Audientia")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Your powerful media library manager")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Recently Played Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENTLY PLAYED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(0..<4) { _ in
                            AlbumPlaceholderView()
                        }
                        Spacer()
                    }
                }
                
                // Recently Added Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENTLY ADDED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(0..<4) { _ in
                            AlbumPlaceholderView()
                        }
                        Spacer()
                    }
                }
                
                // Quick Links
                VStack(alignment: .leading, spacing: 12) {
                    Text("GET STARTED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let url = URL(string: "https://github.com/vksvicky/Audientia") {
                            Link(">> What's New?", destination: url)
                            Link(">> Introduction", destination: url)
                            Link(">> Add files to the library", destination: url)
                            Link(">> Play files", destination: url)
                            Link(">> Update/Edit your files", destination: url)
                            Link(">> Sync your files", destination: url)
                        }
                    }
                    .font(.system(size: 13))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(30)
        }
    }
}

// MARK: - Album Placeholder View

private struct AlbumPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                )
            
            Text("Album")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}

// MARK: - Minimize Button Target

private class MinimizeButtonTarget: NSObject {
    let viewModel: NowPlayingViewModel
    
    init(viewModel: NowPlayingViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    @objc func minimize() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var appDelegate: AppDelegate?
            appDelegate = AppDelegate.shared
            
            if appDelegate == nil {
                appDelegate = NSApplication.shared.delegate as? AppDelegate
            }
            
            if appDelegate == nil,
               let window = NSApplication.shared.windows.first(where: { $0.isMainWindow || $0.isKeyWindow }) {
                appDelegate = window.delegate as? AppDelegate
            }
            
            guard let appDelegate = appDelegate else {
                Logger.userInterface.error("Failed to get AppDelegate - delegate: \(String(describing: NSApplication.shared.delegate))")
                return
            }
            
            appDelegate.minimizeToPlayer(nowPlayingViewModel: self.viewModel)
        }
    }
}
