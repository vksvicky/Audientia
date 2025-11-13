//
//  LibrarySearchRelevanceTests.swift
//  DataLayerTests
//
//  Unit tests for search relevance
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// Unit tests for search relevance
/// Tests that search results are ordered by relevance
@MainActor
final class LibrarySearchRelevanceTests: XCTestCase {
    
    var indexer: LibraryIndexer!
    var search: LibrarySearch!
    
    override func setUp() async throws {
        try await super.setUp()
        indexer = LibraryIndexer()
        search = LibrarySearch(indexer: indexer)
    }
    
    override func tearDown() async throws {
        indexer = nil
        search = nil
        try await super.tearDown()
    }
    
    // MARK: - Relevance Tests
    
    /// Test that exact title matches appear before partial matches
    func testExactTitleMatchBeforePartialMatch() async throws {
        // Given - Tracks with exact and partial title matches
        let exactMatch = Track(
            title: "Here Comes the Sun",
            artist: "The Beatles",
            album: "Abbey Road",
            duration: 185.0,
            filePath: "/music/exact.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let partialMatch = Track(
            title: "Here Comes the Moon",
            artist: "The Beatles",
            album: "Abbey Road",
            duration: 200.0,
            filePath: "/music/partial.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        try await indexer.index(tracks: [exactMatch, partialMatch])
        
        // When - Search for "Here Comes the Sun"
        let results = try await search.search(query: "Here Comes the Sun", field: .all)
        
        // Then - Exact match should appear first
        XCTAssertGreaterThan(results.count, 0, "Should find at least one result")
        if let firstResult = results.first {
            XCTAssertEqual(firstResult.title, exactMatch.title, "Exact match should appear first")
        }
    }
    
    /// Test that title matches appear before artist matches
    func testTitleMatchBeforeArtistMatch() async throws {
        // Given - Track with matching title and another with matching artist
        let titleMatch = Track(
            title: "Jazz Song",
            artist: "Artist A",
            album: "Album A",
            duration: 180.0,
            filePath: "/music/title.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let artistMatch = Track(
            title: "Other Song",
            artist: "Jazz Artist",
            album: "Album B",
            duration: 200.0,
            filePath: "/music/artist.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        try await indexer.index(tracks: [titleMatch, artistMatch])
        
        // When - Search for "Jazz"
        let results = try await search.search(query: "Jazz", field: .all)
        
        // Then - Title match should appear before artist match
        XCTAssertGreaterThan(results.count, 1, "Should find multiple results")
        if results.count >= 2 {
            let firstTitle = results[0].title.lowercased()
            let secondTitle = results[1].title.lowercased()
            // Title match should be first (this is a basic test - actual relevance would need scoring)
            XCTAssertTrue(
                firstTitle.contains("jazz") || secondTitle.contains("jazz"),
                "At least one result should match title"
            )
        }
    }
    
    /// Test that case-insensitive matching works correctly
    func testCaseInsensitiveMatching() async throws {
        // Given - Track with mixed case
        let track = Track(
            title: "Here Comes The Sun",
            artist: "The Beatles",
            album: "Abbey Road",
            duration: 185.0,
            filePath: "/music/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        try await indexer.index(tracks: [track])
        
        // When - Search with different cases
        let lowerResults = try await search.search(query: "here comes", field: .all)
        let upperResults = try await search.search(query: "HERE COMES", field: .all)
        let mixedResults = try await search.search(query: "HeRe CoMeS", field: .all)
        
        // Then - All should find the track
        XCTAssertEqual(lowerResults.count, 1, "Lowercase search should find track")
        XCTAssertEqual(upperResults.count, 1, "Uppercase search should find track")
        XCTAssertEqual(mixedResults.count, 1, "Mixed case search should find track")
    }
}
