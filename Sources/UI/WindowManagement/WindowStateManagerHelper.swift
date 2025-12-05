//
//  WindowStateManagerHelper.swift
//  Audientia
//
//  Helper methods for window state management
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import Shared

/// Helper methods for window state management
@MainActor
enum WindowStateManagerHelper {
    /// Determine the current window frame and minimized state
    static func getCurrentWindowState(
        minimisedPlayerWindow: NSWindow?,
        isMinimised: Bool,
        mainWindow: NSWindow?
    ) -> (frame: CGRect, isMinimised: Bool)? {
        // Check for minimized player window first (even if isMinimised flag is false,
        // the window might still exist when app is terminating)
        if let playerWindow = minimisedPlayerWindow {
            // If minimized player window exists, save its frame (even if not visible)
            return (playerWindow.frame, true)
        } else if isMinimised {
            // Fallback: if isMinimised flag is true but window is nil, we're in minimized mode
            // Use a default frame for minimized player
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let frame = CGRect(
                    x: screenRect.midX - 200,
                    y: screenRect.midY - 40,
                    width: 400,
                    height: 80
                )
                return (frame, true)
            } else {
                return (CGRect(x: 100, y: 100, width: 400, height: 80), true)
            }
        } else if let mainWindow = mainWindow {
            // Otherwise, save the main window frame
            return (mainWindow.frame, false)
        } else {
            // No window available, don't save
            return nil
        }
    }
    
    /// Ensure the frame is on a valid screen
    static func ensureFrameOnScreen(_ frame: CGRect) -> CGRect {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return frame
        }
        
        // Check if frame is on any screen
        let isOnScreen = screens.contains { screen in
            screen.frame.intersects(frame)
        }
        
        if isOnScreen {
            return frame
        }
        
        // Frame is off-screen, center on main screen
        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.visibleFrame
            let centerX = screenRect.midX - frame.width / 2
            let centerY = screenRect.midY - frame.height / 2
            return CGRect(
                x: centerX,
                y: centerY,
                width: frame.width,
                height: frame.height
            )
        }
        
        return frame
    }
}
