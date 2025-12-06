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
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 80
        
        Task {
            if let savedState = await windowStateManager.loadWindowState(),
               savedState.isMinimised,
               savedState.frame.width > 0,
               savedState.frame.height > 0 {
                // Restore saved position
                let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(savedState.frame)
                await MainActor.run {
                    window.setFrame(validFrame, display: false)
                }
                Logger.userInterface.debug(
                    "Restored minimized player window position from saved state: \(NSStringFromRect(validFrame))"
                )
            } else {
                // Use default centering logic
                await MainActor.run {
                    if let screen = NSScreen.main {
                        let screenRect = screen.visibleFrame
                        let centerX: CGFloat
                        let centerY: CGFloat
                        
                        if mainWindowFrame != NSRect.zero {
                            // Center relative to where the main window was
                            centerX = mainWindowFrame.midX - windowWidth / 2
                            centerY = mainWindowFrame.midY - windowHeight / 2
                        } else {
                            // Center on screen
                            centerX = screenRect.midX - windowWidth / 2
                            centerY = screenRect.midY - windowHeight / 2
                        }
                        
                        window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
                    }
                }
            }
            
            // Complete callback
            await onComplete()
        }
    }
}
