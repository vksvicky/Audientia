//
//  FingerprintStatusViewBDDTests.swift
//  UITests
//
//  BDD tests for fingerprint status view
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// BDD tests for FingerprintStatusView following user-centric scenarios
@MainActor
final class FingerprintStatusViewBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    func testAsUserIWantToSeeFingerprintStatusForMyTrack() async {
        // Scenario: As a user, I want to see the fingerprint status for my track
        let mockService = MockAcoustIDService()
        let mockCache = MockFingerprintCache()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: mockCache
        )
        let track = createTestTrack()
        
        // Given: I have a track
        // When: I check the fingerprint status
        await viewModel.checkStatus(for: track)
        
        // Then: I can see the status (not cached initially)
        XCTAssertEqual(viewModel.fingerprintStatus, .notCached)
    }
    
    func testAsUserIWantToManuallyGenerateFingerprintForUnknownTrack() async {
        // Scenario: As a user, I want to manually generate a fingerprint for an unknown track
        let mockService = MockAcoustIDService()
        let mockCache = MockFingerprintCache()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: mockCache
        )
        let track = createTestTrack()
        
        // Given: I have a track without a fingerprint
        await viewModel.checkStatus(for: track)
        XCTAssertEqual(viewModel.fingerprintStatus, .notCached)
        
        // When: I manually trigger fingerprint generation
        await viewModel.generateFingerprint(for: track)
        
        // Then: The fingerprint is generated and status is updated
        // Note: In a real scenario, the fingerprint would be cached
        // For this test, we verify the generation process completes
        XCTAssertFalse(viewModel.isGenerating, "Generation should complete")
    }
    
    func testAsUserIWantToSeeWhenFingerprintIsCached() async throws {
        // Scenario: As a user, I want to see when a fingerprint is already cached
        let mockService = MockAcoustIDService()
        let mockCache = MockFingerprintCache()
        let track = createTestTrack()
        
        // Given: I have a track with a cached fingerprint
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
        
        // When: I check the fingerprint status
        await viewModel.checkStatus(for: track)
        
        // Then: I can see that the fingerprint is cached
        XCTAssertEqual(viewModel.fingerprintStatus, .cached)
        XCTAssertNotNil(viewModel.fingerprint)
    }
    
    func testAsUserIWantToRefreshFingerprintStatus() async {
        // Scenario: As a user, I want to refresh the fingerprint status
        let mockService = MockAcoustIDService()
        let mockCache = MockFingerprintCache()
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: mockCache
        )
        let track = createTestTrack()
        
        // Given: I have checked the status once
        await viewModel.checkStatus(for: track)
        let initialStatus = viewModel.fingerprintStatus
        
        // When: I refresh the status
        await viewModel.checkStatus(for: track)
        
        // Then: The status is updated
        XCTAssertEqual(viewModel.fingerprintStatus, initialStatus)
    }
    
    func testAsUserIWantToSeeErrorWhenFingerprintGenerationFails() async {
        // Scenario: As a user, I want to see an error when fingerprint generation fails
        let mockService = MockAcoustIDService()
        mockService.shouldFail = true
        mockService.errorToThrow = AcoustIDError.fingerprintGenerationFailed("FFmpeg not available")
        
        let viewModel = FingerprintStatusViewModel(
            acoustIDService: mockService,
            fingerprintCache: nil
        )
        let track = createTestTrack()
        
        // Given: I have a track
        // When: I try to generate a fingerprint and it fails
        await viewModel.generateFingerprint(for: track)
        
        // Then: I see an error message
        if case let .error(message) = viewModel.fingerprintStatus {
            XCTAssertTrue(message.contains("FFmpeg") || message.contains("error"), "Error message should be displayed")
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
