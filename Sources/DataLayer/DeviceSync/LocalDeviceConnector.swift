//
//  LocalDeviceConnector.swift
//  DataLayer
//
//  File-system backed connector that copies tracks to mounted devices.
//

import CryptoKit
import Foundation
import Shared

public protocol FileHashing: Sendable {
    func hashFile(at url: URL) throws -> String
}

public struct SHA256FileHasher: FileHashing {
    public init() {}
    
    public func hashFile(at url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = try? handle.read(upToCount: 64 * 1024)
            if let data, !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private struct DeviceManifest: Codable {
    var entries: [UUID: DeviceManifestEntry]
}

private struct DeviceManifestEntry: Codable {
    let track: Track
    let relativePath: String
    let libraryChecksum: String?
    let lastSynced: Date
}

public actor LocalDeviceConnector: DeviceConnectorProtocol {
    
    private let fileManager: FileManager
    private let hasher: FileHashing
    private let copyDelayNanoseconds: UInt64
    private var cancelledJobs: Set<UUID> = []
    
    private let manifestFolderName = ".audientia-sync"
    private let libraryFolderName = "Audientia"
    
    public init(
        fileManager: FileManager = .default,
        hasher: FileHashing = SHA256FileHasher(),
        copyDelayNanoseconds: UInt64 = 0
    ) {
        self.fileManager = fileManager
        self.hasher = hasher
        self.copyDelayNanoseconds = copyDelayNanoseconds
    }
    
    public func fetchDeviceTracks(device: Device) async throws -> [DeviceTrackSnapshot] {
        guard let mountPath = device.mountPath else {
            throw DeviceSyncError.deviceNotFound
        }
        
        let manifest = try loadManifest(at: mountPath)
        let rootURL = URL(fileURLWithPath: mountPath, isDirectory: true)
        
        return manifest.entries.values.map { entry in
            let fileURL = rootURL.appendingPathComponent(entry.relativePath)
            let isPresent = fileManager.fileExists(atPath: fileURL.path)
            let deviceChecksum = isPresent ? (try? hasher.hashFile(at: fileURL)) : nil
            
            return DeviceTrackSnapshot(
                track: entry.track,
                relativePath: entry.relativePath,
                libraryChecksum: entry.libraryChecksum,
                deviceChecksum: deviceChecksum,
                isPresentOnDevice: isPresent
            )
        }
    }
    
    public func transfer(
        tracks: [Track],
        to device: Device,
        jobId: UUID,
        progress: @escaping (SyncProgress) -> Void
    ) async throws {
        guard let mountPath = device.mountPath else {
            throw DeviceSyncError.deviceNotFound
        }
        
        var manifest = try loadManifest(at: mountPath)
        let rootURL = URL(fileURLWithPath: mountPath, isDirectory: true)
        let libraryRoot = rootURL.appendingPathComponent(libraryFolderName, isDirectory: true)
        
        try fileManager.createDirectory(at: libraryRoot, withIntermediateDirectories: true, attributes: nil)
        
        defer { cancelledJobs.remove(jobId) }
        
        for (index, track) in tracks.enumerated() {
            try Task.checkCancellation()
            if copyDelayNanoseconds > 0 {
                try await Task.sleep(nanoseconds: copyDelayNanoseconds)
            }
            if cancelledJobs.contains(jobId) {
                throw CancellationError()
            }
            
            let relativeDirectory = track.id.uuidString
            let destinationDirectory = libraryRoot.appendingPathComponent(relativeDirectory, isDirectory: true)
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let sourceURL = URL(fileURLWithPath: track.filePath)
            let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            let relativePath = destinationURL.path.replacingOccurrences(of: rootURL.path + "/", with: "")
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            
            let checksum = try hasher.hashFile(at: sourceURL)
            manifest.entries[track.id] = DeviceManifestEntry(
                track: track,
                relativePath: relativePath,
                libraryChecksum: checksum,
                lastSynced: Date()
            )
            
            let completed = index + 1
            progress(SyncProgress(completed: completed, total: tracks.count))
        }
        
        try saveManifest(manifest, at: mountPath)
    }
    
    public func cancel(jobId: UUID) async {
        cancelledJobs.insert(jobId)
    }
    
    // MARK: - Manifest Utilities
    
    private func manifestURL(for mountPath: String) -> URL {
        let root = URL(fileURLWithPath: mountPath, isDirectory: true)
        return root
            .appendingPathComponent(manifestFolderName, isDirectory: true)
            .appendingPathComponent("manifest.json", isDirectory: false)
    }
    
    private func loadManifest(at mountPath: String) throws -> DeviceManifest {
        let url = manifestURL(for: mountPath)
        guard fileManager.fileExists(atPath: url.path) else {
            return DeviceManifest(entries: [:])
        }
        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(DeviceManifest.self, from: data)
        return manifest
    }
    
    private func saveManifest(_ manifest: DeviceManifest, at mountPath: String) throws {
        let url = manifestURL(for: mountPath)
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: url, options: .atomic)
    }
}
