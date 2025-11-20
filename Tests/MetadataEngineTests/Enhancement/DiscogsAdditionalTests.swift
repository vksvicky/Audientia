//
//  DiscogsAdditionalTests.swift
//  MetadataEngineTests
//
//  Additional TDD tests for Discogs API client (Error, Performance, Edge Cases)
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// Additional TDD tests for Discogs API client: Error, Performance, Edge Cases
final class DiscogsAdditionalTests: XCTestCase {
    
    // MARK: - Error Conditions
    
    func testLookupReleaseWithNetworkError() async {
        // Given: A network error
        let releaseID = 123
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.networkError("Connection timeout")
        
        // When/Then: Error is thrown
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            XCTAssertEqual(error, .networkError("Connection timeout"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupReleaseWithRateLimitExceeded() async {
        // Given: Rate limit exceeded
        let releaseID = 123
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.rateLimitExceeded
        
        // When/Then: Rate limit error is thrown
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            XCTAssertEqual(error, .rateLimitExceeded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupReleaseWithInvalidResponse() async {
        // Given: Invalid response from API
        let releaseID = 123
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.invalidResponse("Malformed JSON")
        
        // When/Then: Invalid response error is thrown
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            XCTAssertEqual(error, .invalidResponse("Malformed JSON"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Characteristics
    
    func testLookupReleasePerformance() async throws {
        // Given: A valid release ID
        let releaseID = 123
        let client = MockDiscogsClient()
        client.mockRelease = DiscogsRelease(
            id: releaseID,
            title: "Test",
            artist: "Test"
        )
        
        // When: Measuring lookup time
        let startTime = Date()
        _ = try await client.lookupRelease(releaseID: releaseID)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Lookup completes within SLA (< 2s per roadmap)
        XCTAssertLessThan(elapsed, 2.0, "Release lookup should complete in < 2s")
    }
    
    func testSearchReleasesPerformance() async throws {
        // Given: A search query
        let query = "Queen"
        let client = MockDiscogsClient()
        client.mockSearchReleases = Array(repeating: DiscogsRelease(
            id: Int.random(in: 1...1000),
            title: "Test",
            artist: "Queen"
        ), count: 10)
        
        // When: Measuring search time
        let startTime = Date()
        _ = try await client.searchReleases(query: query)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Search completes within SLA (< 2s per roadmap)
        XCTAssertLessThan(elapsed, 2.0, "Release search should complete in < 2s")
    }
    
    // MARK: - Edge Cases
    
    func testReleaseWithPartialMetadata() async throws {
        // Given: A release with partial metadata
        let releaseID = 123
        let client = MockDiscogsClient()
        let partialRelease = DiscogsRelease(
            id: releaseID,
            title: "Unknown Album",
            artist: "Unknown Artist",
            year: nil,
            format: nil,
            genres: [],
            styles: [],
            tracks: [],
            label: nil,
            catalogNumber: nil,
            country: nil
        )
        client.mockRelease = partialRelease
        
        // When: Looking up the release
        let release = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: Release with partial metadata is returned
        XCTAssertEqual(release.title, "Unknown Album")
        XCTAssertEqual(release.artist, "Unknown Artist")
        XCTAssertNil(release.year)
        XCTAssertTrue(release.genres.isEmpty)
    }
    
    func testReleaseWithUnicodeMetadata() async throws {
        // Given: A release with Unicode characters
        let releaseID = 123
        let client = MockDiscogsClient()
        let unicodeRelease = DiscogsRelease(
            id: releaseID,
            title: "テストアルバム",
            artist: "テストアーティスト",
            genres: ["ロック"]
        )
        client.mockRelease = unicodeRelease
        
        // When: Looking up the release
        let release = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: Unicode metadata is preserved
        XCTAssertEqual(release.title, "テストアルバム")
        XCTAssertEqual(release.artist, "テストアーティスト")
        XCTAssertEqual(release.genres.first, "ロック")
    }
    
    func testReleaseWithMultipleTracks() async throws {
        // Given: A release with many tracks
        let releaseID = 123
        let client = MockDiscogsClient()
        let tracks = (1...20).map { trackNum in
            DiscogsTrack(
                title: "Track \(trackNum)",
                position: "\(trackNum)",
                duration: "3:\(String(format: "%02d", trackNum))"
            )
        }
        let release = DiscogsRelease(
            id: releaseID,
            title: "Test Album",
            artist: "Test Artist",
            tracks: tracks
        )
        client.mockRelease = release
        
        // When: Looking up the release
        let result = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: All tracks are returned
        XCTAssertEqual(result.tracks.count, 20)
    }
}

// MARK: - Mock Implementation

final class MockDiscogsClient: DiscogsClientProtocol, @unchecked Sendable {
    var mockRelease: DiscogsRelease?
    var mockSearchReleases: [DiscogsRelease] = []
    var mockSearchArtists: [DiscogsArtist] = []
    var shouldFail = false
    var errorToThrow: Error?
    
    func searchReleases(query: String) async throws -> [DiscogsRelease] {
        if shouldFail {
            throw errorToThrow ?? DiscogsError.invalidQuery(query)
        }
        if query.isEmpty {
            throw DiscogsError.invalidQuery(query)
        }
        return mockSearchReleases
    }
    
    func lookupRelease(releaseID: Int) async throws -> DiscogsRelease {
        if shouldFail {
            throw errorToThrow ?? DiscogsError.releaseNotFound(releaseID)
        }
        if releaseID <= 0 {
            throw DiscogsError.invalidReleaseID(releaseID)
        }
        guard let release = mockRelease else {
            throw DiscogsError.releaseNotFound(releaseID)
        }
        return release
    }
    
    func searchArtists(query: String) async throws -> [DiscogsArtist] {
        if shouldFail {
            throw errorToThrow ?? DiscogsError.invalidQuery(query)
        }
        if query.isEmpty {
            throw DiscogsError.invalidQuery(query)
        }
        return mockSearchArtists
    }
}
