//
//  FingerprintCacheTests+EdgeCases.swift
//  MetadataEngineTests
//
//  Edge case tests for fingerprint cache (extracted to reduce type body length)
//

import Foundation
import XCTest

@testable import MetadataEngine

extension FingerprintCacheTests {
    // MARK: - Edge Cases
    
    func testStoreFingerprintWithSpecialCharactersInPath() async throws {
        let cache = try requireCache()
        let filePath = "/path/to/audio (remix) [2020].mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        try await cache.store(entry)
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.filePath, filePath)
    }
    
    func testStoreFingerprintWithUnicodeInPath() async throws {
        let cache = try requireCache()
        let filePath = "/path/to/音楽.mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        try await cache.store(entry)
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.filePath, filePath)
    }
    
    func testExpiredEntryIsNotReturned() async throws {
        let cache = try requireCache()
        let filePath = "/path/to/audio.mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE...",
            cachedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(-1800)
        )
        try await cache.store(entry)
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNil(retrieved)
        XCTAssertFalse(try await cache.isCached(filePath: filePath))
    }
    
    func testNonExpiredEntryIsReturned() async throws {
        let cache = try requireCache()
        let filePath = "/path/to/audio.mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE...",
            cachedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )
        try await cache.store(entry)
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.fingerprint, "AQADtE...")
    }
    
    func testEntryWithoutExpirationIsAlwaysReturned() async throws {
        let cache = try requireCache()
        let filePath = "/path/to/audio.mp3"
        let entry = FingerprintCacheEntry(
            filePath: filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE...",
            cachedAt: Date(),
            expiresAt: nil
        )
        try await cache.store(entry)
        let retrieved = try await cache.get(filePath: filePath)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.fingerprint, "AQADtE...")
    }
}
