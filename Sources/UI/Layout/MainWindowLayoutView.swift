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
import ObjectiveC
import os.log
import Shared
import SwiftUI

/// Main window layout with left navigation, toolbar, playlist panel, and player controls
@MainActor
public struct MainWindowLayoutView: View {
    @StateObject private var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var libraryBrowserViewModel = LibraryBrowserViewModel()
    // Use type inference - let Swift infer the type from the initial value
    @State private var selectedNavigationItem: NavigationItem = .home
    @State private var importError: Error?
    
    private let audioEngine: AudioEngineProtocol
    @StateObject private var importCoordinator: TrackImportCoordinator
    @Environment(\.dismissWindow) private var dismissWindow
    
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
        .onAppear {
            // Setup minimize button in title bar when view appears
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
            MainWindowToolbar(selectedNavigationItem: $selectedNavigationItem)
                .frame(height: 44)
                .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)
                .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content Area (Library Browser or other views)
            contentArea
                .frame(minWidth: 0, maxWidth: CGFloat.infinity, minHeight: 0, maxHeight: CGFloat.infinity)
                .clipped()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
    }
    
    // MARK: - Minimize Button Setup
    
    private func setupMinimizeButtonInTitleBar() {
        // Capture the viewModel to use in the closure
        let viewModel = nowPlayingViewModel
        
        // Try to add button to title bar using AppKit
        DispatchQueue.main.async {
            // Find the main window - try multiple times if needed
            var window: NSWindow?
            for attempt in 0..<5 {
                window = NSApplication.shared.windows.first(where: { $0.isMainWindow || $0.isKeyWindow })
                if window != nil { break }
                if attempt < 4 {
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            guard let window = window else {
                // Retry after a short delay if window not found
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // We need to call this from the view, but we can't capture self
                    // So we'll find the window and set it up directly
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
        // Remove any existing titlebar accessories
        while !window.titlebarAccessoryViewControllers.isEmpty {
            window.removeTitlebarAccessoryViewController(at: 0)
        }
        
        // Create button
        let button = NSButton()
        if let image = NSImage(systemSymbolName: "minus.circle.fill", accessibilityDescription: nil) {
            button.image = image
        }
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.toolTip = "Minimize to Player"
        button.frame = NSRect(x: 0, y: 0, width: 20, height: 20)
        
        // Create target and retain it - use a strong reference
        let target = MinimizeButtonTarget(viewModel: viewModel)
        button.target = target
        button.action = #selector(MinimizeButtonTarget.minimize)
        
        // Create container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 80, height: 22))
        containerView.addSubview(button)
        button.frame.origin = NSPoint(x: 60, y: 1) // Position to the right of traffic lights
        
        // Retain the target by storing it in the container view
        objc_setAssociatedObject(containerView, "minimizeTarget", target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Create titlebar accessory
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = containerView
        accessory.layoutAttribute = .leading
        
        window.addTitlebarAccessoryViewController(accessory)
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
                .frame(minWidth: 0, maxWidth: CGFloat.infinity, minHeight: 0, maxHeight: CGFloat.infinity)
                .clipped()
        case .music:
            LibraryBrowserView(viewModel: libraryBrowserViewModel)
                .frame(minWidth: 0, maxWidth: CGFloat.infinity, minHeight: 0, maxHeight: CGFloat.infinity)
                .clipped()
        case .playlists:
            PlaylistBrowserView(playlistManager: PlaylistManager(indexer: LibraryIndexer()))
                .frame(minWidth: 0, maxWidth: CGFloat.infinity, minHeight: 0, maxHeight: CGFloat.infinity)
                .clipped()
        case .devices:
            DeviceSyncView()
                .frame(minWidth: 0, maxWidth: CGFloat.infinity, minHeight: 0, maxHeight: CGFloat.infinity)
                .clipped()
        case .folders:
            LibraryBrowserView(viewModel: libraryBrowserViewModel)
                .frame(minWidth: 0, maxWidth: CGFloat.infinity, minHeight: 0, maxHeight: CGFloat.infinity)
                .clipped()
        case .web:
            Text("Web")
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
        case .pinned:
            Text("Pinned")
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
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
            .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)
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
            .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)
            .padding(30)
        }
    }
}

// Helper class to handle button action
private class MinimizeButtonTarget: NSObject {
    let viewModel: NowPlayingViewModel
    
    init(viewModel: NowPlayingViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    @objc func minimize() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Try multiple ways to get AppDelegate
            var appDelegate: AppDelegate?
            
            // Method 1: Try static shared property
            appDelegate = AppDelegate.shared
            
            // Method 2: Try NSApplication delegate
            if appDelegate == nil {
                appDelegate = NSApplication.shared.delegate as? AppDelegate
            }
            
            // Method 3: Try to get from the main window's delegate
            if appDelegate == nil, let window = NSApplication.shared.windows.first(where: { $0.isMainWindow || $0.isKeyWindow }) {
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
