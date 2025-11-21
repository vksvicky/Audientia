//
//  USBDeviceConnector.swift
//  DataLayer
//
//  USB device connector for direct USB mass storage device access
//

import Foundation
import Shared

/// USB-specific connector that handles USB mass storage devices
/// Uses the same file system approach as LocalDeviceConnector but with USB-specific optimizations
public actor USBDeviceConnector: DeviceConnectorProtocol {
    
    private let baseConnector: LocalDeviceConnector
    
    public init(fileManager: FileManager = .default) {
        // USB devices are mounted as regular file systems on macOS
        // We can use LocalDeviceConnector as the base implementation
        self.baseConnector = LocalDeviceConnector(fileManager: fileManager)
    }
    
    public func fetchDeviceTracks(device: Device) async throws -> [DeviceTrackSnapshot] {
        // USB devices are handled the same way as local devices
        try await baseConnector.fetchDeviceTracks(device: device)
    }
    
    public func transfer(
        tracks: [Track],
        to device: Device,
        jobId: UUID,
        options: SyncOptions,
        progress: @escaping (SyncProgress) -> Void
    ) async throws {
        // USB transfer uses standard file system operations
        // Add USB-specific optimizations here (e.g., batch writes, write caching)
        try await baseConnector.transfer(
            tracks: tracks,
            to: device,
            jobId: jobId,
            options: options,
            progress: progress
        )
    }
    
    public func cancel(jobId: UUID) async {
        await baseConnector.cancel(jobId: jobId)
    }
}
