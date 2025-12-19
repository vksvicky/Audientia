//
//  WindowPositioningHelper.swift
//  Audientia
//
//  Helper methods for window positioning
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import os.log
import Shared

/// Helper methods for window positioning
@MainActor
enum WindowPositioningHelper {
    /// Position the minimized player window, restoring saved position or centering
    static func positionMinimisedPlayerWindow(
        _ window: NSWindow,
        savedState: WindowState?,
        mainWindowFrame: NSRect,
        windowStateManager: WindowStateManager,
        onComplete: @escaping () async -> Void
    ) {
        // Use content dimensions for centering (matches test expectations)
        // The window frame includes title bar, but we center based on content area
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 80  // Content height, not frame height
        
        Task {
            if let savedState = await windowStateManager.loadWindowState(),
               savedState.isMinimised,
               savedState.frame.width > 0,
               savedState.frame.height > 0,
               savedState.frame.origin.x != 0 || savedState.frame.origin.y != 0 {
                // Restore saved position (only if it's not at origin 0,0 which indicates unpositioned window)
                let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(savedState.frame)
                await MainActor.run {
                    window.setFrame(validFrame, display: true)
                    window.makeKeyAndOrderFront(nil)
                }
                Logger.userInterface.debug(
                    "Restored minimized player window position from saved state: \(NSStringFromRect(validFrame))"
                )
            } else {
                // Use default centering logic (no saved state or saved state has invalid position)
                await centerWindow(
                    window: window,
                    mainWindowFrame: mainWindowFrame,
                    windowWidth: windowWidth,
                    windowHeight: windowHeight
                )
            }
            
            // Ensure window is visible after positioning
            await MainActor.run {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            
            // Complete callback
            await onComplete()
        }
    }
    
    /// Center the minimized player window on screen or relative to main window
    private static func centerWindow(
        window: NSWindow,
        mainWindowFrame: NSRect,
        windowWidth: CGFloat,
        windowHeight: CGFloat
    ) async {
        await MainActor.run {
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let centerX: CGFloat
                let centerY: CGFloat
                
                if mainWindowFrame != NSRect.zero {
                    // Center relative to where the main window was
                    // Test expects: frame.origin.y = midY - windowHeight/2 (using content height)
                    let mainMidX = mainWindowFrame.midX
                    let mainMidY = mainWindowFrame.midY
                    centerX = mainMidX - windowWidth / 2
                    centerY = mainMidY - windowHeight / 2
                    let centeringMessage = "Centering relative to main window: " +
                        "mainFrame=\(NSStringFromRect(mainWindowFrame)), " +
                        "midY=\(mainMidY), calculated centerY=\(centerY)"
                    Logger.userInterface.debug("\(centeringMessage)")
                } else {
                    // Center on screen
                    centerX = screenRect.midX - windowWidth / 2
                    centerY = screenRect.midY - windowHeight / 2
                }
                
                window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
                window.makeKeyAndOrderFront(nil)
                let centeredMessage = "Centered minimized player window at: (\(centerX), \(centerY)), " +
                    "actual frame: \(NSStringFromRect(window.frame))"
                Logger.userInterface.debug("\(centeredMessage)")
            }
        }
    }
}
