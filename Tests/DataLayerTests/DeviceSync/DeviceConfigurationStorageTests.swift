//
//  DeviceConfigurationStorageTests.swift
//  DataLayerTests
//
//  TDD tests for DeviceConfigurationStorage (Right-BICEP)
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceConfigurationStorageTests: XCTestCase {
    
    private var storage: UserDefaultsDeviceConfigurationStorage!
    private var testDefaults: UserDefaults!
    private var deviceId: UUID!
    
    override func setUp() async throws {
        guard let defaults = UserDefaults(suiteName: "test.audientia.device.config") else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        testDefaults = defaults
        testDefaults.removePersistentDomain(forName: "test.audientia.device.config")
        storage = UserDefaultsDeviceConfigurationStorage(userDefaults: testDefaults)
        deviceId = UUID()
    }
    
    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "test.audientia.device.config")
        storage = nil
        deviceId = nil
    }
    
    // MARK: - [Right] Results Right
    
    func testSaveAndLoadConfiguration() async throws {
        // Given: A device configuration
        let config = DeviceConfiguration(
            enforceFreeSpace: true,
            autoResolveConflicts: true,
            conflictStrategy: .keepNewer,
            syncDirection: .bidirectional,
            createFolderStructure: true,
            folderStructure: .genreArtistAlbum,
            transcodeIfNeeded: true,
            targetFormat: .aac,
            targetBitrate: 256
        )
        
        // When: Saving and loading the configuration
        try await storage.saveConfiguration(config, for: deviceId)
        let loaded = await storage.loadConfiguration(for: deviceId)
        
        // Then: The loaded configuration should match
        XCTAssertEqual(loaded, config, "Loaded configuration should match saved configuration")
    }
    
    func testLoadNonExistentConfigurationReturnsNil() async {
        // Given: No saved configuration for a device
        let newDeviceId = UUID()
        
        // When: Loading configuration
        let loaded = await storage.loadConfiguration(for: newDeviceId)
        
        // Then: Should return nil
        XCTAssertNil(loaded, "Loading non-existent configuration should return nil")
    }
    
    // MARK: - [B] Boundary Conditions
    
    func testSaveConfigurationWithDefaultValues() async throws {
        // Given: A configuration with all default values
        let config = DeviceConfiguration()
        
        // When: Saving and loading
        try await storage.saveConfiguration(config, for: deviceId)
        let loaded = await storage.loadConfiguration(for: deviceId)
        
        // Then: Should preserve all default values
        XCTAssertEqual(loaded, config)
        XCTAssertEqual(loaded?.enforceFreeSpace, true)
        XCTAssertEqual(loaded?.autoResolveConflicts, false)
        XCTAssertEqual(loaded?.conflictStrategy, .keepLibrary)
    }
    
    func testSaveConfigurationWithAllValuesChanged() async throws {
        // Given: A configuration with all values changed
        let config = DeviceConfiguration(
            enforceFreeSpace: false,
            autoResolveConflicts: true,
            conflictStrategy: .keepLarger,
            syncDirection: .deviceToDesktop,
            createFolderStructure: false,
            folderStructure: .flat,
            transcodeIfNeeded: true,
            targetFormat: .flac,
            targetBitrate: 320
        )
        
        // When: Saving and loading
        try await storage.saveConfiguration(config, for: deviceId)
        let loaded = await storage.loadConfiguration(for: deviceId)
        
        // Then: All values should be preserved
        XCTAssertEqual(loaded, config)
    }
    
    func testMultipleDevicesHaveIndependentConfigurations() async throws {
        // Given: Two devices with different configurations
        let deviceId1 = UUID()
        let deviceId2 = UUID()
        let config1 = DeviceConfiguration(
            enforceFreeSpace: true,
            conflictStrategy: .keepLibrary,
            folderStructure: .artistAlbum
        )
        let config2 = DeviceConfiguration(
            enforceFreeSpace: false,
            conflictStrategy: .keepNewer,
            folderStructure: .flat
        )
        
        // When: Saving both configurations
        try await storage.saveConfiguration(config1, for: deviceId1)
        try await storage.saveConfiguration(config2, for: deviceId2)
        
        // Then: Each device should have its own configuration
        let loaded1 = await storage.loadConfiguration(for: deviceId1)
        let loaded2 = await storage.loadConfiguration(for: deviceId2)
        
        XCTAssertEqual(loaded1, config1, "Device 1 should have its own configuration")
        XCTAssertEqual(loaded2, config2, "Device 2 should have its own configuration")
        XCTAssertNotEqual(loaded1, loaded2, "Configurations should be different")
    }
    
    // MARK: - [I] Inverse Relationships
    
    func testDeleteConfigurationRemovesSavedConfiguration() async throws {
        // Given: A saved configuration
        let config = DeviceConfiguration(enforceFreeSpace: true)
        try await storage.saveConfiguration(config, for: deviceId)
        
        // When: Deleting the configuration
        try await storage.deleteConfiguration(for: deviceId)
        
        // Then: Loading should return nil
        let loaded = await storage.loadConfiguration(for: deviceId)
        XCTAssertNil(loaded, "Deleted configuration should not be loadable")
    }
    
    func testOverwriteConfigurationReplacesPrevious() async throws {
        // Given: A saved configuration
        let config1 = DeviceConfiguration(
            enforceFreeSpace: true,
            conflictStrategy: .keepLibrary
        )
        try await storage.saveConfiguration(config1, for: deviceId)
        
        // When: Saving a different configuration for the same device
        let config2 = DeviceConfiguration(
            enforceFreeSpace: false,
            conflictStrategy: .keepNewer
        )
        try await storage.saveConfiguration(config2, for: deviceId)
        
        // Then: The new configuration should replace the old one
        let loaded = await storage.loadConfiguration(for: deviceId)
        XCTAssertEqual(loaded, config2, "New configuration should replace old one")
        XCTAssertNotEqual(loaded, config1, "Old configuration should be gone")
    }
    
    // MARK: - [C] Cross-Checking
    
    func testToSyncOptionsConversion() {
        // Given: A device configuration
        let config = DeviceConfiguration(
            enforceFreeSpace: true,
            autoResolveConflicts: true
        )
        
        // When: Converting to SyncOptions
        let options = config.toSyncOptions()
        
        // Then: SyncOptions should match configuration values
        XCTAssertEqual(options.enforceFreeSpace, config.enforceFreeSpace)
        XCTAssertEqual(options.autoResolveConflicts, config.autoResolveConflicts)
    }
    
    // MARK: - [E] Error Conditions
    
    func testDeleteNonExistentConfigurationDoesNotThrow() async throws {
        // Given: No saved configuration
        let newDeviceId = UUID()
        
        // When: Deleting non-existent configuration
        // Then: Should not throw
        try await storage.deleteConfiguration(for: newDeviceId)
    }
    
    // MARK: - [P] Performance
    
    func testSaveAndLoadPerformance() async throws {
        // Given: A configuration
        let config = DeviceConfiguration()
        
        // When: Measuring save/load performance
        measure {
            Task {
                try? await storage.saveConfiguration(config, for: deviceId)
                _ = await storage.loadConfiguration(for: deviceId)
            }
        }
    }
}
