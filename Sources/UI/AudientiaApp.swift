//
//  AudientiaApp.swift
//  Audientia
//
//  Main application entry point
//

import AppKit
import CoreGraphics
import os.log
import Shared
import SwiftUI

// MARK: - Window Accessor

/// ViewModifier to access the NSWindow from SwiftUI view hierarchy
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = WindowTrackingView(callback: callback)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Window will be captured when view moves to window
    }
}

/// NSView subclass that tracks when it's added to a window
private class WindowTrackingView: NSView {
    let callback: (NSWindow?) -> Void
    
    init(callback: @escaping (NSWindow?) -> Void) {
        self.callback = callback
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.callback(self?.window)
        }
    }
}

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
                // Main content - always visible so window is created
                ContentView()
                    .environmentObject(settings)
                
                // Splash screen - covers everything when visible
                if showSplashScreen && settings.showSplashScreen {
                    SplashScreenView(settings: settings)
                        .transition(.opacity)
                        .zIndex(1000)
                        .allowsHitTesting(true)
                }
            }
            .background(WindowAccessor { window in
                // Capture the window when it's available from SwiftUI view hierarchy
                // Only capture if it's not a sheet, not the minimised player, and not an About window
                guard let window = window,
                      !window.isSheet,
                      window != appDelegate.minimisedPlayerWindow,
                      !window.title.contains("About"),
                      window.title.isEmpty || window.title == "Audientia" else {
                    return
                }
                
                // Only configure once
                guard appDelegate.mainWindow == nil else { return }
                
                appDelegate.mainWindow = window
                if window.title.isEmpty {
                    window.title = "Audientia"
                }
                
                // Ensure window is visible immediately - this is critical
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                
                // Configure window properties
                Task { @MainActor in
                    appDelegate.configureMainWindow(window)
                }
            })
            .onAppear {
                Task { await NotificationPermissionManager.shared.ensureInitialPromptIfNeeded() }
                
                // Show splash screen on app launch if enabled
                if settings.showSplashScreen {
                    showSplashScreen = true
                    appDelegate.disableKeyboardShortcuts()
                    
                    // Auto-dismiss after 10 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSplashScreen = false
                            }
                            appDelegate.enableKeyboardShortcuts()
                            
                            // Show setup wizard after splash screen dismisses
                            if SetupWizardViewModel.shouldShowWizard() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    appDelegate.showSetupWizard()
                                }
                            }
                        }
                    }
                } else {
                    // Show setup wizard immediately if needed
                    if SetupWizardViewModel.shouldShowWizard() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            appDelegate.showSetupWizard()
                        }
                    }
                }
            }
        }
        .defaultSize(width: 1200, height: 800)
        .windowResizability(.contentSize)
        .windowStyle(.automatic)
        .handlesExternalEvents(matching: Set(["*"])) // Allow window to handle all external events
        .commands {
            // Replace "New Window" with "Setup Wizard" in File menu
            CommandGroup(replacing: .newItem) {
                Button("Setup Wizard...") {
                    Logger.userInterface.info("Setup Wizard menu item clicked")
                    appDelegate.showSetupWizard()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(showSplashScreen && settings.showSplashScreen)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Static reference to the AppDelegate instance
    private static var _sharedInstance: AppDelegate?
    
    static var shared: AppDelegate? {
        // Try static instance first
        if let instance = _sharedInstance {
            return instance
        }
        // Fallback to NSApplication delegate
        return NSApplication.shared.delegate as? AppDelegate
    }
    
    let dependencyChecker = DependencyChecker()
    let hasCheckedDependenciesKey = "hasCheckedDependencies"
    let aboutMenuConfigurator = AboutMenuConfigurator()
    let setupWizardMenuConfigurator = SetupWizardMenuConfigurator()
    let windowStateManager = WindowStateManager() // Internal for testing
    var setupWizardWindow: NSWindow?
    var mainWindow: NSWindow?
    var minimisedPlayerWindow: NSWindow?
    var minimisedPlayerWindowDelegate: MinimisedPlayerWindowDelegate?
    var shortcutsDisabled = false
    var isMinimised = false
    var shouldRestoreMinimizedState = false
    private var hasConfiguredMainWindow = false
    
    override init() {
        super.init()
        AppDelegate._sharedInstance = self // Set static instance
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure we're set as the delegate
        NSApplication.shared.delegate = self
        
        // Activate the app
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Customize About panel
        setupCustomAboutMenu()
        
        // Check dependencies on first launch
        checkDependenciesOnFirstLaunch()
        
        // Simple, reliable fallback: ensure at least one window is visible
        // WindowAccessor should handle the main window, but this ensures something shows up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // If main window still not configured, find and show any non-sheet window
            if self?.hasConfiguredMainWindow == false {
                // Find any window that could be the main window
                let candidateWindows = NSApplication.shared.windows.filter {
                    !$0.isSheet &&
                    $0.title != "Settings" &&
                    $0.title != "Audientia Player" &&
                    !$0.title.contains("About")
                }
                
                if let window = candidateWindows.first {
                    self?.mainWindow = window
                    if window.title.isEmpty {
                        window.title = "Audientia"
                    }
                    window.makeKeyAndOrderFront(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    Task { @MainActor in
                        self?.configureMainWindow(window)
                    }
                } else {
                    // Last resort: show any window
                    if let window = NSApplication.shared.windows.first(where: { !$0.isSheet }) {
                        window.makeKeyAndOrderFront(nil)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
            }
        }
    }
    
    @MainActor
    func hideMainWindow() {
        mainWindow?.orderOut(nil)
        setupWizardWindow?.orderOut(nil)
    }
    
    @MainActor
    func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            Logger.userInterface.info("Main window explicitly shown via showMainWindow()")
        } else {
            // Try to find the window if mainWindow is nil
            if let window = NSApplication.shared.windows.first(where: { !$0.isSheet }) {
                self.mainWindow = window
                window.makeKeyAndOrderFront(nil)
                Logger.userInterface.info("Main window found and shown via showMainWindow()")
            } else {
                Logger.userInterface.warning("Cannot show main window - window not found")
            }
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Ensure window is visible when app becomes active
        if let window = mainWindow, !window.isVisible, !isMinimised {
            window.makeKeyAndOrderFront(nil)
            Logger.userInterface.info("App became active - ensuring main window is visible")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Quit the app when the main window is closed
        true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save window state before app terminates
        // Use a semaphore to ensure the save completes before termination
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            await saveWindowState()
            semaphore.signal()
        }
        // Wait up to 1 second for the save to complete
        _ = semaphore.wait(timeout: .now() + 1.0)
    }
    
    @MainActor
    func minimizeToPlayer(nowPlayingViewModel: NowPlayingViewModel) {
        guard !isMinimised else { return }
        
        // Get main window frame before hiding it (for centering)
        let mainWindowFrame = mainWindow?.frame ?? NSRect.zero
        
        // Create minimised player window using factory first
        let (playerWindow, windowDelegate) = MinimisedPlayerWindowFactory.createWindow(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { [weak self] in
                self?.restoreFromPlayer()
            },
            onClose: { [weak self] in
                self?.closeMinimisedPlayer()
            }
        )
        
        // Only hide main window if minimized player window was successfully created
        playerWindow.makeKeyAndOrderFront(nil)
        minimisedPlayerWindow = playerWindow
        minimisedPlayerWindowDelegate = windowDelegate
        isMinimised = true
        
        // Now hide the main window since minimized player is ready
        mainWindow?.orderOut(nil)
        
        // Save state immediately after setting minimized state
        // This ensures the state is saved even if positioning is delayed
        Task { @MainActor in
            await saveWindowState()
        }
        
        // Position window using helper
        WindowPositioningHelper.positionMinimisedPlayerWindow(
            playerWindow,
            savedState: nil, // Will load from windowStateManager
            mainWindowFrame: mainWindowFrame,
            windowStateManager: windowStateManager,
            onComplete: { [weak self] in
                // Save state again after positioning is complete to capture final frame
                guard let self = self else { return }
                Task { @MainActor in
                    await self.saveWindowState()
                }
            }
        )
        
        Logger.userInterface.info("Minimised to player window")
    }
    
    @MainActor
    func restoreFromPlayer() {
        guard isMinimised else { return }
        
        // Close minimised window
        minimisedPlayerWindow?.close()
        minimisedPlayerWindow = nil
        minimisedPlayerWindowDelegate = nil
        
        // Show main window
        mainWindow?.makeKeyAndOrderFront(nil)
        
        isMinimised = false
        
        // Save the new state (main window mode) immediately so it persists
        Task { @MainActor in
            await saveWindowState()
        }
        
        Logger.userInterface.info("Restored from player window")
    }
    
    @MainActor
    func closeMinimisedPlayer() {
        guard isMinimised else { return }
        
        // Save state before closing (while window still exists)
        Task { @MainActor in
            await saveWindowState()
        }
        
        // Close minimised window
        minimisedPlayerWindow?.close()
        minimisedPlayerWindow = nil
        minimisedPlayerWindowDelegate = nil
        
        // Reset minimized state and restore main window
        isMinimised = false
        mainWindow?.makeKeyAndOrderFront(nil)
        
        // Save state after closing (main window mode)
        Task { @MainActor in
            await saveWindowState()
        }
    }
    
    /// Configure the main window with settings
    @MainActor
    func configureMainWindow(_ window: NSWindow) {
        // Only configure if not already configured for this window
        guard !hasConfiguredMainWindow || mainWindow == window else { return }
        
        // If already configured for this window, skip
        if hasConfiguredMainWindow && mainWindow == window {
            return
        }
        
        mainWindow = window
        hasConfiguredMainWindow = true
        
        // Configure window: minimum size, allow maximize/minimize
        window.minSize = NSSize(width: 1000, height: 600)
        window.styleMask.insert(.resizable)
        window.styleMask.insert(.miniaturizable)
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling]
        window.isRestorable = false
        
        // Ensure window is visible
        window.makeKeyAndOrderFront(nil)
        
        Logger.userInterface.info("Main window configured: \(window.title)")
        
        // Restore window state (position and minimized mode) after a short delay
        // to let SwiftUI finish setting up the window
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
            await self?.restoreWindowState()
        }
    }
}
