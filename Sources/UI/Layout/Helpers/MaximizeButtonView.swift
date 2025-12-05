//
//  MaximizeButtonView.swift
//  Audientia
//
//  Maximize/restore button with hover for minimized player view
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import SwiftUI

/// Custom button subclass to handle hover
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

/// SwiftUI wrapper for maximize button with hover
struct MaximizeButtonView: NSViewRepresentable {
    let action: () -> Void
    let size: CGFloat
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        
        // Load icons
        let defaultIcon = NSImage(named: "MaximiseIcon")
        let hoverIcon = NSImage(named: "MaximiseIconHover")
        
        let button = MaximizeHoverButton()
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyUpOrDown
        button.toolTip = "Restore"
        button.isEnabled = true
        button.target = context.coordinator
        button.action = #selector(Coordinator.buttonClicked)
        
        if let defaultImage = defaultIcon {
            button.defaultImage = defaultImage
            button.hoverImage = hoverIcon ?? defaultImage
            
            // Set default image
            let resizedDefault = defaultImage.copy() as? NSImage ?? defaultImage
            resizedDefault.size = NSSize(width: size, height: size)
            resizedDefault.isTemplate = false
            button.image = resizedDefault
            
            if #available(macOS 10.14, *) {
                button.contentTintColor = nil
            }
        } else {
            // Fallback to system icon
            if let systemImage = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: nil) {
                button.defaultImage = systemImage
                button.hoverImage = systemImage
                systemImage.isTemplate = false
                systemImage.size = NSSize(width: size, height: size)
                button.image = systemImage
            }
        }
        
        button.frame = NSRect(x: 0, y: 0, width: size, height: size)
        containerView.addSubview(button)
        
        context.coordinator.button = button
        context.coordinator.action = action
        
        // Setup tracking after view is added
        DispatchQueue.main.async {
            button.updateTrackingAreas()
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var button: NSButton?
        var action: (() -> Void)?
        
        @objc func buttonClicked() {
            action?()
        }
    }
}
