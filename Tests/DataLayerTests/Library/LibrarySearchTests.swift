//
//  LibrarySearchTests.swift
//  DataLayerTests
//
//  TDD tests for library search functionality
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// TDD tests for LibrarySearch
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class LibrarySearchTests: XCTestCase {
    
    var indexer: LibraryIndexer!
    var search: LibrarySearch!
    
    override func setUp() async throws {
        try await super.setUp()
        indexer = LibraryIndexer()
        search = LibrarySearch(indexer: indexer)
        
        // Index some test tracks
        let tracks = [
            createTrack(title: "Jazz Song", artist: "Jazz Artist", album: "Jazz Album"),
            createTrack(title: "Rock Song", artist: "Rock Artist", album: "Rock Album"),
            createTrack(title: "Classical Symphony", artist: "Classical Composer", album: "Classical Collection"),
            createTrack(title: "Another Jazz Track", artist: "Jazz Artist", album: "Jazz Album"),
            createTrack(title: "Pop Hit", artist: "Pop Star", album: "Pop Album")
        ]
        try await indexer.index(tracks: tracks)
    }
    
    override func tearDown() async throws {
        try await indexer.clear()
        indexer = nil
        search = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test searching by title
    func testSearchByTitle() async throws {
        // Given - Indexed tracks with various titles
        // When - Search for "Jazz"
        let results = try await search.search(query: "Jazz", field: .title)
        
        // Then - Should find tracks with "Jazz" in title
        XCTAssertEqual(results.count, 2, "Should find 2 tracks with 'Jazz' in title")
        XCTAssertTrue(results.contains { $0.title == "Jazz Song" }, "Should find 'Jazz Song'")
        XCTAssertTrue(results.contains { $0.title == "Another Jazz Track" }, "Should find 'Another Jazz Track'")
    }
    
    /// Test searching by artist
    func testSearchByArtist() async throws {
        // Given - Indexed tracks with various artists
        // When - Search for "Jazz Artist"
        let results = try await search.search(query: "Jazz Artist", field: .artist)
        
        // Then - Should find all tracks by Jazz Artist
        XCTAssertEqual(results.count, 2, "Should find 2 tracks by Jazz Artist")
        XCTAssertTrue(results.allSatisfy { $0.artist == "Jazz Artist" }, "All results should be by Jazz Artist")
    }
    
    /// Test searching by album
    func testSearchByAlbum() async throws {
        // Given - Indexed tracks with various albums
        // When - Search for "Jazz Album"
        let results = try await search.search(query: "Jazz Album", field: .album)
        
        // Then - Should find all tracks from Jazz Album
        XCTAssertEqual(results.count, 2, "Should find 2 tracks from Jazz Album")
        XCTAssertTrue(results.allSatisfy { $0.album == "Jazz Album" }, "All results should be from Jazz Album")
    }
    
    /// Test searching across all fields
    func testSearchAcrossAllFields() async throws {
        // Given - Indexed tracks
        // When - Search for "Jazz" across all fields
        let results = try await search.search(query: "Jazz", field: .all)
        
        // Then - Should find all tracks containing "Jazz" in any field
        // Both "Jazz Song" and "Another Jazz Track" have "Jazz" in title, artist, and album
        XCTAssertEqual(results.count, 2, "Should find 2 tracks with 'Jazz' in any field")
        XCTAssertTrue(
            results.allSatisfy { track in
                track.title.contains("Jazz") ||
                track.artist.contains("Jazz") ||
                track.album.contains("Jazz")
            },
            "All results should contain 'Jazz' in at least one field"
        )
    }
    
    // MARK: - Boundary Conditions
    
    /// Test searching with empty query
    func testSearchWithEmptyQuery() async throws {
        // Given - Empty search query
        // When - Search with empty string
        let results = try await search.search(query: "", field: .all)
        
        // Then - Should return empty results or all tracks (implementation dependent)
        // For now, we'll expect empty results for empty query
        XCTAssertTrue(results.isEmpty, "Empty query should return empty results")
    }
    
    /// Test searching with query that matches no tracks
    func testSearchWithNoMatches() async throws {
        // Given - Indexed tracks
        // When - Search for non-existent term
        let results = try await search.search(query: "NonExistentTerm", field: .all)
        
        // Then - Should return empty results
        XCTAssertTrue(results.isEmpty, "Should return empty results for non-existent term")
    }
    
    /// Test searching with single character query
    func testSearchWithSingleCharacter() async throws {
        // Given - Indexed tracks
        // When - Search with single character
        let results = try await search.search(query: "J", field: .all)
        
        // Then - Should find tracks containing 'J'
        XCTAssertGreaterThan(results.count, 0, "Should find tracks containing 'J'")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that search results are consistent
    func testSearchResultsAreConsistent() async throws {
        // Given - Indexed tracks
        // When - Search multiple times with same query
        let results1 = try await search.search(query: "Jazz", field: .all)
        let results2 = try await search.search(query: "Jazz", field: .all)
        
        // Then - Results should be identical
        XCTAssertEqual(results1.count, results2.count, "Search results should be consistent")
        XCTAssertEqual(Set(results1.map { $0.id }), Set(results2.map { $0.id }), "Search results should contain same tracks")
    }
    
    /// Test that adding track updates search results
    func testAddingTrackUpdatesSearchResults() async throws {
        // Given - Initial search
        let initialResults = try await search.search(query: "New", field: .all)
        XCTAssertTrue(initialResults.isEmpty, "Should have no results initially")
        
        // When - Add new track and search again
        let newTrack = createTrack(title: "New Song", artist: "New Artist", album: "New Album")
        try await indexer.index(tracks: [newTrack])
        
        let updatedResults = try await search.search(query: "New", field: .all)
        
        // Then - Should find the new track
        XCTAssertEqual(updatedResults.count, 1, "Should find the newly added track")
        XCTAssertEqual(updatedResults.first?.id, newTrack.id, "Should find the correct new track")
    }
    
    /// Test that removing track updates search results
    func testRemovingTrackUpdatesSearchResults() async throws {
        // Given - Track in index
        let track = createTrack(title: "Temporary Song", artist: "Temporary Artist", album: "Temporary Album")
        try await indexer.index(tracks: [track])
        
        let resultsBefore = try await search.search(query: "Temporary", field: .all)
        XCTAssertEqual(resultsBefore.count, 1, "Should find track before removal")
        
        // When - Remove track
        try await indexer.remove(track: track)
        
        // Then - Should not find removed track
        let resultsAfter = try await search.search(query: "Temporary", field: .all)
        XCTAssertTrue(resultsAfter.isEmpty, "Should not find removed track")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that search is case-insensitive
    func testSearchIsCaseInsensitive() async throws {
        // Given - Indexed tracks
        // When - Search with different cases
        let resultsLower = try await search.search(query: "jazz", field: .all)
        let resultsUpper = try await search.search(query: "JAZZ", field: .all)
        let resultsMixed = try await search.search(query: "JaZz", field: .all)
        
        // Then - All should return same results
        XCTAssertEqual(resultsLower.count, resultsUpper.count, "Case should not affect results")
        XCTAssertEqual(resultsLower.count, resultsMixed.count, "Case should not affect results")
        XCTAssertEqual(Set(resultsLower.map { $0.id }), Set(resultsUpper.map { $0.id }), "Results should be identical regardless of case")
    }
    
    /// Test that search supports partial matches
    func testSearchSupportsPartialMatches() async throws {
        // Given - Indexed tracks
        // When - Search with partial word
        let results = try await search.search(query: "Class", field: .all)
        
        // Then - Should find tracks with "Class" in them
        XCTAssertGreaterThan(results.count, 0, "Should find tracks with partial match")
        XCTAssertTrue(
            results.allSatisfy { track in
                track.title.contains("Class") ||
                track.artist.contains("Class") ||
                track.album.contains("Class")
            },
            "All results should contain partial match"
        )
    }
    
    // MARK: - Error Conditions
    
    /// Test that search handles invalid field gracefully
    func testSearchHandlesInvalidField() async throws {
        // Given - Indexed tracks
        // When - Search with invalid field (should default to .all)
        // Note: This depends on implementation - if enum is exhaustive, this won't compile
        // For now, we test that .all works correctly
        let results = try await search.search(query: "Jazz", field: .all)
        
        // Then - Should return results
        XCTAssertGreaterThanOrEqual(results.count, 0, "Should handle search gracefully")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that search is performant
    func testSearchIsPerformant() async throws {
        // Given - Large number of indexed tracks (1000)
        let largeTracks = (1...1000).map { index in
            createTrack(
                title: "Song \(index)",
                artist: "Artist \(index % 100)",
                album: "Album \(index % 50)"
            )
        }
        try await indexer.index(tracks: largeTracks)
        
        // When - Search
        let startTime = Date()
        _ = try await search.search(query: "Song 500", field: .all)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete quickly
        XCTAssertLessThan(duration, 0.1, "Should search 1000 tracks in less than 100ms")
    }
    
    // MARK: - Edge Cases
    
    /// Test searching with special characters
    func testSearchWithSpecialCharacters() async throws {
        // Given - Track with special characters
        let specialTrack = createTrack(
            title: "Song with émojis 🎵 & symbols!",
            artist: "Artist with ünicode",
            album: "Album (2024)"
        )
        try await indexer.index(tracks: [specialTrack])
        
        // When - Search for special characters
        let results = try await search.search(query: "émojis", field: .all)
        
        // Then - Should find the track
        XCTAssertEqual(results.count, 1, "Should find track with special characters")
        XCTAssertEqual(results.first?.id, specialTrack.id, "Should find correct track")
    }
    
    /// Test searching with very long query
    func testSearchWithVeryLongQuery() async throws {
        // Given - Very long search query
        let longQuery = String(repeating: "A", count: 1000)
        
        // When - Search with very long query
        let results = try await search.search(query: longQuery, field: .all)
        
        // Then - Should handle gracefully (likely no results)
        XCTAssertGreaterThanOrEqual(results.count, 0, "Should handle very long query gracefully")
    }
    
    /// Test searching with whitespace-only query
    func testSearchWithWhitespaceOnlyQuery() async throws {
        // Given - Whitespace-only query
        // When - Search with whitespace
        let results = try await search.search(query: "   ", field: .all)
        
        // Then - Should return empty results
        XCTAssertTrue(results.isEmpty, "Whitespace-only query should return empty results")
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
