//
//  MinimisedPlayerWindowFactory.swift
//  Audientia
//
//  Factory for creating minimized player windows
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Shared
import SwiftUI

/// Factory for creating minimized player windows
@MainActor
enum MinimisedPlayerWindowFactory {
    /// Create a minimized player window
    static func createWindow(
        nowPlayingViewModel: NowPlayingViewModel,
        onRestore: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) -> (window: NSWindow, delegate: NSWindowDelegate) {
        // Create minimised player window
        let playerWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        playerWindow.title = "Audientia Player"
        playerWindow.level = .floating
        playerWindow.isMovableByWindowBackground = true
        playerWindow.backgroundColor = NSColor.controlBackgroundColor
        playerWindow.hasShadow = true
        playerWindow.isReleasedWhenClosed = false
        playerWindow.isOpaque = true
        
        // Hide minimize and maximize buttons, keep only close button
        if let minimizeButton = playerWindow.standardWindowButton(.miniaturizeButton) {
            minimizeButton.isHidden = true
        }
        if let zoomButton = playerWindow.standardWindowButton(.zoomButton) {
            zoomButton.isHidden = true
        }
        
        // Create minimised player view
        let playerView = MinimisedPlayerView(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: onRestore
        )
        let hostingView = NSHostingView(rootView: playerView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 80)
        
        playerWindow.contentView = hostingView
        
        // Set window delegate to handle close button (traffic light)
        let windowDelegate = MinimisedPlayerWindowDelegate(onClose: onClose)
        playerWindow.delegate = windowDelegate
        
        // Setup maximize/restore button in title bar (aligned with traffic lights)
        TitleBarMaximizeButton.setup(in: playerWindow) {
            onRestore()
        }
        
        return (playerWindow, windowDelegate)
    }
}
