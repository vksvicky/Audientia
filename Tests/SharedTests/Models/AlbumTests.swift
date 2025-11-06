// AlbumTests.swift
// Audientia - TDD/BDD Tests for Album Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import Shared
import XCTest

/// BDD-style test suite for Album model
/// Following Right-BICEP principles
final class AlbumTests: XCTestCase {

    // MARK: - [Right] Tests

    /// BDD: Given a valid album, when I create it, then all properties should be set correctly
    func testAlbumCreationWithAllProperties() {
        // Given
        let id = UUID()
        let title = "A Night at the Opera"
        let artist = "Queen"
        let year = 1975
        let genre = "Rock"
        let trackCount = 12
        let totalDuration: TimeInterval = 4320.0

        // When
        let album = Album(
            id: id,
            title: title,
            artist: artist,
            year: year,
            genre: genre,
            trackCount: trackCount,
            totalDuration: totalDuration
        )

        // Then
        XCTAssertEqual(album.id, id, "Album ID should match")
        XCTAssertEqual(album.title, title, "Album title should match")
        XCTAssertEqual(album.artist, artist, "Album artist should match")
        XCTAssertEqual(album.year, year, "Album year should match")
        XCTAssertEqual(album.genre, genre, "Album genre should match")
        XCTAssertEqual(album.trackCount, trackCount, "Track count should match")
        XCTAssertEqual(album.totalDuration, totalDuration, accuracy: 0.01, "Total duration should match")
    }

    /// BDD: Given a minimal album, when I create it, then optional properties should be nil
    func testAlbumCreationWithMinimalProperties() {
        // Given & When
        let album = MockFactory.makeMinimalAlbum()

        // Then
        XCTAssertNotNil(album.id, "Album ID should be generated")
        XCTAssertFalse(album.title.isEmpty, "Album title should not be empty")
        XCTAssertNil(album.year, "Year should be nil for minimal album")
        XCTAssertNil(album.genre, "Genre should be nil for minimal album")
        XCTAssertEqual(album.trackCount, 0, "Track count should be 0 for minimal album")
        XCTAssertEqual(album.totalDuration, 0.0, "Total duration should be 0 for minimal album")
    }

    // MARK: - [B]oundary Condition Tests

    /// BDD: Given an album with zero tracks, when I create it, then it should be valid
    func testAlbumWithZeroTracks() {
        // Given & When
        let album = Album(
            id: UUID(),
            title: "Empty Album",
            artist: "Test Artist",
            year: nil,
            genre: nil,
            trackCount: 0,
            totalDuration: 0.0
        )

        // Then
        XCTAssertEqual(album.trackCount, 0, "Zero track count should be valid")
        XCTAssertEqual(album.totalDuration, 0.0, "Zero duration should be valid")
    }

    /// BDD: Given an album with very many tracks, when I create it, then it should be valid
    func testAlbumWithManyTracks() {
        // Given & When
        let album = Album(
            id: UUID(),
            title: "Large Album",
            artist: "Test Artist",
            year: 2024,
            genre: "Various",
            trackCount: 1000,
            totalDuration: 36000.0
        )

        // Then
        XCTAssertEqual(album.trackCount, 1000, "Large track count should be valid")
        XCTAssertEqual(album.totalDuration, 36000.0, accuracy: 0.01, "Large duration should be valid")
    }

    /// BDD: Given an album with very old year, when I create it, then it should be valid
    func testAlbumWithVeryOldYear() {
        // Given & When
        let album = Album(
            id: UUID(),
            title: "Old Album",
            artist: "Test Artist",
            year: 1900,
            genre: "Classical",
            trackCount: 10,
            totalDuration: 1800.0
        )

        // Then
        XCTAssertEqual(album.year, 1900, "Very old year should be valid")
    }

    /// BDD: Given an album with future year, when I create it, then it should be valid
    func testAlbumWithFutureYear() {
        // Given & When
        let futureYear = Calendar.current.component(.year, from: Date()) + 10
        let album = Album(
            id: UUID(),
            title: "Future Album",
            artist: "Test Artist",
            year: futureYear,
            genre: "Electronic",
            trackCount: 15,
            totalDuration: 2700.0
        )

        // Then
        XCTAssertEqual(album.year, futureYear, "Future year should be valid")
    }

