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
    @State private var showSplashScreen = false

    init() {
        // Update versions on app launch
        updateAppVersionFromBuild()
        scanAndRegisterModules()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(settings)
                
                if showSplashScreen && settings.showSplashScreen {
                    SplashScreenView(settings: settings)
                        .transition(.opacity)
                        .zIndex(1000) // Ensure splash is on top
                }
            }
            .onAppear {
                Task { await NotificationPermissionManager.shared.ensureInitialPromptIfNeeded() }
                // Show splash screen on app launch if enabled
                if settings.showSplashScreen {
                    showSplashScreen = true
                    // Auto-dismiss after 10 seconds, then show setup wizard if needed
                    Task {
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSplashScreen = false
                            }
                            // Show setup wizard after splash screen dismisses
                            if SetupWizardViewModel.shouldShowWizard() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    appDelegate.showSetupWizard()
                                }
                            }
                        }
                    }
                } else {
                    // If splash is disabled, show setup wizard immediately if needed
                    if SetupWizardViewModel.shouldShowWizard() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            appDelegate.showSetupWizard()
                        }
                    }
                }
            }
        }
        .commands {
            // Replace "New Window" with "Setup Wizard" in File menu
            // This is the proper SwiftUI way and won't be overwritten
            CommandGroup(replacing: .newItem) {
                Button("Setup Wizard...") {
                    Logger.userInterface.info("Setup Wizard menu item clicked")
                    appDelegate.showSetupWizard()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
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
    private let aboutMenuConfigurator = AboutMenuConfigurator()
    private let setupWizardMenuConfigurator = SetupWizardMenuConfigurator()
    private var setupWizardWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Customize About panel to show only our version format
        setupCustomAboutMenu()
        
        // Setup wizard menu item is now handled by SwiftUI's .commands modifier
        // This ensures it persists when SwiftUI recreates the menu bar
        
        // Check dependencies on first launch (only once)
        checkDependenciesOnFirstLaunch()
        
        // Note: Setup wizard is now shown after splash screen dismisses (handled in onAppear)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Menu is now managed by SwiftUI's .commands modifier
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Quit the app when the main window is closed
        true
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
                Logger.userInterface.error("Failed to add Setup Wizard menu item after 10 attempts")
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
