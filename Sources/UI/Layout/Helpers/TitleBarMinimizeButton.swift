//
//  TitleBarMinimizeButton.swift
//  Audientia
//
//  Helper for setting up minimize button in title bar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import ObjectiveC
import Shared
import SwiftUI

/// Helper for setting up minimize button in title bar
enum TitleBarMinimizeButton {
    static func setup(in window: NSWindow, viewModel: NowPlayingViewModel) {
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
    
    static func setupAsync(viewModel: NowPlayingViewModel) {
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
                        Self.setup(in: retryWindow, viewModel: viewModel)
                    }
                }
                return
            }
            
            Self.setup(in: window, viewModel: viewModel)
        }
    }
}