    // MARK: - [I]nverse Relationship Tests

    /// BDD: Given an album, when I encode and decode it, then the result should match the original
    func testAlbumEncodingAndDecodingRoundtrip() throws {
        // Given
        let originalAlbum = MockFactory.makeAlbum()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalAlbum)
        let decoder = JSONDecoder()
        let decodedAlbum = try decoder.decode(Album.self, from: data)

        // Then
        XCTAssertEqual(decodedAlbum.id, originalAlbum.id, "ID should match after roundtrip")
        XCTAssertEqual(decodedAlbum.title, originalAlbum.title, "Title should match after roundtrip")
        XCTAssertEqual(decodedAlbum.artist, originalAlbum.artist, "Artist should match after roundtrip")
        XCTAssertEqual(decodedAlbum.year, originalAlbum.year, "Year should match after roundtrip")
        XCTAssertEqual(decodedAlbum.genre, originalAlbum.genre, "Genre should match after roundtrip")
        XCTAssertEqual(decodedAlbum.trackCount, originalAlbum.trackCount, "Track count should match after roundtrip")
        XCTAssertEqual(decodedAlbum.totalDuration, originalAlbum.totalDuration, accuracy: 0.01, "Duration should match after roundtrip")
    }

    /// BDD: Given two albums with same properties, when I compare them, then they should be equal
    func testAlbumEquality() {
        // Given
        let id = UUID()
        let album1 = Album(
            id: id,
            title: "Test Album",
            artist: "Test Artist",
            year: 2024,
            genre: "Rock",
            trackCount: 10,
            totalDuration: 1800.0
        )
        let album2 = Album(
            id: id,
            title: "Test Album",
            artist: "Test Artist",
            year: 2024,
            genre: "Rock",
            trackCount: 10,
            totalDuration: 1800.0
        )

        // When & Then
        XCTAssertEqual(album1, album2, "Albums with same properties should be equal")
    }

    // MARK: - [C]ross-Check Tests

    /// BDD: Given an album JSON, when I decode it, then it should match the expected structure
    func testAlbumDecodingFromJSON() throws {
        // Given
        let json = TestFixtures.sampleAlbumJSON

        // When
        let album = try TestFixtures.decodeAlbum(from: json)

        // Then
        XCTAssertEqual(album.title, "A Night at the Opera", "Decoded title should match")
        XCTAssertEqual(album.artist, "Queen", "Decoded artist should match")
        XCTAssertEqual(album.year, 1975, "Decoded year should match")
        XCTAssertEqual(album.trackCount, 12, "Decoded track count should match")
    }

    // MARK: - [E]rror Condition Tests

    /// BDD: Given invalid JSON, when I decode it, then it should throw an error
    func testAlbumDecodingWithInvalidJSON() {
        // Given
        let invalidJSON = "{ invalid json }"

        // When & Then
        XCTAssertThrowsError(try TestFixtures.decodeAlbum(from: invalidJSON), "Invalid JSON should throw error")
    }

    // MARK: - [P]erformance Tests

    /// BDD: Given many albums, when I encode them, then it should complete quickly
    func testAlbumEncodingPerformance() {
        // Given
        let albums = (0..<1000).map { index in
            MockFactory.makeAlbum(title: "Album \(index)")
        }

        // When & Then
        measure {
            let encoder = JSONEncoder()
            for album in albums {
                _ = try? encoder.encode(album)
            }
        }
    }

    // MARK: - Edge Case Tests

    /// BDD: Given an album with Unicode characters, when I encode and decode it, then it should preserve Unicode
    func testAlbumWithUnicodeCharacters() throws {
        // Given
        let album = Album(
            id: UUID(),
            title: "アルバム",
            artist: "アーティスト",
            year: 2024,
            genre: "J-Pop",
            trackCount: 10,
            totalDuration: 1800.0
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(album)
        let decoder = JSONDecoder()
        let decodedAlbum = try decoder.decode(Album.self, from: data)

        // Then
        XCTAssertEqual(decodedAlbum.title, album.title, "Unicode title should be preserved")
        XCTAssertEqual(decodedAlbum.artist, album.artist, "Unicode artist should be preserved")
    }
}
