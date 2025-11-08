//
//  LibrarySearchBDDTests.swift
//  DataLayerTests
//
//  BDD-style tests for library search functionality
//  Implements: "As a user, I want to search my music library by title, artist, or album"
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// BDD-style test suite for library search
/// Implements: "As a user, I want to search my music library by title, artist, or album"
@MainActor
final class LibrarySearchBDDTests: XCTestCase {
    
    var indexer: LibraryIndexer!
    var search: LibrarySearch!
    
    override func setUp() async throws {
        try await super.setUp()
        indexer = LibraryIndexer()
        search = LibrarySearch(indexer: indexer)
        
        // Index test tracks for search scenarios
        let tracks = [
            createTrack(title: "Blue Moon", artist: "Frank Sinatra", album: "Classic Standards"),
            createTrack(title: "Moon River", artist: "Andy Williams", album: "Moon River and Other Great Movie Themes"),
            createTrack(title: "Fly Me to the Moon", artist: "Frank Sinatra", album: "It Might as Well Be Swing"),
            createTrack(title: "Stardust", artist: "Nat King Cole", album: "The Nat King Cole Story"),
            createTrack(title: "Autumn Leaves", artist: "Nat King Cole", album: "Love Is the Thing")
        ]
        try await indexer.index(tracks: tracks)
    }
    
    override func tearDown() async throws {
        try await indexer.clear()
        indexer = nil
        search = nil
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Search by Title
    
    /// BDD: As a user, when I search for a song title, then I should see all matching tracks
    func testUserSearchesByTitleAndSeesMatchingTracks() async throws {
        // Given - User has a music library with various tracks
        // When - User searches for "Moon"
        let results = try await search.search(query: "Moon", field: .title)
        
        // Then - Should find tracks with "Moon" in the title
        XCTAssertEqual(results.count, 3, "Should find 3 tracks with 'Moon' in title")
        XCTAssertTrue(results.allSatisfy { $0.title.contains("Moon") }, "All results should have 'Moon' in title")
        XCTAssertTrue(results.contains { $0.title == "Blue Moon" }, "Should find 'Blue Moon'")
        XCTAssertTrue(results.contains { $0.title == "Moon River" }, "Should find 'Moon River'")
        XCTAssertTrue(results.contains { $0.title == "Fly Me to the Moon" }, "Should find 'Fly Me to the Moon'")
    }
    
    // MARK: - User Scenario: Search by Artist
    
    /// BDD: As a user, when I search for an artist name, then I should see all tracks by that artist
    func testUserSearchesByArtistAndSeesAllTracksByArtist() async throws {
        // Given - User has a music library with tracks by various artists
        // When - User searches for "Frank Sinatra"
        let results = try await search.search(query: "Frank Sinatra", field: .artist)
        
        // Then - Should find all tracks by Frank Sinatra
        XCTAssertEqual(results.count, 2, "Should find 2 tracks by Frank Sinatra")
        XCTAssertTrue(results.allSatisfy { $0.artist == "Frank Sinatra" }, "All results should be by Frank Sinatra")
        XCTAssertTrue(results.contains { $0.title == "Blue Moon" }, "Should find 'Blue Moon'")
        XCTAssertTrue(results.contains { $0.title == "Fly Me to the Moon" }, "Should find 'Fly Me to the Moon'")
    }
    
    // MARK: - User Scenario: Search by Album
    
    /// BDD: As a user, when I search for an album name, then I should see all tracks from that album
    func testUserSearchesByAlbumAndSeesAllTracksFromAlbum() async throws {
        // Given - User has a music library with tracks from various albums
        // When - User searches for "Classic Standards"
        let results = try await search.search(query: "Classic Standards", field: .album)
        
        // Then - Should find all tracks from "Classic Standards" album
        XCTAssertEqual(results.count, 1, "Should find 1 track from 'Classic Standards' album")
        XCTAssertTrue(results.allSatisfy { $0.album == "Classic Standards" }, "All results should be from 'Classic Standards' album")
        XCTAssertTrue(results.contains { $0.title == "Blue Moon" }, "Should find 'Blue Moon' from the album")
    }
    
    // MARK: - User Scenario: Search Across All Fields
    
    /// BDD: As a user, when I search without specifying a field, then I should see tracks matching in any field
    func testUserSearchesAcrossAllFieldsAndSeesMatchingTracks() async throws {
        // Given - User has a music library
        // When - User searches for "Nat King Cole" across all fields
        let results = try await search.search(query: "Nat King Cole", field: .all)
        
        // Then - Should find tracks where "Nat King Cole" appears in any field
        XCTAssertEqual(results.count, 2, "Should find 2 tracks with 'Nat King Cole' in any field")
        XCTAssertTrue(
            results.allSatisfy { track in
                track.title.contains("Nat King Cole") ||
                track.artist.contains("Nat King Cole") ||
                track.album.contains("Nat King Cole")
            },
            "All results should contain 'Nat King Cole' in at least one field"
        )
        XCTAssertTrue(results.allSatisfy { $0.artist == "Nat King Cole" }, "All results should be by Nat King Cole")
    }
    
    /// BDD: As a user, when I search for a common word, then I should see all tracks containing that word
    func testUserSearchesForCommonWordAndSeesAllMatchingTracks() async throws {
        // Given - User has a music library
        // When - User searches for "Moon" across all fields
        let results = try await search.search(query: "Moon", field: .all)
        
        // Then - Should find all tracks containing "Moon" in any field
        // Note: "Moon River" album also contains "Moon", so we get 3 tracks (all have "Moon" in title)
        XCTAssertEqual(results.count, 3, "Should find 3 tracks with 'Moon' in any field")
        XCTAssertTrue(
            results.allSatisfy { track in
                track.title.contains("Moon") ||
                track.artist.contains("Moon") ||
                track.album.contains("Moon")
            },
            "All results should contain 'Moon' in at least one field"
        )
    }
    
    // MARK: - User Scenario: Case-Insensitive Search
    
    /// BDD: As a user, when I search with different cases, then I should see the same results
    func testUserSearchesWithDifferentCasesAndSeesSameResults() async throws {
        // Given - User has a music library
        // When - User searches with lowercase
        let resultsLower = try await search.search(query: "frank", field: .all)
        
        // And - User searches with uppercase
        let resultsUpper = try await search.search(query: "FRANK", field: .all)
        
        // And - User searches with mixed case
        let resultsMixed = try await search.search(query: "FrAnK", field: .all)
        
        // Then - All searches should return the same results
        XCTAssertEqual(resultsLower.count, resultsUpper.count, "Case should not affect search results")
        XCTAssertEqual(resultsLower.count, resultsMixed.count, "Case should not affect search results")
        XCTAssertEqual(Set(resultsLower.map { $0.id }), Set(resultsUpper.map { $0.id }), "Results should be identical regardless of case")
    }
    
    // MARK: - User Scenario: No Results
    
    /// BDD: As a user, when I search for something that doesn't exist, then I should see no results
    func testUserSearchesForNonExistentTermAndSeesNoResults() async throws {
        // Given - User has a music library
        // When - User searches for a term that doesn't exist
        let results = try await search.search(query: "NonExistentArtist12345", field: .all)
        
        // Then - Should see no results
        XCTAssertTrue(results.isEmpty, "Should return empty results for non-existent term")
    }
    
    // MARK: - Helper Methods
    
    private func createTrack(
        title: String,
        artist: String,
        album: String = "Unknown Album",
        filePath: String? = nil
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: filePath ?? "/path/to/\(title.replacingOccurrences(of: " ", with: "_")).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1
        )
    }
}
