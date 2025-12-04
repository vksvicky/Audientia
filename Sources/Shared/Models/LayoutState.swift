//
//  LayoutState.swift
//  Audientia
//
//  Layout state configuration for UI persistence
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Layout state configuration for UI elements
public struct LayoutState: Codable, Equatable, Sendable {
    /// Toolbar expanded state (true = expanded, false = collapsed)
    public var isToolbarExpanded: Bool
    
    /// Player bar expanded state (true = expanded, false = collapsed)
    public var isPlayerExpanded: Bool
    
    public init(
        isToolbarExpanded: Bool = true,
        isPlayerExpanded: Bool = true
    ) {
        self.isToolbarExpanded = isToolbarExpanded
        self.isPlayerExpanded = isPlayerExpanded
    }
    
    public static let `default` = LayoutState()
}

/// Layout state manager protocol
public protocol LayoutStateManagerProtocol: Sendable {
    func saveLayoutState(_ state: LayoutState) async throws
    func loadLayoutState() async -> LayoutState
    func resetToDefault() async throws
}

/// Layout state manager with persistence
public actor LayoutStateManager: LayoutStateManagerProtocol {
    private let storage: any SettingsStorageProtocol
    private let layoutStateKey = "layout.state"
    
    public init(storage: any SettingsStorageProtocol = UserDefaultsSettingsStorage()) {
        self.storage = storage
    }
    
    public func saveLayoutState(_ state: LayoutState) async throws {
        try await storage.save(state, forKey: layoutStateKey)
    }
    
    public func loadLayoutState() async -> LayoutState {
        guard let state = try? await storage.load(LayoutState.self, forKey: layoutStateKey) else {
            return LayoutState.default
        }
        return state
    }
    
    public func resetToDefault() async throws {
        try await saveLayoutState(.default)
    }
}
