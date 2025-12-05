//
//  MinimisedPlayerWindowDelegate.swift
//  Audientia
//
//  Window delegate for minimized player window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import os.log
import Shared

/// Window delegate for minimized player window to handle close button
class MinimisedPlayerWindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Save state before closing (window still exists here)
        // Use a semaphore to ensure the save completes
        if let appDelegate = AppDelegate.shared ?? (NSApplication.shared.delegate as? AppDelegate) {
            Logger.userInterface.info("windowShouldClose: Saving window state before closing")
            let semaphore = DispatchSemaphore(value: 0)
            var saveCompleted = false
            
            // Run the save task
            Task { @MainActor in
                Logger.userInterface.info("windowShouldClose: Starting saveWindowStateImmediate")
                await appDelegate.saveWindowStateImmediate()
                Logger.userInterface.info("windowShouldClose: saveWindowStateImmediate completed")
                saveCompleted = true
                semaphore.signal()
            }
            
            // Wait up to 2 seconds for the save to complete, processing events to allow Task to run
            var waitCount = 0
            while semaphore.wait(timeout: .now() + 0.1) == .timedOut && waitCount < 20 {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
                waitCount += 1
            }
            
            if waitCount >= 20 {
                Logger.userInterface.error("windowShouldClose: Save timed out after 2 seconds")
            } else {
                Logger.userInterface.info(
                    "windowShouldClose: Save completed successfully, saveCompleted=\(saveCompleted)"
                )
            }
        }
        onClose()
        return true  // Allow window to close after cleanup
    }
}
