//
//  SettingsStorageBDDTests.swift
//  SharedTests
//
//  BDD tests for settings storage
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Shared
/// BDD tests for SettingsStorageProtocol
final class SettingsStorageBDDTests: XCTestCase {
    
    var storage: (any SettingsStorageProtocol)?
    var testUserDefaults: UserDefaults?
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.audientia.settings.bdd")
        testUserDefaults?.removePersistentDomain(forName: "test.audientia.settings.bdd")
        if let testUserDefaults = testUserDefaults {
            storage = UserDefaultsSettingsStorage(userDefaults: testUserDefaults)
        }
    }
    
    override func tearDown() {
        testUserDefaults?.removePersistentDomain(forName: "test.audientia.settings.bdd")
        storage = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsAUserIWantToSaveMyPreferencesAndHaveThemPersist() async throws {
        // Given: I have application preferences
        struct Preferences: Codable, Sendable {
            let theme: String
            let volume: Double
        }
        let preferences = Preferences(theme: "dark", volume: 0.8)
        
        // When: I save my preferences
        guard let storage = storage else {
            XCTFail("Storage not initialized")
            return
        }
        try await storage.save(preferences, forKey: "user.preferences")
        
        // Then: My preferences should be saved
        let saved = try await storage.load(Preferences.self, forKey: "user.preferences")
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.theme, "dark")
    }
    
    func testAsAUserIWantToLoadMySavedPreferencesAfterRestartingTheApp() async throws {
        // Given: I have saved preferences
        guard let storage = storage else {
            XCTFail("Storage not initialized")
            return
        }
        let preferences = ["theme": "dark", "volume": "0.8"]
        try await storage.save(preferences, forKey: "user.preferences")
        
        // When: I restart the app and load preferences
        let loaded = try await storage.load([String: String].self, forKey: "user.preferences")
        
        // Then: My preferences should be restored
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?["theme"], "dark")
    }
    
    func testAsAUserIWantToClearAllMySettings() async throws {
        // Given: I have multiple saved settings
        guard let storage = storage else {
            XCTFail("Storage not initialized")
            return
        }
        try await storage.save("value1", forKey: "setting1")
        try await storage.save("value2", forKey: "setting2")
        try await storage.save(42, forKey: "setting3")
        
        // When: I clear all settings
        try await storage.clearAll()
        
        // Then: All settings should be removed
        let hasSetting1 = await storage.hasValue(forKey: "setting1")
        let hasSetting2 = await storage.hasValue(forKey: "setting2")
        let hasSetting3 = await storage.hasValue(forKey: "setting3")
        XCTAssertFalse(hasSetting1)
        XCTAssertFalse(hasSetting2)
        XCTAssertFalse(hasSetting3)
    }
}
