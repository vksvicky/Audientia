//
//  LayoutConfigurationManager.swift
//  Audientia
//
//  Manager for layout configuration persistence
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Protocol for managing layout configuration
public protocol LayoutConfigurationManagerProtocol: Sendable {
    func saveLayout(_ layout: LayoutConfiguration) async throws
    func loadLayout() async -> LayoutConfiguration
    func resetToDefault() async throws
}

/// Manager for layout configuration with persistence
public actor LayoutConfigurationManager: LayoutConfigurationManagerProtocol {
    private let storage: any SettingsStorageProtocol
    private let layoutKey = "layout.configuration"
    
    public init(storage: any SettingsStorageProtocol = UserDefaultsSettingsStorage()) {
        self.storage = storage
    }
    
    public func saveLayout(_ layout: LayoutConfiguration) async throws {
        try await storage.save(layout, forKey: layoutKey)
    }
    
    public func loadLayout() async -> LayoutConfiguration {
        guard let layout = try? await storage.load(LayoutConfiguration.self, forKey: layoutKey) else {
            return LayoutConfiguration.default
        }
        return layout
    }
    
    public func resetToDefault() async throws {
        try await saveLayout(.default)
    }
}
