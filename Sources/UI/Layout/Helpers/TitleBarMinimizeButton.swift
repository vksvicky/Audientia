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
        
        // Get the standard window buttons to align vertically with them
        let closeButton = window.standardWindowButton(.closeButton)
        let trafficLightFrame = closeButton?.frame ?? NSRect(x: 12, y: 3, width: 12, height: 12)
        let trafficLightY = trafficLightFrame.origin.y
        let trafficLightHeight = trafficLightFrame.height
        
        let button = NSButton()
        if let image = NSImage(systemSymbolName: "minus.circle.fill", accessibilityDescription: nil) {
            button.image = image
        }
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.toolTip = "Minimize to Player"
        
        // Match traffic light button size and vertical position
        let buttonSize: CGFloat = trafficLightHeight
        let buttonY = trafficLightY // Align vertically with traffic lights
        
        button.frame = NSRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        
        let target = MinimizeButtonTarget(viewModel: viewModel)
        button.target = target
        button.action = #selector(MinimizeButtonTarget.minimize)
        
        // Container view - with .leading layout, this starts right after traffic lights
        // Position button at x: 0 (right after traffic lights) and align vertically
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 30, height: 22))
        containerView.addSubview(button)
        button.frame.origin = NSPoint(x: 0, y: buttonY)
        
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
                    if let retryWindow = NSApplication.shared.windows.first(
                        where: { $0.isMainWindow || $0.isKeyWindow }
                    ) {
                        Self.setup(in: retryWindow, viewModel: viewModel)
                    }
                }
                return
            }
            
            Self.setup(in: window, viewModel: viewModel)
        }
    }
}
