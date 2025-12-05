//
//  TitleBarMaximizeButton.swift
//  Audientia
//
//  Helper for setting up maximize/restore button in title bar of minimized player window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import ObjectiveC

/// Custom button subclass to handle hover (like macOS traffic lights)
private class MaximizeHoverButton: NSButton {
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
        let buttonSize = bounds.size
        guard !buttonSize.width.isZero && !buttonSize.height.isZero else { return }
        
        let resizedImage = hoverImage.copy() as? NSImage ?? hoverImage
        resizedImage.size = buttonSize
        resizedImage.isTemplate = false
        image = resizedImage
        
        if #available(macOS 10.14, *) {
            contentTintColor = nil
        }
        
        alphaValue = 1.0
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard let defaultImage = defaultImage else { return }
        let buttonSize = bounds.size
        guard !buttonSize.width.isZero && !buttonSize.height.isZero else { return }
        
        let resizedImage = defaultImage.copy() as? NSImage ?? defaultImage
        resizedImage.size = buttonSize
        resizedImage.isTemplate = false
        image = resizedImage
        
        if #available(macOS 10.14, *) {
            contentTintColor = nil
        }
        
        alphaValue = 1.0
        needsDisplay = true
    }
}

/// Target class for maximize button in title bar
private class MaximizeButtonTarget: NSObject {
    let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
    }
    
    @objc func maximize() {
        DispatchQueue.main.async { [weak self] in
            self?.action()
        }
    }
}

/// Helper for setting up maximize/restore button in title bar
enum TitleBarMaximizeButton {
    static func setup(in window: NSWindow, action: @escaping () -> Void) {
        while !window.titlebarAccessoryViewControllers.isEmpty {
            window.removeTitlebarAccessoryViewController(at: 0)
        }
        
        // Get the standard window buttons to align vertically with them
        let closeButton = window.standardWindowButton(.closeButton)
        let trafficLightFrame = closeButton?.frame ?? NSRect(x: 12, y: 3, width: 12, height: 12)
        let trafficLightY = trafficLightFrame.origin.y
        let trafficLightHeight = trafficLightFrame.height
        
        // Create hover-aware button with custom icon
        let button = MaximizeHoverButton()
        
        // Match traffic light button size and vertical position
        let buttonSize: CGFloat = trafficLightHeight
        let buttonY = trafficLightY // Align vertically with traffic lights
        
        // Load default icon (MaximiseIcon)
        let defaultIcon = NSImage(named: "MaximiseIcon")
        // Load hover icon (MaximiseIconHover)
        let hoverIcon = NSImage(named: "MaximiseIconHover")
        
        if let defaultImage = defaultIcon {
            button.defaultImage = defaultImage
            // Store hover image directly
            if let hover = hoverIcon {
                button.hoverImage = hover
            } else {
                button.hoverImage = defaultImage
            }
            
            // Set default image initially - no template, no tinting, use image as-is
            let resizedDefault = defaultImage.copy() as? NSImage ?? defaultImage
            resizedDefault.size = NSSize(width: buttonSize, height: buttonSize)
            resizedDefault.isTemplate = false
            button.image = resizedDefault
            
            // No tinting - use image colors as-is
            if #available(macOS 10.14, *) {
                button.contentTintColor = nil
            }
        } else {
            // Fallback: use system symbol if custom icon not found
            if let systemImage = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: nil) {
                button.defaultImage = systemImage
                button.hoverImage = systemImage
                systemImage.isTemplate = false
                systemImage.size = NSSize(width: buttonSize, height: buttonSize)
                button.image = systemImage
            }
        }
        
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyUpOrDown
        button.toolTip = "Restore"
        button.wantsLayer = false
        
        button.frame = NSRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        
        // Create circular container view to match traffic lights style
        let circularContainer = NSView(frame: NSRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        circularContainer.wantsLayer = true
        circularContainer.layer?.cornerRadius = buttonSize / 2
        circularContainer.layer?.masksToBounds = true
        
        // Add button to circular container
        button.frame = NSRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        circularContainer.addSubview(button)
        
        let target = MaximizeButtonTarget(action: action)
        button.target = target
        button.action = #selector(MaximizeButtonTarget.maximize)
        button.isEnabled = true
        
        // Container view - with .leading layout, this starts right after traffic lights
        // Position button at x: 0 (right after traffic lights) and align vertically
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 30, height: 22))
        containerView.addSubview(circularContainer)
        circularContainer.frame.origin = NSPoint(x: 0, y: buttonY)
        
        objc_setAssociatedObject(containerView, "maximizeTarget", target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = containerView
        accessory.layoutAttribute = .leading
        
        window.addTitlebarAccessoryViewController(accessory)
        
        // Setup tracking after the view is in the window hierarchy and laid out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            button.updateTrackingAreas()
        }
    }
}
