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
}
