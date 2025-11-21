//
//  SMBDeviceConnector.swift
//  DataLayer
//
//  SMB (Server Message Block) network share connector
//  Uses macOS built-in SMB support via mounted network volumes
//

import Foundation
import Shared

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// SMB device connector for network shares
/// Uses macOS mounted SMB volumes (same as local file system)
public actor SMBDeviceConnector: DeviceConnectorProtocol {
    
    private let baseConnector: LocalDeviceConnector
    
    public init(fileManager: FileManager = .default) {
        // SMB shares are mounted as regular file systems on macOS
        // We can use LocalDeviceConnector as the base implementation
        self.baseConnector = LocalDeviceConnector(fileManager: fileManager)
    }
    
    public func fetchDeviceTracks(device: Device) async throws -> [DeviceTrackSnapshot] {
        // SMB devices are handled the same way as local devices
        // Add SMB-specific error handling for network issues
        do {
            return try await baseConnector.fetchDeviceTracks(device: device)
        } catch {
            // Map network errors to DeviceSyncError
            if let nsError = error as NSError?,
               nsError.domain == NSPOSIXErrorDomain,
               nsError.code == ENETDOWN || nsError.code == ENETUNREACH {
                throw DeviceSyncError.deviceNotFound
            }
            throw error
        }
    }
    
    public func transfer(
        tracks: [Track],
        to device: Device,
        jobId: UUID,
        options: SyncOptions,
        progress: @escaping (SyncProgress) -> Void
    ) async throws {
        // SMB transfer uses standard file system operations
        // Add SMB-specific optimizations:
        // - Network retry logic
        // - Bandwidth throttling
        // - Connection monitoring
        
        do {
            try await baseConnector.transfer(
                tracks: tracks,
                to: device,
                jobId: jobId,
                options: options,
                progress: progress
            )
        } catch {
            // Map network errors to DeviceSyncError
            if let nsError = error as NSError?,
               nsError.domain == NSPOSIXErrorDomain {
                let errorCode = Int(nsError.code)
                switch errorCode {
                case Int(ENETDOWN), Int(ENETUNREACH):
                    throw DeviceSyncError.deviceNotFound
                case Int(ENOSPC):
                    throw DeviceSyncError.insufficientSpace
                default:
                    throw DeviceSyncError.deviceNotFound
                }
            }
            throw error
        }
    }
    
    public func cancel(jobId: UUID) async {
        await baseConnector.cancel(jobId: jobId)
    }
}
