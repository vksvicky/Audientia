//
//  ThemeConfigurationManager.swift
//  Audientia
//
//  Theme configuration manager
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Protocol for managing theme configurations
public protocol ThemeConfigurationManagerProtocol: Sendable {
    func saveTheme(_ theme: ThemeConfiguration) async throws
    func loadTheme() async -> ThemeConfiguration
    func getAvailableThemes() -> [ThemeConfiguration]
    func resetToDefault() async throws
}

/// Manager for theme configurations with persistence
public actor ThemeConfigurationManager: ThemeConfigurationManagerProtocol {
    private let storage: any SettingsStorageProtocol
    private let themeKey = "theme.configuration"
    
    public init(storage: any SettingsStorageProtocol = UserDefaultsSettingsStorage()) {
        self.storage = storage
    }
    
    public func saveTheme(_ theme: ThemeConfiguration) async throws {
        try await storage.save(theme, forKey: themeKey)
    }
    
    public func loadTheme() async -> ThemeConfiguration {
        guard let theme = try? await storage.load(ThemeConfiguration.self, forKey: themeKey) else {
            return ThemeConfiguration.auto
        }
        return theme
    }
    
    public nonisolated func getAvailableThemes() -> [ThemeConfiguration] {
        [
            ThemeConfiguration.light,
            ThemeConfiguration.dark,
            ThemeConfiguration.auto
        ]
    }
    
    public func resetToDefault() async throws {
        try await storage.save(ThemeConfiguration.auto, forKey: themeKey)
    }
}
