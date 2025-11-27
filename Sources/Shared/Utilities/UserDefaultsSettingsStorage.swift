//
//  UserDefaultsSettingsStorage.swift
//  Audientia
//
//  UserDefaults-based implementation of SettingsStorageProtocol
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log

/// UserDefaults-based implementation of SettingsStorageProtocol
/// Uses actor isolation to ensure thread-safe access to UserDefaults
public actor UserDefaultsSettingsStorage: SettingsStorageProtocol {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    
    public init(userDefaults: UserDefaults = .standard, keyPrefix: String = "audientia.settings.") {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }
    
    private func fullKey(for key: String) -> String {
        "\(keyPrefix)\(key)"
    }
    
    public func save<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        userDefaults.set(data, forKey: fullKey(for: key))
    }
    
    public func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard let data = userDefaults.data(forKey: fullKey(for: key)) else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            Logger.shared.error(
                "Failed to decode type \(String(describing: type)) for key \(key): \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    public func remove(forKey key: String) async throws {
        userDefaults.removeObject(forKey: fullKey(for: key))
    }
    
    public func hasValue(forKey key: String) async -> Bool {
        userDefaults.data(forKey: fullKey(for: key)) != nil
    }
    
    public func clearAll() async throws {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }
}
