//
//  FingerprintCacheProtocol.swift
//  MetadataEngine
//
//  Protocol for fingerprint caching
//

import Foundation

/// Represents a cached fingerprint entry
public struct FingerprintCacheEntry: Codable, Equatable, Sendable {
    /// File path (used as cache key)
    public let filePath: String
    
    /// File modification time (for cache invalidation)
    public let fileModificationTime: Date
    
    /// The fingerprint string
    public let fingerprint: String
    
    /// When the fingerprint was cached
    public let cachedAt: Date
    
    /// Optional expiration date (nil means never expires)
    public let expiresAt: Date?
    
    public init(
        filePath: String,
        fileModificationTime: Date,
        fingerprint: String,
        cachedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.filePath = filePath
        self.fileModificationTime = fileModificationTime
        self.fingerprint = fingerprint
        self.cachedAt = cachedAt
        self.expiresAt = expiresAt
    }
}

/// Protocol for fingerprint caching
public protocol FingerprintCacheProtocol: Sendable {
    /// Get a cached fingerprint for a file
    /// - Parameter filePath: The file path
    /// - Returns: Cached entry if found and valid, nil otherwise
    func get(filePath: String) async throws -> FingerprintCacheEntry?
    
    /// Store a fingerprint in the cache
    /// - Parameter entry: The cache entry to store
    func store(_ entry: FingerprintCacheEntry) async throws
    
    /// Remove a cached fingerprint
    /// - Parameter filePath: The file path to remove
    func remove(filePath: String) async throws
    
    /// Clear all cached fingerprints
    func clear() async throws
    
    /// Check if a fingerprint is cached and valid
    /// - Parameter filePath: The file path
    /// - Returns: true if cached and valid, false otherwise
    func isCached(filePath: String) async throws -> Bool
    
    /// Get cache statistics
    /// - Returns: Tuple with (total entries, expired entries)
    func getStatistics() async throws -> (total: Int, expired: Int)
}

/// Errors that can occur during cache operations
public enum FingerprintCacheError: Error, LocalizedError, Equatable {
    case databaseError(String)
    case invalidEntry(String)
    case cacheNotFound
    
    public var errorDescription: String? {
        switch self {
        case let .databaseError(message):
            return "Database error: \(message)"
        case let .invalidEntry(message):
            return "Invalid cache entry: \(message)"
        case .cacheNotFound:
            return "Cache entry not found"
        }
    }
}
