//
//  FingerprintStatusViewTests.swift
//  UITests
//
//  UI tests for fingerprint status view
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// UI tests for FingerprintStatusView following Right-BICEP principles
@MainActor
final class FingerprintStatusViewTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testFingerprintStatusDisplaysCorrectly() {
        // Given: A fingerprint status view with a track
        let mockService = MockAcoustIDService()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: nil
        )
        let track = createTestTrack()
        
        // When: Creating the view
        let view = FingerprintStatusView(viewModel: viewModel, track: track)
        
        // Then: View is created successfully
        XCTAssertNotNil(view)
    }
    
    func testFingerprintStatusShowsNotCachedWhenNoFingerprint() async {
        // Given: A track without a cached fingerprint
        let mockService = MockAcoustIDService()
        let mockCache = MockFingerprintCache()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: mockCache
        )
        let track = createTestTrack()
        
        // When: Checking status
        await viewModel.checkStatus(for: track)
        
        // Then: Status shows not cached
        XCTAssertEqual(viewModel.fingerprintStatus, .notCached)
    }
    
    func testFingerprintStatusShowsCachedWhenFingerprintExists() async throws {
        // Given: A track with a cached fingerprint
        let mockService = MockAcoustIDService()
        let mockCache = MockFingerprintCache()
        let track = createTestTrack()
        
        // Store fingerprint in cache
        let entry = FingerprintCacheEntry(
            filePath: track.filePath,
            fileModificationTime: Date(),
            fingerprint: "AQADtE..."
        )
        try await mockCache.store(entry)
        
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: mockCache
        )
        
        // When: Checking status
        await viewModel.checkStatus(for: track)
        
        // Then: Status shows cached
        XCTAssertEqual(viewModel.fingerprintStatus, .cached)
        XCTAssertNotNil(viewModel.fingerprint)
    }
    
    // MARK: - Boundary Conditions
    
    func testFingerprintStatusHandlesNilTrack() {
        // Given: A view with nil track
        let mockService = MockAcoustIDService()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: nil
        )
        
        // When: Creating view with nil track
        let view = FingerprintStatusView(viewModel: viewModel, track: nil)
        
        // Then: View is created (buttons should be disabled)
        XCTAssertNotNil(view)
    }
    
    func testFingerprintStatusHandlesMissingCache() async {
        // Given: A view without cache
        let mockService = MockAcoustIDService()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: nil
        )
        let track = createTestTrack()
        
        // When: Checking status
        await viewModel.checkStatus(for: track)
        
        // Then: Status shows unknown (no cache available)
        XCTAssertEqual(viewModel.fingerprintStatus, .unknown)
    }
    
    // MARK: - Error Conditions
    
    func testFingerprintStatusHandlesGenerationError() async {
        // Given: A service that fails to generate fingerprint
        let mockService = MockAcoustIDService()
        mockService.shouldFail = true
        mockService.errorToThrow = AcoustIDError.fingerprintGenerationFailed("Test error")
        
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: nil
        )
        let track = createTestTrack()
        
        // When: Generating fingerprint
        await viewModel.generateFingerprint(for: track)
        
        // Then: Error is displayed
        if case let .error(message) = viewModel.fingerprintStatus {
            XCTAssertTrue(message.contains("Test error"))
        } else {
            XCTFail("Expected error status")
        }
        XCTAssertNotNil(viewModel.lastError)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack() -> Track {
        Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
    }
}

// MARK: - Mock Implementations

private final class MockAcoustIDService: AcoustIDServicing, @unchecked Sendable {
    var shouldFail = false
    var errorToThrow: Error?
    var matches: [AcoustIDMatch] = []
    
    func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] {
        if shouldFail, let error = errorToThrow {
            throw error
        }
        return matches
    }
}

private actor MockFingerprintCache: FingerprintCacheProtocol {
    private var cache: [String: FingerprintCacheEntry] = [:]
    
    func get(filePath: String) async throws -> FingerprintCacheEntry? {
        cache[filePath]
    }
    
    func store(_ entry: FingerprintCacheEntry) async throws {
        cache[entry.filePath] = entry
    }
    
    func remove(filePath: String) async throws {
        cache.removeValue(forKey: filePath)
    }
    
    func clear() async throws {
        cache.removeAll()
    }
    
    func isCached(filePath: String) async throws -> Bool {
        cache[filePath] != nil
    }
    
    func getStatistics() async throws -> (total: Int, expired: Int) {
        (total: cache.count, expired: 0)
    }
}
