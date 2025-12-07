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

/// Custom button subclass to handle hover (like macOS traffic lights)
private class HoverButton: NSButton {
    var accentColor: NSColor?
    var defaultColor: NSColor?
    var defaultImage: NSImage?
    var hoverImage: NSImage?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            DispatchQueue.main.async {
                self.updateTrackingAreas()
            }
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        guard !bounds.isEmpty else { return }
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard let hoverImage = hoverImage, hoverImage !== defaultImage else { return }
        // Use the hover image directly, just resize it - no template, no tinting
        let buttonSize = bounds.size
        guard !buttonSize.width.isZero && !buttonSize.height.isZero else { return }
        
        let resizedImage = hoverImage.copy() as? NSImage ?? hoverImage
        resizedImage.size = buttonSize
        resizedImage.isTemplate = false  // Don't use template - use image as-is
        image = resizedImage
        
        // Remove any tinting
        if #available(macOS 10.14, *) {
            contentTintColor = nil
        }
        
        alphaValue = 1.0
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard let defaultImage = defaultImage else { return }
        // Use the default image directly, just resize it - no template, no tinting
        let buttonSize = bounds.size
        guard !buttonSize.width.isZero && !buttonSize.height.isZero else { return }
        
        let resizedImage = defaultImage.copy() as? NSImage ?? defaultImage
        resizedImage.size = buttonSize
        resizedImage.isTemplate = false  // Don't use template - use image as-is
        image = resizedImage
        
        // Remove any tinting
        if #available(macOS 10.14, *) {
            contentTintColor = nil
        }
        
        alphaValue = 1.0
        needsDisplay = true
    }
}

/// Helper for setting up minimize button in title bar
enum TitleBarMinimizeButton {
    static func setup(in window: NSWindow, viewModel: NowPlayingViewModel) {
        removeExistingMinimizeButtons(from: window)
        
        let (buttonSize, buttonY) = getTrafficLightDimensions(from: window)
        let button = createMinimizeButton(size: buttonSize)
        setupButtonImages(for: button, size: buttonSize)
        let (containerView, target) = createButtonContainer(
            button: button,
            size: buttonSize,
            yPosition: buttonY,
            viewModel: viewModel
        )
        
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = containerView
        accessory.layoutAttribute = .leading
        window.addTitlebarAccessoryViewController(accessory)
        
        // Setup tracking after the view is in the window hierarchy and laid out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            button.updateTrackingAreas()
        }
    }
    
    private static func removeExistingMinimizeButtons(from window: NSWindow) {
        var indicesToRemove: [Int] = []
        for (index, accessory) in window.titlebarAccessoryViewControllers.enumerated() {
            let view = accessory.view
            let target = objc_getAssociatedObject(view, "minimizeTarget")
            if target != nil {
                indicesToRemove.append(index)
            }
        }
        for index in indicesToRemove.reversed() {
            window.removeTitlebarAccessoryViewController(at: index)
        }
    }
    
    private static func getTrafficLightDimensions(from window: NSWindow) -> (size: CGFloat, y: CGFloat) {
        let closeButton = window.standardWindowButton(.closeButton)
        let trafficLightFrame = closeButton?.frame ?? NSRect(x: 12, y: 3, width: 12, height: 12)
        let trafficLightY = trafficLightFrame.origin.y
        let trafficLightHeight = trafficLightFrame.height
        return (trafficLightHeight, trafficLightY)
    }
    
    private static func createMinimizeButton(size: CGFloat) -> HoverButton {
        let accentColor = NSColor(red: 0.357, green: 0.553, blue: 0.933, alpha: 1.0)
        let button = HoverButton()
        button.accentColor = accentColor
        button.defaultColor = accentColor
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyUpOrDown
        button.toolTip = "Minimise to Player"
        button.wantsLayer = false
        button.frame = NSRect(x: 0, y: 0, width: size, height: size)
        return button
    }
    
    private static func setupButtonImages(for button: HoverButton, size: CGFloat) {
        let defaultIcon = NSImage(named: "MinimizeIcon")
        let hoverIcon = NSImage(named: "MinimizeIconHover")
        
        if let defaultImage = defaultIcon {
            button.defaultImage = defaultImage
            button.hoverImage = hoverIcon ?? defaultImage
            
            let resizedDefault = defaultImage.copy() as? NSImage ?? defaultImage
            resizedDefault.size = NSSize(width: size, height: size)
            resizedDefault.isTemplate = false
            button.image = resizedDefault
            
            if #available(macOS 10.14, *) {
                button.contentTintColor = nil
            }
        } else {
            if let systemImage = NSImage(
                systemSymbolName: "arrow.down.right.and.arrow.up.left",
                accessibilityDescription: nil
            ) {
                button.defaultImage = systemImage
                button.hoverImage = systemImage
                systemImage.isTemplate = true
                systemImage.size = NSSize(width: size, height: size)
                button.image = systemImage
                if #available(macOS 10.14, *) {
                    button.contentTintColor = button.defaultColor
                }
            }
        }
    }
    
    private static func createButtonContainer(
        button: HoverButton,
        size: CGFloat,
        yPosition: CGFloat,
        viewModel: NowPlayingViewModel
    ) -> (containerView: NSView, target: MinimizeButtonTarget) {
        let circularContainer = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        circularContainer.wantsLayer = true
        circularContainer.layer?.cornerRadius = size / 2
        circularContainer.layer?.masksToBounds = true
        circularContainer.addSubview(button)
        
        let target = MinimizeButtonTarget(viewModel: viewModel)
        button.target = target
        button.action = #selector(MinimizeButtonTarget.minimize)
        button.isEnabled = true
        
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 30, height: 22))
        containerView.addSubview(circularContainer)
        circularContainer.frame.origin = NSPoint(x: 0, y: yPosition)
        
        objc_setAssociatedObject(
            containerView,
            "minimizeTarget",
            target,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        return (containerView, target)
    }
    
    static func setupAsync(viewModel: NowPlayingViewModel) {
        DispatchQueue.main.async {
            var window: NSWindow?
            for attempt in 0..<10 {
                window = NSApplication.shared.windows.first(where: {
                    ($0.isMainWindow || $0.isKeyWindow) &&
                    $0.titlebarAccessoryViewControllers.isEmpty == false ||
                    $0.standardWindowButton(.closeButton) != nil
                })
                if window != nil { break }
                if attempt < 9 {
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            guard let window = window else {
                // Retry after a longer delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let retryWindow = NSApplication.shared.windows.first(
                        where: { $0.isMainWindow || $0.isKeyWindow }
                    ) {
                        Self.setup(in: retryWindow, viewModel: viewModel)
                    } else {
                        // Final retry
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if let finalWindow = NSApplication.shared.windows.first(
                                where: { $0.isMainWindow || $0.isKeyWindow }
                            ) {
                                Self.setup(in: finalWindow, viewModel: viewModel)
                            }
                        }
                    }
                }
                return
            }
            
            Self.setup(in: window, viewModel: viewModel)
        }
    }
}
