//
//  AudientiaApp_WindowState.swift
//  Audientia
//
//  Window state management extension for AppDelegate
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import AppKit
import CoreGraphics
import Foundation
import os.log
import Shared

// MARK: - Window State Persistence Extension
extension AppDelegate {
    /// Save window state immediately (public for window delegate)
    @MainActor
    func saveWindowStateImmediate() async {
        await saveWindowState()
    }
    
    /// Save current window state (position and minimized mode)
    @MainActor
    func saveWindowState() async {
        let windowExists = self.minimisedPlayerWindow != nil
        Logger.userInterface.info(
            "saveWindowState: Starting, isMinimised=\(self.isMinimised), minimisedPlayerWindow exists=\(windowExists)"
        )
        
        guard let (frame, isMinimisedState) = WindowStateManagerHelper.getCurrentWindowState(
            minimisedPlayerWindow: minimisedPlayerWindow,
            isMinimised: isMinimised,
            mainWindow: mainWindow
        ) else {
            Logger.userInterface.warning("No window available to save state")
            return
        }
        
        let windowState = WindowState(
            frame: frame,
            isMaximized: false, // We don't track maximized state separately
            isMinimised: isMinimisedState
        )
        
        do {
            try await windowStateManager.saveWindowState(windowState)
            Logger.userInterface.info(
                "Window state saved successfully: frame=\(NSStringFromRect(frame)), isMinimised=\(isMinimisedState)"
            )
        } catch {
            Logger.userInterface.error("Failed to save window state: \(error.localizedDescription)")
        }
    }
    
    /// Restore window state (position and minimized mode)
    @MainActor
    func restoreWindowState() async {
        Logger.userInterface.info("restoreWindowState: Attempting to load saved window state")
        let savedState = await windowStateManager.loadWindowState()
        
        guard let savedState = savedState else {
            handleNoSavedState()
            return
        }
        
        let frame = savedState.frame
        let wasMinimised = savedState.isMinimised
        
        Logger.userInterface.info(
            "Restoring window state: frame=\(NSStringFromRect(frame)), wasMinimised=\(wasMinimised)"
        )
        
        if !wasMinimised {
            restoreMainWindowPosition(frame: frame)
        } else {
            handleMinimizedStateRestoration()
        }
        
        // Store flag to restore minimized state after view model is available
        if wasMinimised {
            self.shouldRestoreMinimizedState = true
            Logger.userInterface.info(
                "App was in minimized player mode, will restore after view model is available"
            )
        }
    }
    
    /// Handle case when no saved state exists
    @MainActor
    private func handleNoSavedState() {
        Logger.userInterface.info("No saved window state found, using defaults")
        if let mainWindow = mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            Logger.userInterface.info("Making main window visible (no saved state)")
        }
    }
    
    /// Restore main window position
    @MainActor
    private func restoreMainWindowPosition(frame: CGRect) {
        guard let mainWindow = mainWindow else { return }
        
        // Only restore if the frame is significantly different (more than 10 pixels)
        let currentFrame = mainWindow.frame
        let frameDifference = abs(currentFrame.origin.x - frame.origin.x) +
                             abs(currentFrame.origin.y - frame.origin.y) +
                             abs(currentFrame.width - frame.width) +
                             abs(currentFrame.height - frame.height)
        
        if frameDifference > 10 {
            let validFrame = WindowStateManagerHelper.ensureFrameOnScreen(frame)
            mainWindow.setFrame(validFrame, display: true)
            mainWindow.makeKeyAndOrderFront(nil)
            Logger.userInterface.info("Restored window position: \(NSStringFromRect(validFrame))")
        } else {
            mainWindow.makeKeyAndOrderFront(nil)
            Logger.userInterface.info("Window position already correct, skipping restoration")
        }
    }
    
    /// Handle minimized state restoration
    @MainActor
    private func handleMinimizedStateRestoration() {
        Logger.userInterface.info("App was in minimized player mode, will attempt to restore")
        
        // Don't hide the window - let restoreMinimizedStateIfNeeded handle it
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if self.minimisedPlayerWindow != nil && self.minimisedPlayerWindow?.isVisible == true {
                self.mainWindow?.orderOut(nil)
                Logger.userInterface.info("Minimized player window created, hiding main window")
            } else {
                self.mainWindow?.makeKeyAndOrderFront(nil)
                Logger.userInterface.warning(
                    "Minimized player window not created, keeping main window visible"
                )
            }
        }
    }
    
    /// Restore minimized state if needed (called when view model is available)
    @MainActor
    func restoreMinimizedStateIfNeeded(nowPlayingViewModel: NowPlayingViewModel) async {
        Logger.userInterface.info(
            "restoreMinimizedStateIfNeeded called, shouldRestoreMinimizedState=\(self.shouldRestoreMinimizedState)"
        )
        
        // Check both the flag and the saved state directly (in case of timing issues)
        var shouldRestore = self.shouldRestoreMinimizedState
        
        // If flag is not set, check saved state directly
        if !shouldRestore {
            if let savedState = await self.windowStateManager.loadWindowState(), savedState.isMinimised {
                Logger.userInterface.info("Found saved minimized state, will restore")
                shouldRestore = true
            }
        }
        
        guard shouldRestore else {
            Logger.userInterface.info("No need to restore minimized state")
            return
        }
        
        self.shouldRestoreMinimizedState = false
        
        // Restore minimized player mode (position will be restored in minimizeToPlayer)
        Logger.userInterface.info("Restoring minimized player state on app launch")
        self.minimizeToPlayer(nowPlayingViewModel: nowPlayingViewModel)
        Logger.userInterface.info("Restored minimized player state on app launch")
        
        // Verify minimized player window was created, if not show main window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if self.minimisedPlayerWindow == nil || self.minimisedPlayerWindow?.isVisible == false {
                self.mainWindow?.makeKeyAndOrderFront(nil)
                Logger.userInterface.warning(
                    "Minimized player window not created after restore, forcing main window visible"
                )
            }
        }
    }
}
