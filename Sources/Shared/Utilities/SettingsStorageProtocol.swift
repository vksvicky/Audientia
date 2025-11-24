//
//  SettingsStorageProtocol.swift
//  Audientia
//
//  Protocol for settings persistence
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Protocol for storing and retrieving application settings
public protocol SettingsStorageProtocol: Sendable {
    /// Save a value for a given key
    func save<T: Codable & Sendable>(_ value: T, forKey key: String) async throws
    
    /// Load a value for a given key
    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T?
    
    /// Remove a value for a given key
    func remove(forKey key: String) async throws
    
    /// Check if a key exists
    func hasValue(forKey key: String) async -> Bool
    
    /// Clear all settings
    func clearAll() async throws
}
