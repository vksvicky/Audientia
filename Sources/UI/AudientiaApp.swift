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

@main
struct AudientiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared
    @State private var showSplashScreen = false
    @State private var showMainWindow = false

    init() {
        // Update versions on app launch
        updateAppVersionFromBuild()
        scanAndRegisterModules()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content - only visible when splash is dismissed
                if showMainWindow {
                    ContentView()
                        .environmentObject(settings)
                }
                
                // Splash screen - covers everything when visible
                if showSplashScreen && settings.showSplashScreen {
                    SplashScreenView(settings: settings)
                        .transition(.opacity)
                        .zIndex(1000)
                        .allowsHitTesting(true)
                }
            }
            .onAppear {
                Task { await NotificationPermissionManager.shared.ensureInitialPromptIfNeeded() }
                // Show splash screen on app launch if enabled
                if settings.showSplashScreen {
                    showSplashScreen = true
                    showMainWindow = false
                    // Hide main window and disable shortcuts while splash is showing
                    appDelegate.hideMainWindow()
                    appDelegate.disableKeyboardShortcuts()
                    
                    // Auto-dismiss after 10 seconds, then show main window and setup wizard if needed
                    Task {
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSplashScreen = false
                            }
                            // Show main window and re-enable shortcuts
                            showMainWindow = true
                            appDelegate.showMainWindow()
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
                    // If splash is disabled, show main window immediately
                    showMainWindow = true
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
        .commands {
            // Replace "New Window" with "Setup Wizard" in File menu
            // This is the proper SwiftUI way and won't be overwritten
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
    
    private let dependencyChecker = DependencyChecker()
    private let hasCheckedDependenciesKey = "hasCheckedDependencies"
    private let aboutMenuConfigurator = AboutMenuConfigurator()
    private let setupWizardMenuConfigurator = SetupWizardMenuConfigurator()
    let windowStateManager = WindowStateManager() // Internal for testing
    private var setupWizardWindow: NSWindow?
    var mainWindow: NSWindow?
    var minimisedPlayerWindow: NSWindow?
    private var minimisedPlayerWindowDelegate: MinimisedPlayerWindowDelegate?
    private var shortcutsDisabled = false
    var isMinimised = false
    private var shouldRestoreMinimizedState = false
    
    override init() {
        super.init()
        // Store this instance as the shared delegate
        AppDelegate._sharedInstance = self
        // Ensure NSApplication knows about it
        // @NSApplicationDelegateAdaptor should set this, but we ensure it's set
        NSApplication.shared.delegate = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure we're set as the delegate (reassigning is safe and ensures correctness)
        NSApplication.shared.delegate = self
        
        // Customize About panel to show only our version format
        setupCustomAboutMenu()
        
        // Setup wizard menu item is now handled by SwiftUI's .commands modifier
        // This ensures it persists when SwiftUI recreates the menu bar
        
        // Check dependencies on first launch (only once)
        checkDependenciesOnFirstLaunch()
        
        // Store reference to main window and configure it
        DispatchQueue.main.async { [weak self] in
            if let window = NSApplication.shared.windows.first {
                self?.mainWindow = window
                // Configure window: minimum size, allow maximize/minimize
                window.minSize = NSSize(width: 1000, height: 600)
                window.styleMask.insert(.resizable)
                window.styleMask.insert(.miniaturizable)
                window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling]
                
                // Restore window state (position and minimized mode)
                Task { [weak self] in
                    await self?.restoreWindowState()
                }
            }
        }
        
        // Note: Setup wizard is now shown after splash screen dismisses (handled in onAppear)
    }
    
    @MainActor
    func hideMainWindow() {
        mainWindow?.orderOut(nil)
        setupWizardWindow?.orderOut(nil)
    }
    
    @MainActor
    func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Menu is now managed by SwiftUI's .commands modifier
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
        
        // Hide main window
        mainWindow?.orderOut(nil)
        
        // Create minimised player window using factory
        let (playerWindow, windowDelegate) = MinimisedPlayerWindowFactory.createWindow(
            nowPlayingViewModel: nowPlayingViewModel,
            onRestore: { [weak self] in
                self?.restoreFromPlayer()
            },
            onClose: { [weak self] in
                self?.closeMinimisedPlayer()
            }
        )
        
        playerWindow.makeKeyAndOrderFront(nil)
        minimisedPlayerWindow = playerWindow
        minimisedPlayerWindowDelegate = windowDelegate
        isMinimised = true
        
        // Position window using helper
        WindowPositioningHelper.positionMinimisedPlayerWindow(
            playerWindow,
            savedState: nil, // Will be loaded in helper
            mainWindowFrame: mainWindowFrame,
            windowStateManager: windowStateManager
        ) { [weak self] in
            await self?.saveWindowState()
        }
        
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
        // This is necessary because if the user restores and then closes the app,
        // we want to remember they're in main window mode, not minimized mode
        Task {
            await saveWindowState()
        }
        
        Logger.userInterface.info("Restored from player window")
    }
    
    @MainActor
    func closeMinimisedPlayer() {
        guard isMinimised else { return }
        
        // Save state before closing (app will terminate after this)
        Task {
            await saveWindowState()
        }
        
        // Close minimised window
        minimisedPlayerWindow?.close()
        minimisedPlayerWindow = nil
        minimisedPlayerWindowDelegate = nil
        
        // Don't restore main window - just close the minimized player
        isMinimised = false
        Logger.userInterface.info("Closed minimised player window")
    }
    
    // MARK: - Window State Persistence
    
    /// Save window state immediately (public for window delegate)
    @MainActor
    func saveWindowStateImmediate() async {
        Logger.userInterface.info("saveWindowStateImmediate: Starting save")
        await saveWindowState()
        Logger.userInterface.info("saveWindowStateImmediate: Save finished")
    }
    
    /// Save current window state (position and minimized mode)
    @MainActor
    private func saveWindowState() async {
        Logger.userInterface.info(
            "saveWindowState: Starting, isMinimised=\(self.isMinimised), "
            + "minimisedPlayerWindow exists=\(self.minimisedPlayerWindow != nil)"
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
                "Window state saved successfully: frame=\(NSStringFromRect(frame)), "
                + "isMinimised=\(isMinimisedState)"
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
            // No saved state, use defaults
            Logger.userInterface.info("No saved window state found, using defaults")
            return
        }
        
        let frame = savedState.frame
        let wasMinimised = savedState.isMinimised
        
        Logger.userInterface.info(
            "Restoring window state: frame=\(NSStringFromRect(frame)), wasMinimised=\(wasMinimised)"
        )
        
        // Restore window position (only if not minimized, as minimized will be handled separately)
        if !wasMinimised, let mainWindow = mainWindow {
            // Ensure frame is on a valid screen
            let validFrame = ensureFrameOnScreen(frame)
            mainWindow.setFrame(validFrame, display: false)
            Logger.userInterface.info("Restored window position: \(NSStringFromRect(validFrame))")
        }
        
        // Store flag to restore minimized state after view model is available
        if wasMinimised {
            self.shouldRestoreMinimizedState = true
            Logger.userInterface.info(
                "App was in minimized player mode, will restore after view model is available, "
                + "shouldRestoreMinimizedState=\(self.shouldRestoreMinimizedState)"
            )
        } else {
            Logger.userInterface.info("App was in main window mode")
        }
    }
    
    /// Ensure the frame is on a valid screen
    @MainActor
    func ensureFrameOnScreen(_ frame: CGRect) -> CGRect {
        // Check if frame is on any screen
        let screens = NSScreen.screens
        for screen in screens {
            let screenFrame = screen.frame
            if screenFrame.intersects(frame) {
                // Frame is on this screen, return as-is
                return frame
            }
        }
        
        // Frame is not on any screen, center on main screen
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let centeredX = screenFrame.midX - frame.width / 2
            let centeredY = screenFrame.midY - frame.height / 2
            return CGRect(
                x: centeredX,
                y: centeredY,
                width: frame.width,
                height: frame.height
            )
        }
        
        // Fallback to original frame
        return frame
    }
    
    /// Restore minimized state if needed (called when view model is available)
    @MainActor
    func restoreMinimizedStateIfNeeded(nowPlayingViewModel: NowPlayingViewModel) {
        Logger.userInterface.info(
            "restoreMinimizedStateIfNeeded called, "
            + "shouldRestoreMinimizedState=\(self.shouldRestoreMinimizedState)"
        )
        
        // Check both the flag and the saved state directly (in case of timing issues)
        Task {
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
        }
    }
}
