//
//  DiscogsBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for Discogs API client
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// BDD tests for Discogs API client following user-centric scenarios
final class DiscogsBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    func testUserWantsToSearchForAlbumOnDiscogs() async throws {
        // Scenario: As a user, I want to search for an album on Discogs
        
        // Given: I know the artist and album title
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
        
        // When: I search for the album
        let releases = try await client.searchReleases(query: query)
        
        // Then: I see multiple matching releases with different formats and years
        XCTAssertEqual(releases.count, 2)
        XCTAssertTrue(releases.allSatisfy { $0.artist == "Queen" })
        XCTAssertTrue(releases.allSatisfy { $0.title.contains("A Night at the Opera") })
        XCTAssertEqual(releases[0].year, 1975)
        XCTAssertEqual(releases[0].format, "LP")
        XCTAssertEqual(releases[1].year, 2011)
        XCTAssertEqual(releases[1].format, "CD")
    }
    
    func testUserWantsToViewAlbumDetailsWithTracks() async throws {
        // Scenario: As a user, I want to view album details including all tracks
        
        // Given: I have a Discogs release ID
        let releaseID = 123
        let client = MockDiscogsClient()
        
        let tracks = [
            DiscogsTrack(title: "Death on Two Legs", position: "A1", duration: "3:43"),
            DiscogsTrack(title: "Lazing on a Sunday Afternoon", position: "A2", duration: "1:07"),
            DiscogsTrack(title: "I'm in Love with My Car", position: "A3", duration: "3:05"),
            DiscogsTrack(title: "You're My Best Friend", position: "A4", duration: "2:50"),
            DiscogsTrack(title: "39", position: "A5", duration: "3:30")
        ]
        
        let release = DiscogsRelease(
            id: releaseID,
            title: "A Night at the Opera",
            artist: "Queen",
            year: 1975,
            format: "LP",
            genres: ["Rock"],
            styles: ["Progressive Rock"],
            tracks: tracks,
            label: "EMI",
            catalogNumber: "EMA 784",
            country: "UK"
        )
        client.mockRelease = release
        
        // When: I look up the release
        let result = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: I see complete album details including all tracks, label, and catalog number
        XCTAssertEqual(result.title, "A Night at the Opera")
        XCTAssertEqual(result.artist, "Queen")
        XCTAssertEqual(result.year, 1975)
        XCTAssertEqual(result.format, "LP")
        XCTAssertEqual(result.tracks.count, 5)
        XCTAssertEqual(result.tracks[0].title, "Death on Two Legs")
        XCTAssertEqual(result.tracks[0].position, "A1")
        XCTAssertEqual(result.label, "EMI")
        XCTAssertEqual(result.catalogNumber, "EMA 784")
        XCTAssertEqual(result.country, "UK")
    }
    
    func testUserWantsToHandleReleaseNotFound() async {
        // Scenario: As a user, I want to handle cases where a release is not found
        
        // Given: I have a release ID that doesn't exist in Discogs
        let releaseID = 999999
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.releaseNotFound(releaseID)
        
        // When: I try to look up the release
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            // Then: I see a clear message that the release was not found
            XCTAssertEqual(error, .releaseNotFound(releaseID))
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserWantsToHandleNetworkErrorsGracefully() async {
        // Scenario: As a user, I want network errors to be handled gracefully
        
        // Given: I have a network connection issue
        let releaseID = 123
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.networkError("Connection timeout")
        
        // When: I try to look up a release
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            // Then: I see a clear error message about the network issue
            XCTAssertEqual(error, .networkError("Connection timeout"))
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserWantsToHandleRateLimitErrors() async {
        // Scenario: As a user, I want rate limit errors to be handled gracefully
        
        // Given: I have exceeded the API rate limit
        let releaseID = 123
        let client = MockDiscogsClient()
        client.shouldFail = true
        client.errorToThrow = DiscogsError.rateLimitExceeded
        
        // When: I try to look up a release
        do {
            _ = try await client.lookupRelease(releaseID: releaseID)
            XCTFail("Should have thrown an error")
        } catch let error as DiscogsError {
            // Then: I see a clear message about rate limiting
            XCTAssertEqual(error, .rateLimitExceeded)
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserWantsToSeePartialMetadataWhenAvailable() async throws {
        // Scenario: As a user, I want to see partial metadata when full metadata isn't available
        
        // Given: I have a release with incomplete metadata
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
        
        // When: I look up the release
        let release = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: I see the available metadata (title and artist) even though other fields are missing
        XCTAssertEqual(release.title, "Unknown Album")
        XCTAssertEqual(release.artist, "Unknown Artist")
        XCTAssertNil(release.year)
        XCTAssertTrue(release.genres.isEmpty)
    }
    
    func testUserWantsToSearchForArtists() async throws {
        // Scenario: As a user, I want to search for artists on Discogs
        
        // Given: I know the artist name
        let query = "Queen"
        let client = MockDiscogsClient()
        
        let artist1 = DiscogsArtist(
            id: 1,
            name: "Queen",
            profile: "British rock band formed in 1970",
            realName: nil
        )
        let artist2 = DiscogsArtist(
            id: 2,
            name: "Queen (2)",
            profile: "Different artist with same name",
            realName: nil
        )
        client.mockSearchArtists = [artist1, artist2]
        
        // When: I search for the artist
        let artists = try await client.searchArtists(query: query)
        
        // Then: I see multiple matching artists
        XCTAssertEqual(artists.count, 2)
        XCTAssertTrue(artists.allSatisfy { $0.name.contains("Queen") })
        XCTAssertEqual(artists[0].profile, "British rock band formed in 1970")
    }
    
    func testUserWantsToSeeReleaseWithGenresAndStyles() async throws {
        // Scenario: As a user, I want to see genres and styles for an album
        
        // Given: I have a release with genres and styles
        let releaseID = 123
        let client = MockDiscogsClient()
        
        let release = DiscogsRelease(
            id: releaseID,
            title: "A Night at the Opera",
            artist: "Queen",
            year: 1975,
            genres: ["Rock", "Progressive Rock"],
            styles: ["Progressive Rock", "Art Rock", "Arena Rock"]
        )
        client.mockRelease = release
        
        // When: I look up the release
        let result = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: I see genres and styles for categorization
        XCTAssertEqual(result.genres.count, 2)
        XCTAssertTrue(result.genres.contains("Rock"))
        XCTAssertTrue(result.genres.contains("Progressive Rock"))
        XCTAssertEqual(result.styles.count, 3)
        XCTAssertTrue(result.styles.contains("Progressive Rock"))
        XCTAssertTrue(result.styles.contains("Art Rock"))
    }
}
