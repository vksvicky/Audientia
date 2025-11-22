//
//  FingerprintCacheTests.swift
//  MetadataEngineTests
//
//  TDD tests for fingerprint cache following Right-BICEP principles
//

import Foundation
import XCTest

@testable import MetadataEngine

/// TDD tests for fingerprint cache following Right-BICEP principles
final class FingerprintCacheTests: XCTestCase {
    
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
    
    // MARK: - Helper Methods
    
    private func requireCache() throws -> any FingerprintCacheProtocol {
        guard let cache = cache else {
            throw XCTSkip("Cache not initialized")
        }
        return cache
    }
    
    // MARK: - Right: Are the results right?
    
    func testStoreAndRetrieveFingerprint() async throws {
        let cache = try requireCache()
        // Given: A fingerprint cache entry
        let filePath = "/path/to/audio.mp3"
        let modificationTime = Date()
        let fingerprint = "AQADtE..."
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: modificationTime,
            fingerprint: fingerprint
        )
        
        // When: Storing and retrieving the entry
        try await cache.store(entry)
        let retrieved = try await cache.get(filePath: filePath)
        
        // Then: The entry is retrieved correctly
        XCTAssertNotNil(retrieved)
        guard let retrieved = retrieved else { return }
        XCTAssertEqual(retrieved.filePath, filePath)
        XCTAssertEqual(retrieved.fingerprint, fingerprint)
        XCTAssertEqual(retrieved.fileModificationTime.timeIntervalSince1970, modificationTime.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testRetrieveNonExistentFingerprint() async throws {
        let cache = try requireCache()
        // Given: A file path that doesn't exist in cache
        let filePath = "/path/to/nonexistent.mp3"
        
        // When: Retrieving the entry
        let retrieved = try await cache.get(filePath: filePath)
        
        // Then: nil is returned
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Boundary Conditions
    
    func testStoreFingerprintWithVeryLongPath() async throws {
        let cache = try requireCache()
        // Given: A file path that's very long
        let longPath = "/" + String(repeating: "a", count: 1000) + ".mp3"
        let entry = FingerprintCacheEntry(
            filePath: longPath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        
        // When: Storing the entry
        try await cache.store(entry)
        
        // Then: The entry can be retrieved
        let retrieved = try await cache.get(filePath: longPath)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.filePath, longPath)
    }
    
    func testStoreFingerprintWithEmptyFingerprint() async throws {
        let cache = try requireCache()
        // Given: An entry with empty fingerprint
        let entry = FingerprintCacheEntry(
            filePath: "/path/to/audio.mp3",
            fileModificationTime: Date(),
            fingerprint: ""
        )
        
        // When: Storing the entry
        try await cache.store(entry)
        
        // Then: The entry can be retrieved (empty fingerprint is valid)
        let retrieved = try await cache.get(filePath: "/path/to/audio.mp3")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.fingerprint, "")
    }
    
    func testStoreMultipleFingerprints() async throws {
        let cache = try requireCache()
        // Given: Multiple fingerprint entries
        let entries = (0..<100).map { index in
            FingerprintCacheEntry(
                filePath: "/path/to/audio\(index).mp3",
                fileModificationTime: Date(),
                fingerprint: "fingerprint\(index)"
            )
        }
        
        // When: Storing all entries
        for entry in entries {
            try await cache.store(entry)
        }
        
        // Then: All entries can be retrieved
        for entry in entries {
            let retrieved = try await cache.get(filePath: entry.filePath)
            XCTAssertNotNil(retrieved)
            XCTAssertEqual(retrieved?.fingerprint, entry.fingerprint)
        }
    }
    
    func testIsCachedReturnsFalseForNonExistentFile() async throws {
        let cache = try requireCache()
        // Given: A file path that doesn't exist in cache
        let filePath = "/path/to/nonexistent.mp3"
        
        // When: Checking if cached
        let isCached = try await cache.isCached(filePath: filePath)
        
        // Then: Returns false
        XCTAssertFalse(isCached)
    }
    
    func testIsCachedReturnsTrueForCachedFile() async throws {
        let cache = try requireCache()
        // Given: A cached fingerprint
        let filePath = "/path/to/audio.mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        try await cache.store(entry)
        
        // When: Checking if cached
        let isCached = try await cache.isCached(filePath: filePath)
        
        // Then: Returns true
        XCTAssertTrue(isCached)
    }
    
    // MARK: - Inverse Relationships
    
    func testStoreRemoveRoundtrip() async throws {
        let cache = try requireCache()
        // Given: A stored fingerprint
        let filePath = "/path/to/audio.mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        try await cache.store(entry)
        
        // When: Removing and checking
        try await cache.remove(filePath: filePath)
        let retrieved = try await cache.get(filePath: filePath)
        
        // Then: Entry is removed (inverse: store → remove → verify gone)
        XCTAssertNil(retrieved)
        let isCached = try await cache.isCached(filePath: filePath)
        XCTAssertFalse(isCached)
    }
    
    func testClearRemovesAllEntries() async throws {
        let cache = try requireCache()
        // Given: Multiple stored fingerprints
        let entries = (0..<10).map { index in
            FingerprintCacheEntry(
                filePath: "/path/to/audio\(index).mp3",
                fileModificationTime: Date(),
                fingerprint: "fingerprint\(index)"
            )
        }
        for entry in entries {
            try await cache.store(entry)
        }
        
        // When: Clearing the cache
        try await cache.clear()
        
        // Then: All entries are removed
        for entry in entries {
            let retrieved = try await cache.get(filePath: entry.filePath)
            XCTAssertNil(retrieved)
        }
        let stats = try await cache.getStatistics()
        XCTAssertEqual(stats.total, 0)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testStatisticsMatchActualEntries() async throws {
        let cache = try requireCache()
        // Given: Multiple stored fingerprints
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
        
        // When: Getting statistics
        let stats = try await cache.getStatistics()
        
        // Then: Statistics match actual entries (cross-check)
        XCTAssertEqual(stats.total, 5)
        XCTAssertEqual(stats.expired, 0)
    }
    
    // MARK: - Error Conditions
    
    func testStoreOverwritesExistingEntry() async throws {
        let cache = try requireCache()
        // Given: An existing cached entry
        let filePath = "/path/to/audio.mp3"
        let entry1 = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "old"
        )
        try await cache.store(entry1)
        
        // When: Storing a new entry with same path
        let entry2 = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "new"
        )
        try await cache.store(entry2)
        
        // Then: New entry overwrites old one
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertEqual(retrieved?.fingerprint, "new")
    }
    
    func testRemoveNonExistentEntry() async throws {
        let cache = try requireCache()
        // Given: A file path that doesn't exist in cache
        let filePath = "/path/to/nonexistent.mp3"
        
        // When: Removing the entry
        // Then: No error is thrown (idempotent operation)
        try await cache.remove(filePath: filePath)
    }
}


