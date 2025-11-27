//
//  DeviceDiscoveryService.swift
//  DataLayer
//
//  Concrete implementation of DeviceDiscoveryProtocol using mounted volumes.
//

import Foundation
import Shared

// MARK: - Mounted Volume Provider

public struct MountedVolumeInfo {
    public let id: UUID
    public let name: String
    public let path: String
    public let capacity: Int64
    public let available: Int64
    public let type: DeviceType
    public let isSystemVolume: Bool
    
    public init(
        id: UUID,
        name: String,
        path: String,
        capacity: Int64,
        available: Int64,
        type: DeviceType,
        isSystemVolume: Bool
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.capacity = capacity
        self.available = available
        self.type = type
        self.isSystemVolume = isSystemVolume
    }
}

public protocol MountedVolumeProvider {
    func mountedVolumes() -> [MountedVolumeInfo]
}

public struct FileManagerVolumeProvider: MountedVolumeProvider {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func mountedVolumes() -> [MountedVolumeInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeUUIDStringKey,
            .volumeLocalizedFormatDescriptionKey
        ]
        
        guard let urls = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else {
            return []
        }
        
        return urls.compactMap { url in
            guard let resourceValues = try? url.resourceValues(forKeys: Set(keys)),
                  let name = resourceValues.volumeName,
                  let totalCapacity = resourceValues.volumeTotalCapacity else {
                return nil
            }
            
            let availableCapacity = resourceValues.volumeAvailableCapacityForImportantUsage ??
                resourceValues.volumeAvailableCapacity.map { Int64($0) } ??
                0
            
            let uuid = UUID(uuidString: resourceValues.volumeUUIDString ?? "") ?? UUID()
            let formatDescription = resourceValues.volumeLocalizedFormatDescription?.lowercased() ?? ""
            let scheme = url.scheme?.lowercased() ?? ""
            let isInternal = resourceValues.volumeIsInternal ?? false
            let isRemovable = resourceValues.volumeIsRemovable ?? false
            
            let type: DeviceType
            if scheme == "smb" || name.lowercased().contains("smb") {
                type = .smb
            } else if formatDescription.contains("mtp") {
                type = .mtp
            } else if !isInternal || isRemovable {
                type = .usb
            } else {
                type = .usb
            }
            
            return MountedVolumeInfo(
                id: uuid,
                name: name,
                path: url.path,
                capacity: Int64(totalCapacity),
                available: Int64(availableCapacity),
                type: type,
                isSystemVolume: isInternal && !isRemovable
            )
        }
    }
}

// MARK: - Device Discovery Service

public actor DeviceDiscoveryService: DeviceDiscoveryProtocol {
    
    public struct Config {
        public var ignoredVolumeNames: Set<String>
        public var includeSystemVolumes: Bool
        public var validateWritability: Bool
        
        public init(
            ignoredVolumeNames: Set<String> = ["Macintosh HD", "Recovery"],
            includeSystemVolumes: Bool = false,
            validateWritability: Bool = true
        ) {
            self.ignoredVolumeNames = ignoredVolumeNames
            self.includeSystemVolumes = includeSystemVolumes
            self.validateWritability = validateWritability
        }
    }
    
    private let provider: MountedVolumeProvider
    private let writabilityValidator: DeviceWritabilityValidator
    private let config: Config
    
    public init(
        provider: MountedVolumeProvider = FileManagerVolumeProvider(),
        writabilityValidator: DeviceWritabilityValidator? = nil,
        config: Config = Config()
    ) {
        self.provider = provider
        self.writabilityValidator = writabilityValidator ?? DeviceWritabilityValidatorWithSpaceCheck(
            volumeProvider: provider,
            minimumRequiredSpace: 0
        )
        self.config = config
    }
    
    public func currentDevices() async -> [Device] {
        let volumes = provider
            .mountedVolumes()
            .filter { config.includeSystemVolumes || !$0.isSystemVolume }
            .filter { !config.ignoredVolumeNames.contains($0.name) }
        
        // Filter out non-writable devices if validation is enabled
        let writableVolumes: [MountedVolumeInfo]
        if config.validateWritability {
            writableVolumes = volumes.filter { volume in
                // Check available space first (quick check)
                guard volume.available > 0 else {
                    return false
                }
                // Then check actual writability
                return writabilityValidator.isWritable(path: volume.path)
            }
        } else {
            writableVolumes = volumes
        }
        
        return writableVolumes.map {
            Device(
                id: $0.id,
                name: $0.name,
                type: $0.type,
                capacity: max(0, $0.capacity),
                availableSpace: max(0, $0.available),
                mountPath: $0.path,
                status: .ready
            )
        }
    }
}
