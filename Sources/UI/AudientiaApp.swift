//
//  AudientiaApp.swift
//  Audientia
//
//  Main application entry point
//

import AppKit
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
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Customize About panel to show only our version format
        setupCustomAboutMenu()
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
