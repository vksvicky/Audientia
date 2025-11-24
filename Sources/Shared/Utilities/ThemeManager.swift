//
//  ThemeManager.swift
//  Audientia
//
//  Manager for theme configuration
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Protocol for managing theme configuration
public protocol ThemeManagerProtocol: Sendable {
    func saveTheme(_ theme: ThemeConfiguration) async throws
    func loadTheme() async -> ThemeConfiguration
    func getAvailableThemes() -> [ThemeConfiguration]
    func resetToDefault() async throws
}

/// Manager for theme configuration with persistence
public actor ThemeManager: ThemeManagerProtocol {
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
            return .auto
        }
        return theme
    }
    
    public nonisolated func getAvailableThemes() -> [ThemeConfiguration] {
        [.light, .dark, .auto]
    }
    
    public func resetToDefault() async throws {
        try await saveTheme(.auto)
    }
}
