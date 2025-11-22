//
//  FingerprintCacheTests+Performance.swift
//  MetadataEngineTests
//
//  Performance tests for fingerprint cache (extracted to reduce type body length)
//

import Foundation
import XCTest

@testable import MetadataEngine

extension FingerprintCacheTests {
    // MARK: - Performance Characteristics
    
    func testStorePerformance() async throws {
        let cache = try requireCache()
        let entry = FingerprintCacheEntry(
            filePath: "/path/to/audio.mp3",
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        let startTime = Date()
        try await cache.store(entry)
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 0.1, "Store should complete in < 100ms")
    }
    
    func testRetrievePerformance() async throws {
        let cache = try requireCache()
        let entry = FingerprintCacheEntry(
            filePath: "/path/to/audio.mp3",
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        try await cache.store(entry)
        let startTime = Date()
        _ = try await cache.get(filePath: entry.filePath)
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 0.05, "Retrieve should complete in < 50ms")
    }
    
    func testBatchStorePerformance() async throws {
        let cache = try requireCache()
        let entries = (0..<100).map { index in
            FingerprintCacheEntry(
                filePath: "/path/to/audio\(index).mp3",
                fileModificationTime: Date(),
                fingerprint: "fingerprint\(index)"
            )
        }
        let startTime = Date()
        for entry in entries {
            try await cache.store(entry)
        }
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 5.0, "Batch store should complete in < 5s for 100 entries")
    }
}
