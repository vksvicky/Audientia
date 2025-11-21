//
//  DeviceConfigurationStorageBDDTests.swift
//  DataLayerTests
//
//  BDD tests for DeviceConfigurationStorage
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceConfigurationStorageBDDTests: XCTestCase {
    
    private var storage: UserDefaultsDeviceConfigurationStorage!
    private var testDefaults: UserDefaults!
    
    override func setUp() async throws {
        guard let defaults = UserDefaults(suiteName: "test.audientia.device.config.bdd") else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        testDefaults = defaults
        testDefaults.removePersistentDomain(forName: "test.audientia.device.config.bdd")
        storage = UserDefaultsDeviceConfigurationStorage(userDefaults: testDefaults)
    }
    
    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "test.audientia.device.config.bdd")
        storage = nil
    }
    
    func testGivenNewDeviceWhenSavingConfigurationThenConfigurationIsPersisted() async throws {
        // Scenario: As a user, I want to save device-specific sync settings
        // Given: A new device with no saved configuration
        let deviceId = UUID()
        let config = DeviceConfiguration(
            enforceFreeSpace: true,
            autoResolveConflicts: true,
            conflictStrategy: .keepNewer,
            folderStructure: .artistAlbum
        )
        
        // When: I save the configuration
        try await storage.saveConfiguration(config, for: deviceId)
        
        // Then: The configuration should be persisted and retrievable
        let loaded = await storage.loadConfiguration(for: deviceId)
        XCTAssertNotNil(loaded, "Configuration should be saved")
        XCTAssertEqual(loaded?.enforceFreeSpace, true)
        XCTAssertEqual(loaded?.autoResolveConflicts, true)
        XCTAssertEqual(loaded?.conflictStrategy, .keepNewer)
        XCTAssertEqual(loaded?.folderStructure, .artistAlbum)
    }
    
    func testGivenSavedConfigurationWhenLoadingConfigurationThenSettingsAreRestored() async throws {
        // Scenario: As a user, I want my device settings to persist across app restarts
        // Given: A device with a saved configuration
        let deviceId = UUID()
        let originalConfig = DeviceConfiguration(
            enforceFreeSpace: false,
            autoResolveConflicts: true,
            conflictStrategy: .keepLarger,
            syncDirection: .bidirectional,
            folderStructure: .genreArtistAlbum,
            transcodeIfNeeded: true,
            targetFormat: .aac,
            targetBitrate: 256
        )
        try await storage.saveConfiguration(originalConfig, for: deviceId)
        
        // When: I load the configuration (simulating app restart)
        let loaded = await storage.loadConfiguration(for: deviceId)
        
        // Then: All settings should be restored exactly as saved
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.enforceFreeSpace, false)
        XCTAssertEqual(loaded?.autoResolveConflicts, true)
        XCTAssertEqual(loaded?.conflictStrategy, .keepLarger)
        XCTAssertEqual(loaded?.syncDirection, .bidirectional)
        XCTAssertEqual(loaded?.folderStructure, .genreArtistAlbum)
        XCTAssertEqual(loaded?.transcodeIfNeeded, true)
        XCTAssertEqual(loaded?.targetFormat, .aac)
        XCTAssertEqual(loaded?.targetBitrate, 256)
    }
    
    func testGivenMultipleDevicesWhenSavingConfigurationsThenEachDeviceHasIndependentSettings() async throws {
        // Scenario: As a user with multiple devices, I want different sync settings for each device
        // Given: Two different devices
        let usbDeviceId = UUID()
        let mtpDeviceId = UUID()
        let usbConfig = DeviceConfiguration(
            enforceFreeSpace: true,
            folderStructure: .artistAlbum
        )
        let mtpConfig = DeviceConfiguration(
            enforceFreeSpace: false,
            folderStructure: .flat
        )
        
        // When: I save different configurations for each device
        try await storage.saveConfiguration(usbConfig, for: usbDeviceId)
        try await storage.saveConfiguration(mtpConfig, for: mtpDeviceId)
        
        // Then: Each device should have its own independent configuration
        let loadedUSB = await storage.loadConfiguration(for: usbDeviceId)
        let loadedMTP = await storage.loadConfiguration(for: mtpDeviceId)
        
        XCTAssertEqual(loadedUSB?.enforceFreeSpace, true, "USB device should have its own settings")
        XCTAssertEqual(loadedUSB?.folderStructure, .artistAlbum)
        XCTAssertEqual(loadedMTP?.enforceFreeSpace, false, "MTP device should have its own settings")
        XCTAssertEqual(loadedMTP?.folderStructure, .flat)
        XCTAssertNotEqual(loadedUSB, loadedMTP, "Configurations should be different")
    }
    
    func testGivenExistingConfigurationWhenUpdatingSettingsThenNewSettingsReplaceOldOnes() async throws {
        // Scenario: As a user, I want to update my device sync settings
        // Given: A device with an existing configuration
        let deviceId = UUID()
        let oldConfig = DeviceConfiguration(
            enforceFreeSpace: true,
            conflictStrategy: .keepLibrary,
            folderStructure: .artistAlbum
        )
        try await storage.saveConfiguration(oldConfig, for: deviceId)
        
        // When: I update the configuration with new settings
        let newConfig = DeviceConfiguration(
            enforceFreeSpace: false,
            conflictStrategy: .keepNewer,
            folderStructure: .flat
        )
        try await storage.saveConfiguration(newConfig, for: deviceId)
        
        // Then: The new settings should replace the old ones
        let loaded = await storage.loadConfiguration(for: deviceId)
        XCTAssertEqual(loaded?.enforceFreeSpace, false, "New setting should replace old")
        XCTAssertEqual(loaded?.conflictStrategy, .keepNewer, "New strategy should replace old")
        XCTAssertEqual(loaded?.folderStructure, .flat, "New structure should replace old")
        XCTAssertNotEqual(loaded?.enforceFreeSpace, oldConfig.enforceFreeSpace)
    }
    
    func testGivenNoSavedConfigurationWhenLoadingConfigurationThenNilIsReturned() async {
        // Scenario: As a user with a new device, I should get default settings when no configuration exists
        // Given: A device with no saved configuration
        let deviceId = UUID()
        
        // When: I try to load the configuration
        let loaded = await storage.loadConfiguration(for: deviceId)
        
        // Then: nil should be returned (indicating no saved configuration)
        XCTAssertNil(loaded, "Loading non-existent configuration should return nil")
    }
    
    func testGivenSavedConfigurationWhenDeletingConfigurationThenConfigurationIsRemoved() async throws {
        // Scenario: As a user, I want to reset my device settings to defaults
        // Given: A device with a saved configuration
        let deviceId = UUID()
        let config = DeviceConfiguration(enforceFreeSpace: true)
        try await storage.saveConfiguration(config, for: deviceId)
        
        // When: I delete the configuration
        try await storage.deleteConfiguration(for: deviceId)
        
        // Then: The configuration should no longer be available
        let loaded = await storage.loadConfiguration(for: deviceId)
        XCTAssertNil(loaded, "Deleted configuration should not be loadable")
    }
    
    func testGivenConfigurationWhenConvertingToSyncOptionsThenOptionsMatchConfiguration() async throws {
        // Scenario: As a user, I want my saved configuration to be used when creating sync requests
        // Given: A device configuration
        let config = DeviceConfiguration(
            enforceFreeSpace: true,
            autoResolveConflicts: true
        )
        
        // When: Converting to SyncOptions
        let options = config.toSyncOptions()
        
        // Then: The SyncOptions should match the configuration values
        XCTAssertEqual(options.enforceFreeSpace, config.enforceFreeSpace, "SyncOptions should match configuration")
        XCTAssertEqual(options.autoResolveConflicts, config.autoResolveConflicts, "SyncOptions should match configuration")
    }
}
