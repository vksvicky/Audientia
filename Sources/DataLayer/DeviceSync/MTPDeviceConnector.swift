//
//  MTPDeviceConnector.swift
//  DataLayer
//
//  MTP (Media Transfer Protocol) device connector
//  Uses MTPProtocol abstraction for testability and future libmtp integration
//

import Foundation
import Shared

/// MTP device connector for Android devices and other MTP-compatible devices
/// Uses MTPProtocol abstraction to allow testing without requiring libmtp
public actor MTPDeviceConnector: DeviceConnectorProtocol {
    
    private let mtpProtocol: MTPProtocol
    private let folderBuilder: FolderStructureBuilderProtocol
    private var cancelledJobs: Set<UUID> = []
    private var activeTransfers: [UUID: Task<Void, Never>] = [:]
    
    public init(
        mtpProtocol: MTPProtocol? = nil,
        folderBuilder: FolderStructureBuilderProtocol = FolderStructureBuilder()
    ) {
        // MTPDeviceConnector uses MTPProtocol abstraction for testability
        // - MockMTPProtocol is used for testing (comprehensive TDD/BDD coverage)
        // - RealMTPProtocol can be implemented later using libmtp for production
        //   This allows full test coverage without requiring libmtp integration
        if let mtpProtocol = mtpProtocol {
            self.mtpProtocol = mtpProtocol
        } else {
            // Production implementation would create RealMTPProtocol here
            // For now, require injection for testability and future libmtp integration
            fatalError(
                "MTPDeviceConnector requires MTPProtocol implementation. " +
                "Use MockMTPProtocol for testing or implement RealMTPProtocol with libmtp for production."
            )
        }
        self.folderBuilder = folderBuilder
    }
    
    public func fetchDeviceTracks(device: Device) async throws -> [DeviceTrackSnapshot] {
        // Connect to device
        do {
            guard try await mtpProtocol.connect(deviceId: device.id.uuidString) else {
                throw DeviceSyncError.deviceNotFound
            }
        } catch {
            throw DeviceSyncError.deviceNotFound
        }
        
        defer {
            Task {
                try? await mtpProtocol.disconnect()
            }
        }
        
        // List files on device
        let filePaths = try await mtpProtocol.listFiles()
        
        // Convert to DeviceTrackSnapshot
        var snapshots: [DeviceTrackSnapshot] = []
        for path in filePaths {
            do {
                let metadata = try await mtpProtocol.getFileMetadata(path: path)
                
                // Parse track from path (simplified - real implementation would read MTP metadata)
                let track = Track(
                    title: (path as NSString).lastPathComponent,
                    artist: "Unknown",
                    album: "Unknown",
                    duration: 0,
                    filePath: path,
                    fileSize: metadata.size,
                    bitrate: 0,
                    sampleRate: 0
                )
                
                snapshots.append(DeviceTrackSnapshot(
                    track: track,
                    relativePath: path,
                    libraryChecksum: nil,
                    deviceChecksum: nil,
                    isPresentOnDevice: true
                ))
            } catch {
                // Skip files that can't be read
                continue
            }
        }
        
        return snapshots
    }
    
    public func transfer(
        tracks: [Track],
        to device: Device,
        jobId: UUID,
        options: SyncOptions,
        progress: @escaping (SyncProgress) -> Void
    ) async throws {
        guard !cancelledJobs.contains(jobId) else {
            throw CancellationError()
        }
        
        // Connect to device
        guard try await mtpProtocol.connect(deviceId: device.id.uuidString) else {
            throw DeviceSyncError.deviceNotFound
        }
        
        defer {
            Task {
                try? await mtpProtocol.disconnect()
            }
            cancelledJobs.remove(jobId)
            activeTransfers.removeValue(forKey: jobId)
        }
        
        let total = tracks.count
        var completed = 0
        
        for track in tracks {
            if cancelledJobs.contains(jobId) {
                await mtpProtocol.cancel()
                throw CancellationError()
            }
            
            let devicePath = try await buildDevicePath(for: track, options: options)
            try await uploadTrack(
                track: track,
                devicePath: devicePath,
                total: total,
                completed: &completed,
                progress: progress
            )
        }
    }
    
    private func buildDevicePath(for track: Track, options: SyncOptions) async throws -> String {
        if options.createFolderStructure {
            let folderPath = folderBuilder.buildPath(for: track, structure: options.folderStructure)
            let directoryPath = (folderPath as NSString).deletingLastPathComponent
            
            // Create directory structure
            if !directoryPath.isEmpty {
                try await mtpProtocol.createDirectory(path: directoryPath)
            }
            
            let fileName = (track.filePath as NSString).lastPathComponent
            return folderPath.replacingOccurrences(of: (folderPath as NSString).lastPathComponent, with: fileName)
        } else {
            return (track.filePath as NSString).lastPathComponent
        }
    }
    
    private func uploadTrack(
        track: Track,
        devicePath: String,
        total: Int,
        completed: inout Int,
        progress: @escaping (SyncProgress) -> Void
    ) async throws {
        do {
            try await mtpProtocol.uploadFile(
                localPath: track.filePath,
                devicePath: devicePath
            ) { uploadProgress in
                // Calculate overall progress
                let overallProgress = (Double(completed) + uploadProgress) / Double(total)
                progress(SyncProgress(
                    completed: Int(overallProgress * Double(total)),
                    total: total
                ))
            }
            completed += 1
            progress(SyncProgress(completed: completed, total: total))
        } catch let error as MTPError {
            switch error {
            case .insufficientSpace:
                throw DeviceSyncError.insufficientSpace
            case .operationCancelled:
                throw CancellationError()
            case .transferFailed(let reason):
                throw DeviceSyncError.transferFailed(reason)
            default:
                throw DeviceSyncError.transferFailed(error.localizedDescription)
            }
        }
    }
    
    public func cancel(jobId: UUID) async {
        cancelledJobs.insert(jobId)
        await mtpProtocol.cancel()
        
        // Cancel active transfer task if any
        if let task = activeTransfers[jobId] {
            task.cancel()
            activeTransfers.removeValue(forKey: jobId)
        }
    }
}
