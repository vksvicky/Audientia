//
//  MockSettingsStorage.swift
//  SharedTests
//
//  Shared mock implementation of SettingsStorageProtocol for testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Mock settings storage for testing
actor MockSettingsStorage: SettingsStorageProtocol {
    private var storage: [String: Data] = [:]
    private var shouldThrowError = false
    private var errorToThrow: Error?
    
    func setShouldThrowError(_ shouldThrow: Bool, error: Error? = nil) {
        shouldThrowError = shouldThrow
        errorToThrow = error
    }
    
    func clearStorage() {
        storage.removeAll()
    }
    
    func save<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "TestError", code: 1)
        }
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        storage[key] = data
    }
    
    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "TestError", code: 1)
        }
        guard let data = storage[key] else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    func remove(forKey key: String) async throws {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "TestError", code: 1)
        }
        storage.removeValue(forKey: key)
    }
    
    func hasValue(forKey key: String) async -> Bool {
        storage[key] != nil
    }
    
    func clearAll() async throws {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "TestError", code: 1)
        }
        storage.removeAll()
    }
}
