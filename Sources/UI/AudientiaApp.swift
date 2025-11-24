//
//  AudientiaApp.swift
//  Audientia
//
//  Main application entry point
//

import AppKit
import os.log
import Shared
import SwiftUI

@main
struct AudientiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared

    init() {
        // Update versions on app launch
        updateAppVersionFromBuild()
        scanAndRegisterModules()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .commands {
            // Add menu commands here
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let dependencyChecker = DependencyChecker()
    private let hasCheckedDependenciesKey = "hasCheckedDependencies"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Customize About panel to show only our version format
        setupCustomAboutMenu()
        
        // Check dependencies on first launch (only once)
        checkDependenciesOnFirstLaunch()
    }
    
    private func checkDependenciesOnFirstLaunch() {
        let hasChecked = UserDefaults.standard.bool(forKey: hasCheckedDependenciesKey)
        
        // Only check on first launch
        guard !hasChecked else { return }
        
        UserDefaults.standard.set(true, forKey: hasCheckedDependenciesKey)
        
        Task {
            let dependencies = await dependencyChecker.checkAllDependencies()
            let missingRequired = dependencies.filter { dep in
                dep.isRequired && {
                    switch dep.status {
                    case .missing, .outdated:
                        return true
                    case .available:
                        return false
                    }
                }()
            }
            
            if !missingRequired.isEmpty {
                let message = await dependencyChecker.formatStatusMessage(dependencies)
                await MainActor.run {
                    showDependencyAlert(message: message, missingRequired: missingRequired)
                }
            }
        }
    }
    
    @MainActor
    private func showDependencyAlert(message: String, missingRequired: [DependencyInfo]) {
        let alert = NSAlert()
        alert.messageText = "Missing Required Dependencies"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Installation Instructions")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open installation instructions
            if let instructionsURL = Bundle.main.url(forResource: "INSTALL_INSTRUCTIONS", withExtension: "md") {
                NSWorkspace.shared.open(instructionsURL)
            } else {
                // Fallback: open Terminal with installation commands
                let script = """
                tell application "Terminal"
                    activate
                    do script "echo 'Installing dependencies...' && brew install ffmpeg chromaprint"
                end tell
                """
                if let appleScript = NSAppleScript(source: script) {
                    appleScript.executeAndReturnError(nil)
                }
            }
        }
    }
    
    private func setupCustomAboutMenu() {
        // Replace the default About menu item with a custom one
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let mainMenu = NSApplication.shared.mainMenu,
               let appMenu = mainMenu.item(at: 0),
               let appMenuMenu = appMenu.submenu {
                
                // Find the About menu item
                if let aboutItem = appMenuMenu.item(withTitle: "About Audientia") {
                    aboutItem.target = self
                    aboutItem.action = #selector(self.showCustomAbout)
                }
            }
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
}
