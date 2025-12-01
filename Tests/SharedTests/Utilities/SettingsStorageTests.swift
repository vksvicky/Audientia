//
//  SettingsStorageTests.swift
//  SharedTests
//
//  TDD tests for settings storage following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared
/// TDD tests for SettingsStorageProtocol
/// Right-BICEP: Right results, Boundary conditions, Inverse relationships, Cross-checking, Error conditions, Performance
final class SettingsStorageTests: XCTestCase {
    
    var storage: (any SettingsStorageProtocol)?
    var testUserDefaults: UserDefaults?
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.audientia.settings")
        testUserDefaults?.removePersistentDomain(forName: "test.audientia.settings")
        if let testUserDefaults = testUserDefaults {
            storage = UserDefaultsSettingsStorage(userDefaults: testUserDefaults)
        }
    }
    
    override func tearDown() {
        testUserDefaults?.removePersistentDomain(forName: "test.audientia.settings")
        storage = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Helper
    
    private func requireStorage() throws -> any SettingsStorageProtocol {
        guard let storage = storage else {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage not initialised"])
        }
        return storage
    }
    
    // MARK: - Right Results
    
    func testSaveAndLoadString() async throws {
        let storage = try requireStorage()
        // Given: A string value
        let value = "test value"
        let key = "test.string"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Value should match
        XCTAssertEqual(loaded, value)
    }
    
    func testSaveAndLoadInt() async throws {
        let storage = try requireStorage()
        // Given: An integer value
        let value = 42
        let key = "test.int"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(Int.self, forKey: key)
        
        // Then: Value should match
        XCTAssertEqual(loaded, value)
    }
    
    func testSaveAndLoadBool() async throws {
        let storage = try requireStorage()
        // Given: A boolean value
        let value = true
        let key = "test.bool"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(Bool.self, forKey: key)
        
        // Then: Value should match
        XCTAssertEqual(loaded, value)
    }
    
    func testSaveAndLoadCodableStruct() async throws {
        let storage = try requireStorage()
        // Given: A codable struct
        struct TestStruct: Codable, Equatable, Sendable {
            let name: String
            let count: Int
        }
        let value = TestStruct(name: "test", count: 5)
        let key = "test.struct"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(TestStruct.self, forKey: key)
        
        // Then: Value should match
        XCTAssertEqual(loaded, value)
    }
    
    // MARK: - Boundary Conditions
    
    func testLoadNonExistentKey() async throws {
        let storage = try requireStorage()
        // Given: A non-existent key
        let key = "test.nonexistent"
        
        // When: Loading
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Should return nil
        XCTAssertNil(loaded)
    }
    
    func testSaveEmptyString() async throws {
        let storage = try requireStorage()
        // Given: An empty string
        let value = ""
        let key = "test.empty"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Should preserve empty string
        XCTAssertEqual(loaded, value)
    }
    
    func testSaveVeryLongString() async throws {
        let storage = try requireStorage()
        // Given: A very long string
        let value = String(repeating: "a", count: 10000)
        let key = "test.long"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Should preserve long string
        XCTAssertEqual(loaded, value)
    }
    
    func testSaveZeroValue() async throws {
        let storage = try requireStorage()
        // Given: Zero value
        let value = 0
        let key = "test.zero"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(Int.self, forKey: key)
        
        // Then: Should preserve zero
        XCTAssertEqual(loaded, value)
    }
    
    // MARK: - Inverse Relationships
    
    func testSaveRemoveRoundtrip() async throws {
        let storage = try requireStorage()
        // Given: A saved value
        let value = "test"
        let key = "test.roundtrip"
        try await storage.save(value, forKey: key)
        
        // When: Removing and checking existence
        try await storage.remove(forKey: key)
        let exists = await storage.hasValue(forKey: key)
        
        // Then: Should not exist
        XCTAssertFalse(exists)
    }
    
    func testSaveOverwrite() async throws {
        let storage = try requireStorage()
        // Given: An existing value
        let key = "test.overwrite"
        try await storage.save("original", forKey: key)
        
        // When: Saving a new value
        try await storage.save("updated", forKey: key)
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Should have new value
        XCTAssertEqual(loaded, "updated")
    }
    
    // MARK: - Cross-Checking
    
    func testHasValueAfterSave() async throws {
        let storage = try requireStorage()
        // Given: A saved value
        let key = "test.exists"
        try await storage.save("test", forKey: key)
        
        // When: Checking existence
        let exists = await storage.hasValue(forKey: key)
        
        // Then: Should exist
        XCTAssertTrue(exists)
    }
    
    func testHasValueBeforeSave() async throws {
        let storage = try requireStorage()
        // Given: A non-existent key
        let key = "test.notexists"
        
        // When: Checking existence
        let exists = await storage.hasValue(forKey: key)
        
        // Then: Should not exist
        XCTAssertFalse(exists)
    }
    
    // MARK: - Error Conditions
    
    func testLoadWrongType() async throws {
        let storage = try requireStorage()
        // Given: A saved integer
        let key = "test.wrongtype"
        try await storage.save(42, forKey: key)
        
        // When: Loading as string
        // Then: Should throw or return nil
        let loaded = try await storage.load(String.self, forKey: key)
        XCTAssertNil(loaded)
    }
    
    func testClearAll() async throws {
        let storage = try requireStorage()
        // Given: Multiple saved values
        try await storage.save("value1", forKey: "test.key1")
        try await storage.save("value2", forKey: "test.key2")
        try await storage.save(42, forKey: "test.key3")
        
        // When: Clearing all
        try await storage.clearAll()
        
        // Then: All should be removed
        let hasKey1 = await storage.hasValue(forKey: "test.key1")
        let hasKey2 = await storage.hasValue(forKey: "test.key2")
        let hasKey3 = await storage.hasValue(forKey: "test.key3")
        XCTAssertFalse(hasKey1)
        XCTAssertFalse(hasKey2)
        XCTAssertFalse(hasKey3)
    }
    
    // MARK: - Performance
    
    func testSavePerformance() async throws {
        let storage = try requireStorage()
        measure {
            Task {
                for i in 0..<100 {
                    try? await storage.save("value\(i)", forKey: "test.perf.\(i)")
                }
            }
        }
    }
    
    func testLoadPerformance() async throws {
        let storage = try requireStorage()
        // Given: Pre-saved values
        for i in 0..<100 {
            try await storage.save("value\(i)", forKey: "test.perf.\(i)")
        }
        
        // When: Loading all
        measure {
            Task {
                for i in 0..<100 {
                    _ = try? await storage.load(String.self, forKey: "test.perf.\(i)")
                }
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testUnicodeKeys() async throws {
        let storage = try requireStorage()
        // Given: Unicode key and value
        let key = "test.测试.🎵"
        let value = "测试值 🎵"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Should preserve Unicode
        XCTAssertEqual(loaded, value)
    }
    
    func testSpecialCharactersInValue() async throws {
        let storage = try requireStorage()
        // Given: Value with special characters
        let value = "test\n\t\"quotes\" & <tags>"
        let key = "test.special"
        
        // When: Saving and loading
        try await storage.save(value, forKey: key)
        let loaded = try await storage.load(String.self, forKey: key)
        
        // Then: Should preserve special characters
        XCTAssertEqual(loaded, value)
    }
    
    func testConcurrentSaves() async throws {
        let storage = try requireStorage()
        // Given: Multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    try? await storage.save("value\(i)", forKey: "test.concurrent.\(i)")
                }
            }
        }
        
        // Then: All should be saved
        for i in 0..<10 {
            let exists = await storage.hasValue(forKey: "test.concurrent.\(i)")
            XCTAssertTrue(exists, "Key test.concurrent.\(i) should exist")
        }
    }
}
