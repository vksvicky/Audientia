//
//  MockMTPProtocol.swift
//  DataLayerTests
//
//  Mock implementation of MTPProtocol for testing
//

@testable import DataLayer
import Foundation
@testable import Shared

/// Mock MTP protocol implementation for testing
public actor MockMTPProtocol: MTPProtocol {
    
    public var connectedDeviceId: String?
    public var files: [String: MTPFileMetadata] = [:]
    public var directories: Set<String> = []
    public var availableSpace: Int64 = 10 * 1024 * 1024 * 1024 // 10 GB default
    public var shouldFailConnection = false
    public var shouldFailUpload = false
    public var shouldFailDelete = false
    public var uploadDelay: TimeInterval = 0.01
    public var cancelled = false
    
    public var connectCallCount = 0
    public var disconnectCallCount = 0
    public var listFilesCallCount = 0
    public var uploadCallCount = 0
    public var deleteCallCount = 0
    public var createDirectoryCallCount = 0
    
    public init() {}
    
    public func connect(deviceId: String) async throws -> Bool {
        connectCallCount += 1
        if shouldFailConnection {
            throw MTPError.connectionFailed("Simulated connection failure")
        }
        connectedDeviceId = deviceId
        return true
    }
    
    public func disconnect() async throws {
        disconnectCallCount += 1
        connectedDeviceId = nil
        cancelled = false
    }
    
    public func listFiles() async throws -> [String] {
        listFilesCallCount += 1
        guard await isConnected() else {
            throw MTPError.deviceNotFound
        }
        return Array(files.keys)
    }
    
    public func getFileMetadata(path: String) async throws -> MTPFileMetadata {
        guard await isConnected() else {
            throw MTPError.deviceNotFound
        }
        guard let metadata = files[path] else {
            throw MTPError.fileNotFound(path)
        }
        return metadata
    }
    
    public func uploadFile(localPath: String, devicePath: String, progress: @escaping (Double) -> Void) async throws {
        uploadCallCount += 1
        guard await isConnected() else {
            throw MTPError.deviceNotFound
        }
        
        if cancelled {
            throw MTPError.operationCancelled
        }
        
        if shouldFailUpload {
            throw MTPError.transferFailed("Simulated upload failure")
        }
        
        // Simulate file size check
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: localPath)[.size] as? Int64) ?? 0
        if fileSize > availableSpace {
            throw MTPError.insufficientSpace
        }
        
        // Simulate upload progress
        let steps = 10
        for step in 0...steps {
            if cancelled {
                throw MTPError.operationCancelled
            }
            let delayNanos = UInt64(uploadDelay * 1_000_000_000) / UInt64(steps)
            try await Task.sleep(nanoseconds: delayNanos)
            progress(Double(step) / Double(steps))
        }
        
        // Add file to mock storage
        files[devicePath] = MTPFileMetadata(
            path: devicePath,
            size: fileSize,
            modificationDate: Date()
        )
        availableSpace -= fileSize
    }
    
    public func deleteFile(path: String) async throws {
        deleteCallCount += 1
        guard await isConnected() else {
            throw MTPError.deviceNotFound
        }
        
        if shouldFailDelete {
            throw MTPError.transferFailed("Simulated delete failure")
        }
        
        guard let metadata = files[path] else {
            throw MTPError.fileNotFound(path)
        }
        
        files.removeValue(forKey: path)
        availableSpace += metadata.size
    }
    
    public func createDirectory(path: String) async throws {
        createDirectoryCallCount += 1
        guard await isConnected() else {
            throw MTPError.deviceNotFound
        }
        directories.insert(path)
    }
    
    public func isConnected() async -> Bool {
        connectedDeviceId != nil
    }
    
    public func cancel() async {
        cancelled = true
    }
    
    // MARK: - Test Helpers
    
    public func setAvailableSpace(_ space: Int64) {
        availableSpace = space
    }
    
    public func setUploadDelay(_ delay: TimeInterval) {
        uploadDelay = delay
    }
    
    public func setShouldFailUpload(_ flag: Bool) {
        shouldFailUpload = flag
    }
    
    public func setShouldFailDelete(_ flag: Bool) {
        shouldFailDelete = flag
    }
    
    public func setShouldFailConnection(_ flag: Bool) {
        shouldFailConnection = flag
    }
    
    public func addFile(_ path: String, size: Int64) {
        files[path] = MTPFileMetadata(path: path, size: size)
    }
    
    public func clearFiles() {
        files.removeAll()
        directories.removeAll()
    }
}
