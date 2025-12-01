//
//  SettingsViewModel.swift
//  Audientia
//
//  ViewModel for Settings/Preferences UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for Settings/Preferences UI
/// Manages all application settings including layout, theme, window state, and library view configuration
@MainActor
public final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current layout configuration
    @Published public private(set) var currentLayout: LayoutConfiguration?
    
    /// Current theme configuration
    @Published public private(set) var currentTheme: ThemeConfiguration?
    
    /// Current window state
    @Published public private(set) var currentWindowState: WindowState?
    
    /// Current library view configuration
    @Published public private(set) var currentLibraryViewConfig: LibraryViewConfiguration?
    
    /// Available themes
    @Published public private(set) var availableThemes: [ThemeConfiguration] = []
    
    /// Whether settings are being loaded
    @Published public private(set) var isLoading = false
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    /// Success message
    @Published public private(set) var successMessage: String?
    
    // MARK: - Private Properties
    
    private let layoutManager: any LayoutConfigurationManagerProtocol
    private let themeManager: any ThemeManagerProtocol
    private let windowStateManager: any WindowStateManagerProtocol
    private let libraryViewManager: any LibraryViewConfigurationManagerProtocol
    private let logger = Logger.userInterface
    
    // MARK: - Initialisation
    
    public init(
        layoutManager: any LayoutConfigurationManagerProtocol = LayoutConfigurationManager(),
        themeManager: any ThemeManagerProtocol = ThemeManager(),
        windowStateManager: any WindowStateManagerProtocol = WindowStateManager(),
        libraryViewManager: any LibraryViewConfigurationManagerProtocol = LibraryViewConfigurationManager()
    ) {
        self.layoutManager = layoutManager
        self.themeManager = themeManager
        self.windowStateManager = windowStateManager
        self.libraryViewManager = libraryViewManager
    }
    
    // MARK: - Public Methods
    
    /// Load all settings
    public func loadSettings() async {
        isLoading = true
        lastError = nil
        
        let layout = await layoutManager.loadLayout()
        let theme = await themeManager.loadTheme()
        let windowState = await windowStateManager.loadWindowState()
        let libraryConfig = await libraryViewManager.loadConfiguration()
        let themes = themeManager.getAvailableThemes()
        
        currentLayout = layout
        currentTheme = theme
        currentWindowState = windowState
        currentLibraryViewConfig = libraryConfig
        availableThemes = themes
        
        logger.debug("Settings loaded successfully")
        
        isLoading = false
    }
    
    /// Save layout configuration
    public func saveLayoutConfiguration(_ layout: LayoutConfiguration) async throws {
        try await layoutManager.saveLayout(layout)
        currentLayout = layout
        successMessage = "Layout configuration saved"
        logger.info("Layout configuration saved")
    }
    
    /// Save theme configuration
    public func saveThemeConfiguration(_ theme: ThemeConfiguration) async throws {
        try await themeManager.saveTheme(theme)
        currentTheme = theme
        successMessage = "Theme saved"
        logger.info("Theme saved: \(theme.name)")
    }
    
    /// Save window state
    public func saveWindowState(_ state: WindowState) async throws {
        try await windowStateManager.saveWindowState(state)
        currentWindowState = state
        logger.debug("Window state saved")
    }
    
    /// Save library view configuration
    public func saveLibraryViewConfiguration(_ config: LibraryViewConfiguration) async throws {
        try await libraryViewManager.saveConfiguration(config)
        currentLibraryViewConfig = config
        successMessage = "Library view configuration saved"
        logger.info("Library view configuration saved")
    }
    
    /// Reset all settings to defaults
    public func resetToDefaults() async throws {
        try await layoutManager.resetToDefault()
        try await themeManager.resetToDefault()
        try await libraryViewManager.resetToDefault()
        
        await loadSettings()
        successMessage = "Settings reset to defaults"
        logger.info("Settings reset to defaults")
    }
    
    /// Clear success message
    public func clearSuccessMessage() {
        successMessage = nil
    }
}
