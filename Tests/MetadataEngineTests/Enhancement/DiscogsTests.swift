//
//  DiscogsTests.swift
//  MetadataEngineTests
//
//  TDD tests for Discogs API client
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// TDD tests for Discogs API client following Right-BICEP principles
// swiftlint:disable type_body_length
final class DiscogsTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testSearchReleases() async throws {
        // Given: A search query
        let query = "Queen A Night at the Opera"
        let client = MockDiscogsClient()
        let release1 = DiscogsRelease(
            id: 123,
            title: "A Night at the Opera",
            artist: "Queen",
            year: 1975,
            format: "LP",
            genres: ["Rock"],
            styles: ["Progressive Rock"]
        )
        let release2 = DiscogsRelease(
            id: 456,
            title: "A Night at the Opera (Remastered)",
            artist: "Queen",
            year: 2011,
            format: "CD",
            genres: ["Rock"]
        )
        client.mockSearchReleases = [release1, release2]
        
        // When: Searching for releases
        let releases = try await client.searchReleases(query: query)
        
        // Then: Matching releases are returned
        XCTAssertEqual(releases.count, 2)
        XCTAssertTrue(releases.allSatisfy { $0.artist == "Queen" })
        XCTAssertTrue(releases.allSatisfy { $0.title.contains("A Night at the Opera") })
    }
    
    func testLookupReleaseByID() async throws {
        // Given: A valid Discogs release ID
        let releaseID = 123
        let client = MockDiscogsClient()
        let track1 = DiscogsTrack(
            title: "Death on Two Legs",
            position: "A1",
            duration: "3:43"
        )
        let track2 = DiscogsTrack(
            title: "Lazing on a Sunday Afternoon",
            position: "A2",
            duration: "1:07"
        )
        let expectedRelease = DiscogsRelease(
            id: releaseID,
            title: "A Night at the Opera",
            artist: "Queen",
            year: 1975,
            format: "LP",
            genres: ["Rock"],
            styles: ["Progressive Rock"],
            tracks: [track1, track2],
            label: "EMI",
            catalogNumber: "EMA 784",
            country: "UK"
        )
        client.mockRelease = expectedRelease
        
        // When: Looking up the release
        let release = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: Correct release is returned with tracks
        XCTAssertEqual(release.id, releaseID)
        XCTAssertEqual(release.title, "A Night at the Opera")
        XCTAssertEqual(release.artist, "Queen")
        XCTAssertEqual(release.year, 1975)
        XCTAssertEqual(release.tracks.count, 2)
        XCTAssertEqual(release.label, "EMI")
    }
    
    func testSearchArtists() async throws {
        // Given: A search query
        let query = "Queen"
        let client = MockDiscogsClient()
        let artist1 = DiscogsArtist(
            id: 1,
            name: "Queen",
            profile: "British rock band",
            realName: nil
        )
        let artist2 = DiscogsArtist(
            id: 2,
            name: "Queen (2)",
            profile: "Different artist",
            realName: nil
        )
        client.mockSearchArtists = [artist1, artist2]
        
        // When: Searching for artists
        let artists = try await client.searchArtists(query: query)
        
        // Then: Matching artists are returned
        XCTAssertEqual(artists.count, 2)
        XCTAssertTrue(artists.allSatisfy { $0.name.contains("Queen") })
    }
    
    // MARK: - Boundary Conditions
    
    func testLookupReleaseWithInvalidID() async {
        // Given: An invalid release ID
        let releaseID = -1
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.invalidReleaseID(releaseID)
        
        // When/Then: Error is thrown
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            XCTAssertEqual(error, .invalidReleaseID(releaseID))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupReleaseNotFound() async {
        // Given: A non-existent release ID
        let releaseID = 999999
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.releaseNotFound(releaseID)
        
        // When/Then: Error is thrown
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            XCTAssertEqual(error, .releaseNotFound(releaseID))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSearchReleasesWithEmptyQuery() async {
        // Given: An empty search query
        let query = ""
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.invalidQuery(query)
        
        // When/Then: Error is thrown
        do {
            _ = try await client.searchReleases(query: query)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            XCTAssertEqual(error, .invalidQuery(query))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSearchReleasesWithNoResults() async throws {
        // Given: A query with no matches
        let query = "NonexistentArtist NonexistentAlbum"
        let client = MockDiscogsClient()
        client.mockSearchReleases = []
        
        // When: Searching for releases
        let releases = try await client.searchReleases(query: query)
        
        // Then: Empty array is returned
        XCTAssertTrue(releases.isEmpty)
    }
    
    // MARK: - Inverse Relationships
    
    func testLookupReleaseRoundtrip() async throws {
        // Given: A release ID
        let releaseID = 123
        let client = MockDiscogsClient()
        let expectedRelease = DiscogsRelease(
            id: releaseID,
            title: "Test Album",
            artist: "Test Artist",
            year: 2020
        )
        client.mockRelease = expectedRelease
        
        // When: Looking up the same release twice
        let release1 = try await client.lookupRelease(releaseID: releaseID)
        let release2 = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: Same result is returned (inverse: consistent results)
        XCTAssertEqual(release1, release2)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testReleaseMetadataStructure() async throws {
        // Given: A release with all fields
        let releaseID = 123
        let client = MockDiscogsClient()
        let track1 = DiscogsTrack(
            title: "Track 1",
            position: "A1",
            duration: "3:30"
        )
        let expectedRelease = DiscogsRelease(
            id: releaseID,
            title: "Test Album",
            artist: "Test Artist",
            artistIDs: [1, 2],
            year: 2020,
            format: "LP",
            genres: ["Rock", "Pop"],
            styles: ["Progressive Rock"],
            tracks: [track1],
            label: "Test Label",
            catalogNumber: "TEST-001",
            country: "US"
        )
        client.mockRelease = expectedRelease
        
        // When: Looking up the release
        let release = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: All fields are correctly populated (cross-check: structure validation)
        XCTAssertEqual(release.id, releaseID)
        XCTAssertEqual(release.title, "Test Album")
        XCTAssertEqual(release.artist, "Test Artist")
        XCTAssertEqual(release.artistIDs.count, 2)
        XCTAssertEqual(release.year, 2020)
        XCTAssertEqual(release.format, "LP")
        XCTAssertEqual(release.genres.count, 2)
        XCTAssertEqual(release.styles.count, 1)
        XCTAssertEqual(release.tracks.count, 1)
        XCTAssertEqual(release.label, "Test Label")
        XCTAssertEqual(release.catalogNumber, "TEST-001")
        XCTAssertEqual(release.country, "US")
    }
    
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
