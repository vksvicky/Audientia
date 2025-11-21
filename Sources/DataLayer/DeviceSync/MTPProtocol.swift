//
//  MTPProtocol.swift
//  DataLayer
//
//  Protocol abstraction for MTP (Media Transfer Protocol) operations
//  Allows testing without requiring libmtp integration
//

import Foundation
import Shared

/// Protocol for MTP device operations
/// This abstraction allows us to test MTP connector logic without requiring libmtp
public protocol MTPProtocol: Sendable {
    /// Connect to an MTP device
    /// - Parameter deviceId: The device identifier
    /// - Returns: True if connection successful
    /// - Throws: MTPError if connection fails
    func connect(deviceId: String) async throws -> Bool
    
    /// Disconnect from the current MTP device
    func disconnect() async throws
    
    /// List all files on the MTP device
    /// - Returns: Array of file paths relative to device root
    /// - Throws: MTPError if enumeration fails
    func listFiles() async throws -> [String]
    
    /// Get file metadata from MTP device
    /// - Parameter path: File path on device
    /// - Returns: File metadata including size, modification date
    /// - Throws: MTPError if file not found
    func getFileMetadata(path: String) async throws -> MTPFileMetadata
    
    /// Upload a file to the MTP device
    /// - Parameters:
    ///   - localPath: Path to local file
    ///   - devicePath: Destination path on device
    ///   - progress: Progress callback (0.0 to 1.0)
    /// - Throws: MTPError if upload fails
    func uploadFile(localPath: String, devicePath: String, progress: @escaping (Double) -> Void) async throws
    
    /// Delete a file from the MTP device
    /// - Parameter path: File path on device
    /// - Throws: MTPError if deletion fails
    func deleteFile(path: String) async throws
    
    /// Create a directory on the MTP device
    /// - Parameter path: Directory path to create
    /// - Throws: MTPError if creation fails
    func createDirectory(path: String) async throws
    
    /// Check if device is connected
    /// - Returns: True if connected
    func isConnected() async -> Bool
    
    /// Cancel any in-progress operations
    func cancel() async
}

/// MTP file metadata
public struct MTPFileMetadata: Sendable, Equatable {
    public let path: String
    public let size: Int64
    public let modificationDate: Date?
    
    public init(path: String, size: Int64, modificationDate: Date? = nil) {
        self.path = path
        self.size = size
        self.modificationDate = modificationDate
    }
}

/// MTP-specific errors
public enum MTPError: LocalizedError, Equatable, Sendable {
    case deviceNotFound
    case connectionFailed(String)
    case fileNotFound(String)
    case insufficientSpace
    case transferFailed(String)
    case operationCancelled
    case notImplemented
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "MTP device not found"
        case let .connectionFailed(reason):
            return "MTP connection failed: \(reason)"
        case let .fileNotFound(path):
            return "File not found on device: \(path)"
        case .insufficientSpace:
            return "Insufficient space on MTP device"
        case let .transferFailed(reason):
            return "MTP transfer failed: \(reason)"
        case .operationCancelled:
            return "MTP operation cancelled"
        case .notImplemented:
            return "MTP operation not yet implemented"
        }
    }
}
