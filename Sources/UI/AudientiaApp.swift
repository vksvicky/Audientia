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
        guard let infoDict = Bundle.main.infoDictionary,
              let shortVersion = infoDict["CFBundleShortVersionString"] as? String,
              let appName = infoDict["CFBundleName"] as? String else {
            // Fallback to default About panel
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
            return
        }
        
        // Create custom About window
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About \(appName)"
        aboutWindow.center()
        aboutWindow.isReleasedWhenClosed = false
        
        // Create custom view with only our version
        let aboutView = NSStackView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        aboutView.orientation = .vertical
        aboutView.alignment = .centerX
        aboutView.spacing = 10
        aboutView.edgeInsets = NSEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        
        let appNameLabel = NSTextField(labelWithString: appName)
        appNameLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        aboutView.addArrangedSubview(appNameLabel)
        
        let versionLabel = NSTextField(labelWithString: "Version \(shortVersion)")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        aboutView.addArrangedSubview(versionLabel)
        
        if let copyright = infoDict["NSHumanReadableCopyright"] as? String {
            let copyrightLabel = NSTextField(labelWithString: copyright)
            copyrightLabel.font = NSFont.systemFont(ofSize: 10)
            copyrightLabel.textColor = .tertiaryLabelColor
            aboutView.addArrangedSubview(copyrightLabel)
        }
        
        aboutWindow.contentView = aboutView
        aboutWindow.makeKeyAndOrderFront(nil)
    }
}
