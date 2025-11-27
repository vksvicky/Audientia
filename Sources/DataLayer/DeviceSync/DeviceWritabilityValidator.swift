//
//  DeviceWritabilityValidator.swift
//  DataLayer
//
//  Validates that a mounted device is writable before including it in device discovery.
//

import Foundation

/// Protocol for validating device writability
public protocol DeviceWritabilityValidator {
    /// Checks if a device at the given path is writable
    /// - Parameter path: The mount path of the device
    /// - Returns: `true` if the device is writable, `false` otherwise
    func isWritable(path: String) -> Bool
}

/// Default implementation that checks writability by attempting to write a test file
public struct DefaultDeviceWritabilityValidator: DeviceWritabilityValidator {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func isWritable(path: String) -> Bool {
        // Check if path exists and is accessible
        guard fileManager.fileExists(atPath: path) else {
            return false
        }
        
        // Check if we can write to the directory
        // Try to create a test file to verify writability
        let testFileName = ".audientia_writability_test_\(UUID().uuidString)"
        let testFilePath = (path as NSString).appendingPathComponent(testFileName)
        
        // Attempt to write an empty file
        let testData = Data()
        let success = fileManager.createFile(
            atPath: testFilePath,
            contents: testData,
            attributes: nil
        )
        
        // Clean up test file if it was created
        if success {
            try? fileManager.removeItem(atPath: testFilePath)
        }
        
        return success
    }
}

/// Validator that also checks available space
public struct DeviceWritabilityValidatorWithSpaceCheck: DeviceWritabilityValidator {
    private let baseValidator: DeviceWritabilityValidator
    private let volumeProvider: MountedVolumeProvider
    private let minimumRequiredSpace: Int64
    
    public init(
        baseValidator: DeviceWritabilityValidator = DefaultDeviceWritabilityValidator(),
        volumeProvider: MountedVolumeProvider,
        minimumRequiredSpace: Int64 = 0
    ) {
        self.baseValidator = baseValidator
        self.volumeProvider = volumeProvider
        self.minimumRequiredSpace = minimumRequiredSpace
    }
    
    public func isWritable(path: String) -> Bool {
        // First check basic writability
        guard baseValidator.isWritable(path: path) else {
            return false
        }
        
        // Check if device has sufficient available space
        let volumes = volumeProvider.mountedVolumes()
        guard let volume = volumes.first(where: { $0.path == path }) else {
            return false
        }
        
        // Device must have available space greater than minimum required
        // (0 available space means device is full/read-only)
        guard volume.available > 0 else {
            return false
        }
        
        return volume.available >= minimumRequiredSpace
    }
}
