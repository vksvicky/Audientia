//
//  AppDelegate+WindowSetup.swift
//  Audientia
//
//  Window setup and menu configuration extension for AppDelegate
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import os.log
import Shared
import SwiftUI

extension AppDelegate {
    private func setupCustomAboutMenu() {
        // Replace the default About menu item with a custom one
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            _ = self.aboutMenuConfigurator.configure(
                mainMenu: NSApplication.shared.mainMenu,
                target: self,
                action: #selector(AppDelegate.showCustomAbout)
            )
        }
    }
    
    @objc private func showCustomAbout() {
        // Create custom About window with SwiftUI view
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About Audientia"
        aboutWindow.center()
        aboutWindow.isReleasedWhenClosed = false
        
        // Create SwiftUI About view
        let aboutView = AboutView()
        let hostingView = NSHostingView(rootView: aboutView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 450, height: 400)
        
        aboutWindow.contentView = hostingView
        aboutWindow.makeKeyAndOrderFront(nil)
    }
    
    private func setupSetupWizardMenu() {
        // Try to add menu item immediately, then retry if needed
        func tryAddMenu(attempt: Int = 0) {
            guard attempt < 10 else {
                Logger.userInterface.error(
                    "Failed to add Setup Wizard menu item after 10 attempts"
                )
                return
            }
            
            let delay = attempt == 0 ? 0.0 : Double(attempt) * 0.1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                // Always call configure - it will update existing item or create new one
                let success = self.setupWizardMenuConfigurator.configure(
                    mainMenu: NSApplication.shared.mainMenu,
                    target: self,
                    action: #selector(AppDelegate.showSetupWizard)
                )
                
                if success {
                    Logger.userInterface.info(
                        "Setup Wizard menu item configured successfully on attempt \(attempt + 1)"
                    )
                } else if attempt < 9 {
                    tryAddMenu(attempt: attempt + 1)
                }
            }
        }
        
        tryAddMenu()
    }
    
    @objc func showSetupWizard() {
        // Don't show setup wizard if splash screen is visible
        guard !shortcutsDisabled else {
            Logger.userInterface.info("Setup Wizard requested but splash screen is visible")
            return
        }
        
        Logger.userInterface.info("showSetupWizard() called")
        Task { @MainActor in
            Logger.userInterface.info("Creating Setup Wizard window")
            // Close existing wizard window if open
            setupWizardWindow?.close()
            
            // Create setup wizard window
            let wizardWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 550),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            wizardWindow.title = "Setup Wizard"
            wizardWindow.center()
            wizardWindow.isReleasedWhenClosed = false
            
            // Create SwiftUI Setup Wizard view
            let wizardView = SetupWizardView()
            let hostingView = NSHostingView(rootView: wizardView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 700, height: 550)
            
            wizardWindow.contentView = hostingView
            wizardWindow.makeKeyAndOrderFront(nil)
            
            setupWizardWindow = wizardWindow
            Logger.userInterface.info("Setup Wizard window created and shown")
        }
    }
}
