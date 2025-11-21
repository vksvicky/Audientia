//
//  DeviceConfigurationStorage.swift
//  DataLayer
//
//  Protocol and implementation for persisting device configuration
//

import Foundation
import Shared

/// Protocol for storing and retrieving device configuration
public protocol DeviceConfigurationStorageProtocol: Sendable {
    func saveConfiguration(_ config: DeviceConfiguration, for deviceId: UUID) async throws
    func loadConfiguration(for deviceId: UUID) async -> DeviceConfiguration?
    func deleteConfiguration(for deviceId: UUID) async throws
}

/// Device configuration model matching the ViewModel's state
public struct DeviceConfiguration: Codable, Equatable, Sendable {
    public var enforceFreeSpace: Bool
    public var autoResolveConflicts: Bool
    public var conflictStrategy: ConflictResolutionStrategy
    public var syncDirection: SyncDirection
    public var createFolderStructure: Bool
    public var folderStructure: FolderStructure
    public var transcodeIfNeeded: Bool
    public var targetFormat: AudioFormat
    public var targetBitrate: Int
    
    public init(
        enforceFreeSpace: Bool = true,
        autoResolveConflicts: Bool = false,
        conflictStrategy: ConflictResolutionStrategy = .keepLibrary,
        syncDirection: SyncDirection = .desktopToDevice,
        createFolderStructure: Bool = true,
        folderStructure: FolderStructure = .artistAlbum,
        transcodeIfNeeded: Bool = false,
        targetFormat: AudioFormat = .mp3,
        targetBitrate: Int = 192
    ) {
        self.enforceFreeSpace = enforceFreeSpace
        self.autoResolveConflicts = autoResolveConflicts
        self.conflictStrategy = conflictStrategy
        self.syncDirection = syncDirection
        self.createFolderStructure = createFolderStructure
        self.folderStructure = folderStructure
        self.transcodeIfNeeded = transcodeIfNeeded
        self.targetFormat = targetFormat
        self.targetBitrate = targetBitrate
    }
    
    /// Convert to SyncOptions for use in SyncRequest
    public func toSyncOptions() -> SyncOptions {
        SyncOptions(
            autoResolveConflicts: autoResolveConflicts,
            verifyChecksums: false, // Can be added to config if needed
            enforceFreeSpace: enforceFreeSpace,
            deleteMissingFromDevice: false, // Can be added to config if needed
            createFolderStructure: createFolderStructure,
            folderStructure: folderStructure
        )
    }
}

/// UserDefaults-based implementation
/// Uses actor isolation to ensure thread-safe access to UserDefaults
public actor UserDefaultsDeviceConfigurationStorage: DeviceConfigurationStorageProtocol {
    private let userDefaults: UserDefaults
    private let keyPrefix = "audientia.device.config."
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    private func key(for deviceId: UUID) -> String {
        "\(keyPrefix)\(deviceId.uuidString)"
    }
    
    public func saveConfiguration(_ config: DeviceConfiguration, for deviceId: UUID) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        userDefaults.set(data, forKey: key(for: deviceId))
    }
    
    public func loadConfiguration(for deviceId: UUID) async -> DeviceConfiguration? {
        guard let data = userDefaults.data(forKey: key(for: deviceId)) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(DeviceConfiguration.self, from: data)
    }
    
    public func deleteConfiguration(for deviceId: UUID) async throws {
        userDefaults.removeObject(forKey: key(for: deviceId))
    }
}

// Types are defined in Shared/Models/DeviceSyncModels.swift
