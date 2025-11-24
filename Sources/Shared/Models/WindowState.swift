//
//  WindowState.swift
//  Audientia
//
//  Window state configuration models
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import CoreGraphics
import Foundation

/// Window state configuration
public struct WindowState: Codable, Equatable, Sendable {
    public var frame: CGRect
    public var isMaximized: Bool
    public var isMinimized: Bool
    
    public init(
        frame: CGRect = CGRect(x: 100, y: 100, width: 1200, height: 800),
        isMaximized: Bool = false,
        isMinimized: Bool = false
    ) {
        self.frame = frame
        self.isMaximized = isMaximized
        self.isMinimized = isMinimized
    }
}

/// Window state manager protocol
public protocol WindowStateManagerProtocol: Sendable {
    func saveWindowState(_ state: WindowState) async throws
    func loadWindowState() async -> WindowState?
    func clearWindowState() async throws
}

/// Window state manager with persistence
public actor WindowStateManager: WindowStateManagerProtocol {
    private let storage: any SettingsStorageProtocol
    private let windowStateKey = "window.state"
    
    public init(storage: any SettingsStorageProtocol = UserDefaultsSettingsStorage()) {
        self.storage = storage
    }
    
    public func saveWindowState(_ state: WindowState) async throws {
        try await storage.save(state, forKey: windowStateKey)
    }
    
    public func loadWindowState() async -> WindowState? {
        try? await storage.load(WindowState.self, forKey: windowStateKey)
    }
    
    public func clearWindowState() async throws {
        try await storage.remove(forKey: windowStateKey)
    }
}
