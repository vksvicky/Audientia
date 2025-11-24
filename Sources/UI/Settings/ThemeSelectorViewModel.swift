//
//  ThemeSelectorViewModel.swift
//  Audientia
//
//  ViewModel for Theme Selector UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for Theme Selector UI
@MainActor
public final class ThemeSelectorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current theme
    @Published public private(set) var currentTheme: ThemeConfiguration = .auto
    
    /// Available themes
    @Published public private(set) var availableThemes: [ThemeConfiguration] = []
    
    /// Whether theme is being saved
    @Published public private(set) var isSaving = false
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    /// Success message
    @Published public private(set) var successMessage: String?
    
    // MARK: - Private Properties
    
    private let themeManager: any ThemeManagerProtocol
    private let logger = Logger.userInterface
    
    // MARK: - Initialization
    
    public init(themeManager: any ThemeManagerProtocol = ThemeManager()) {
        self.themeManager = themeManager
    }
    
    // MARK: - Public Methods
    
    /// Load current theme and available themes
    public func loadThemes() async {
        currentTheme = await themeManager.loadTheme()
        availableThemes = themeManager.getAvailableThemes()
        logger.debug("Themes loaded")
    }
    
    /// Select and save theme
    public func selectTheme(_ theme: ThemeConfiguration) async {
        isSaving = true
        lastError = nil
        
        do {
            try await themeManager.saveTheme(theme)
            currentTheme = theme
            successMessage = "Theme changed to \(theme.name)"
            logger.info("Theme changed to: \(theme.name)")
        } catch {
            lastError = error
            logger.error("Failed to save theme: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    /// Reset to default theme
    public func resetToDefault() async {
        do {
            try await themeManager.resetToDefault()
            currentTheme = await themeManager.loadTheme()
            successMessage = "Theme reset to default"
            logger.info("Theme reset to default")
        } catch {
            lastError = error
            logger.error("Failed to reset theme: \(error.localizedDescription)")
        }
    }
    
    /// Clear success message
    public func clearSuccessMessage() {
        successMessage = nil
    }

    /// Clear the last error shown to the user
    public func clearLastError() {
        lastError = nil
    }
}
