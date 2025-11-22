//
//  FingerprintCacheBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for fingerprint caching scenarios
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// BDD tests for fingerprint caching following user-centric scenarios
final class FingerprintCacheBDDTests: XCTestCase {
    
    private var cache: (any FingerprintCacheProtocol)?
    private var cacheURL: URL?
    
    override func setUp() async throws {
        try await super.setUp()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("db")
        cacheURL = url
        cache = SQLiteFingerprintCache(databaseURL: url)
    }
    
    override func tearDown() async throws {
        if let cache = cache {
            try? await cache.clear()
        }
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL)
        }
        cache = nil
        cacheURL = nil
        try await super.tearDown()
    }
    
    private func requireCache() throws -> any FingerprintCacheProtocol {
        guard let cache = cache else {
            throw XCTSkip("Cache not initialized")
        }
        return cache
    }
    
    // MARK: - BDD Scenarios
    
    func testAsUserIWantFingerprintsToBeCachedForFasterLookups() async throws {
        // Scenario: As a user, I want fingerprints to be cached so that subsequent lookups are faster
        let cache = try requireCache()
        
        // Given: I have generated a fingerprint for a track
        let filePath = "/path/to/audio.mp3"
        let modificationTime = Date()
        let fingerprint = "AQADtE..."
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: modificationTime,
            fingerprint: fingerprint
        )
        
        // When: I store the fingerprint in the cache
        try await cache.store(entry)
        
        // Then: The fingerprint is available for future lookups
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.fingerprint, fingerprint)
    }
    
    func testAsUserIWantCachedFingerprintsToBeInvalidatedWhenFileChanges() async throws {
        // Scenario: As a user, I want cached fingerprints to be invalidated when the file is modified
        let cache = try requireCache()
        
        // Given: I have a cached fingerprint for a track
        let filePath = "/path/to/audio.mp3"
        let oldModificationTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let oldFingerprint = "old_fingerprint"
        let oldEntry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: oldModificationTime,
            fingerprint: oldFingerprint
        )
        try await cache.store(oldEntry)
        
        // When: The file is modified and I check the cache with the new modification time
        let newModificationTime = Date()
        let newEntry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: newModificationTime,
            fingerprint: "new_fingerprint"
        )
        try await cache.store(newEntry)
        
        // Then: The cache contains the new fingerprint
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNotNil(retrieved)
        guard let retrieved = retrieved else { return }
        XCTAssertEqual(retrieved.fingerprint, "new_fingerprint")
        XCTAssertEqual(retrieved.fileModificationTime.timeIntervalSince1970, newModificationTime.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testAsUserIWantExpiredFingerprintsToBeRemovedAutomatically() async throws {
        // Scenario: As a user, I want expired fingerprints to be automatically removed from the cache
        let cache = try requireCache()
        
        // Given: I have an expired fingerprint in the cache
        let filePath = "/path/to/audio.mp3"
        let expiredDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE...",
            cachedAt: expiredDate,
            expiresAt: Date().addingTimeInterval(-1800) // Expired 30 minutes ago
        )
        try await cache.store(entry)
        
        // When: I try to retrieve the fingerprint
        let retrieved = try await cache.get(filePath: filePath)
        
        // Then: The expired fingerprint is not returned and is removed from cache
        XCTAssertNil(retrieved, "Expired fingerprint should not be returned")
        let isCached = try await cache.isCached(filePath: filePath)
        XCTAssertFalse(isCached, "Expired fingerprint should be removed from cache")
    }
    
    func testAsUserIWantToClearAllCachedFingerprints() async throws {
        // Scenario: As a user, I want to clear all cached fingerprints
        let cache = try requireCache()
        
        // Given: I have multiple fingerprints cached
        let entries = (0..<5).map { index in
            FingerprintCacheEntry(
                filePath: "/path/to/audio\(index).mp3",
                fileModificationTime: Date(),
                fingerprint: "fingerprint\(index)"
            )
        }
        for entry in entries {
            try await cache.store(entry)
        }
        
        // When: I clear the cache
        try await cache.clear()
        
        // Then: All fingerprints are removed
        for entry in entries {
            let retrieved = try await cache.get(filePath: entry.filePath)
            XCTAssertNil(retrieved, "Fingerprint should be removed after clearing cache")
        }
        let stats = try await cache.getStatistics()
        XCTAssertEqual(stats.total, 0, "Cache should be empty after clearing")
    }
    
    func testAsUserIWantToSeeCacheStatistics() async throws {
        // Scenario: As a user, I want to see cache statistics to understand cache usage
        let cache = try requireCache()
        
        // Given: I have multiple fingerprints cached, some expired
        let validEntries = (0..<3).map { index in
            FingerprintCacheEntry(
                filePath: "/path/to/audio\(index).mp3",
                fileModificationTime: Date(),
                fingerprint: "fingerprint\(index)"
            )
        }
        for entry in validEntries {
            try await cache.store(entry)
        }
        
        let expiredEntry = FingerprintCacheEntry(
            filePath: "/path/to/expired.mp3",
            fileModificationTime: Date(),
            fingerprint: "expired",
            cachedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(-1800) // Expired
        )
        try await cache.store(expiredEntry)
        
        // When: I get cache statistics
        let stats = try await cache.getStatistics()
        
        // Then: I can see the total number of entries and expired entries
        XCTAssertGreaterThanOrEqual(stats.total, 4, "Should have at least 4 entries")
        XCTAssertGreaterThanOrEqual(stats.expired, 1, "Should have at least 1 expired entry")
    }
    
    func testAsUserIWantFingerprintsToPersistAcrossAppRestarts() async throws {
        // Scenario: As a user, I want cached fingerprints to persist across app restarts
        let cache = try requireCache()
        
        // Given: I have cached a fingerprint
        let filePath = "/path/to/audio.mp3"
        let modificationTime = Date()
        let fingerprint = "AQADtE..."
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: modificationTime,
            fingerprint: fingerprint
        )
        try await cache.store(entry)
        
        // When: I create a new cache instance (simulating app restart)
        // Note: In a real scenario, the cache would be recreated from the same database
        guard let cacheURL = cacheURL else {
            XCTFail("Cache URL not available")
            return
        }
        let newCache = SQLiteFingerprintCache(databaseURL: cacheURL)
        
        // Then: The fingerprint is still available
        let retrieved = try await newCache.get(filePath: filePath)
        XCTAssertNotNil(retrieved, "Fingerprint should persist across cache instances")
        guard let retrieved = retrieved else { return }
        XCTAssertEqual(retrieved.fingerprint, fingerprint)
    }
}
