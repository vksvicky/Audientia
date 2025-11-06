// ArtistTests.swift
// Audientia - TDD/BDD Tests for Artist Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import Shared
import XCTest

/// BDD-style test suite for Artist model
/// Following Right-BICEP principles
final class ArtistTests: XCTestCase {

    // MARK: - [Right] Tests

    /// BDD: Given a valid artist, when I create it, then all properties should be set correctly
    func testArtistCreationWithAllProperties() {
        // Given
        let id = UUID()
        let name = "Queen"
        let albumCount = 15
        let trackCount = 180

        // When
        let artist = Artist(
            id: id,
            name: name,
            albumCount: albumCount,
            trackCount: trackCount
        )

        // Then
        XCTAssertEqual(artist.id, id, "Artist ID should match")
        XCTAssertEqual(artist.name, name, "Artist name should match")
        XCTAssertEqual(artist.albumCount, albumCount, "Album count should match")
        XCTAssertEqual(artist.trackCount, trackCount, "Track count should match")
    }

    /// BDD: Given a minimal artist, when I create it, then counts should be zero
    func testArtistCreationWithMinimalProperties() {
        // Given & When
        let artist = MockFactory.makeMinimalArtist()

        // Then
        XCTAssertNotNil(artist.id, "Artist ID should be generated")
        XCTAssertFalse(artist.name.isEmpty, "Artist name should not be empty")
        XCTAssertEqual(artist.albumCount, 0, "Album count should be 0 for minimal artist")
        XCTAssertEqual(artist.trackCount, 0, "Track count should be 0 for minimal artist")
    }

    // MARK: - [B]oundary Condition Tests

    /// BDD: Given an artist with zero albums and tracks, when I create it, then it should be valid
    func testArtistWithZeroCounts() {
        // Given & When
        let artist = Artist(
            id: UUID(),
            name: "New Artist",
            albumCount: 0,
            trackCount: 0
        )

        // Then
        XCTAssertEqual(artist.albumCount, 0, "Zero album count should be valid")
        XCTAssertEqual(artist.trackCount, 0, "Zero track count should be valid")
    }

    /// BDD: Given an artist with very many albums and tracks, when I create it, then it should be valid
    func testArtistWithManyCounts() {
        // Given & When
        let artist = Artist(
            id: UUID(),
            name: "Prolific Artist",
            albumCount: 1000,
            trackCount: 10000
        )

        // Then
        XCTAssertEqual(artist.albumCount, 1000, "Large album count should be valid")
        XCTAssertEqual(artist.trackCount, 10000, "Large track count should be valid")
    }

    /// BDD: Given an artist with empty name, when I create it, then it should be valid
    func testArtistWithEmptyName() {
        // Given & When
        let artist = Artist(
            id: UUID(),
            name: "",
            albumCount: 0,
            trackCount: 0
        )

        // Then
        XCTAssertTrue(artist.name.isEmpty, "Empty name should be valid")
    }

    // MARK: - [I]nverse Relationship Tests

    /// BDD: Given an artist, when I encode and decode it, then the result should match the original
    func testArtistEncodingAndDecodingRoundtrip() throws {
        // Given
        let originalArtist = MockFactory.makeArtist()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalArtist)
        let decoder = JSONDecoder()
        let decodedArtist = try decoder.decode(Artist.self, from: data)

        // Then
        XCTAssertEqual(decodedArtist.id, originalArtist.id, "ID should match after roundtrip")
        XCTAssertEqual(decodedArtist.name, originalArtist.name, "Name should match after roundtrip")
        XCTAssertEqual(decodedArtist.albumCount, originalArtist.albumCount, "Album count should match after roundtrip")
        XCTAssertEqual(decodedArtist.trackCount, originalArtist.trackCount, "Track count should match after roundtrip")
    }

    /// BDD: Given two artists with same properties, when I compare them, then they should be equal
    func testArtistEquality() {
        // Given
        let id = UUID()
        let artist1 = Artist(
            id: id,
            name: "Test Artist",
            albumCount: 5,
            trackCount: 50
        )
        let artist2 = Artist(
            id: id,
            name: "Test Artist",
            albumCount: 5,
            trackCount: 50
        )

        // When & Then
        XCTAssertEqual(artist1, artist2, "Artists with same properties should be equal")
    }

    // MARK: - [C]ross-Check Tests

    /// BDD: Given an artist JSON, when I decode it, then it should match the expected structure
    func testArtistDecodingFromJSON() throws {
        // Given
        let json = TestFixtures.sampleArtistJSON

        // When
        let artist = try TestFixtures.decodeArtist(from: json)

        // Then
        XCTAssertEqual(artist.name, "Queen", "Decoded name should match")
        XCTAssertEqual(artist.albumCount, 15, "Decoded album count should match")
        XCTAssertEqual(artist.trackCount, 180, "Decoded track count should match")
    }

    // MARK: - [E]rror Condition Tests

    /// BDD: Given invalid JSON, when I decode it, then it should throw an error
    func testArtistDecodingWithInvalidJSON() {
        // Given
        let invalidJSON = "{ invalid json }"

        // When & Then
        XCTAssertThrowsError(try TestFixtures.decodeArtist(from: invalidJSON), "Invalid JSON should throw error")
    }

    // MARK: - [P]erformance Tests

    /// BDD: Given many artists, when I encode them, then it should complete quickly
    func testArtistEncodingPerformance() {
        // Given
        let artists = (0..<1000).map { index in
            MockFactory.makeArtist(name: "Artist \(index)")
        }

        // When & Then
        measure {
            let encoder = JSONEncoder()
            for artist in artists {
                _ = try? encoder.encode(artist)
            }
        }
    }

    // MARK: - Edge Case Tests

    /// BDD: Given an artist with Unicode characters, when I encode and decode it, then it should preserve Unicode
    func testArtistWithUnicodeCharacters() throws {
        // Given
        let artist = Artist(
            id: UUID(),
            name: "アーティスト",
            albumCount: 10,
            trackCount: 100
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(artist)
        let decoder = JSONDecoder()
        let decodedArtist = try decoder.decode(Artist.self, from: data)

        // Then
        XCTAssertEqual(decodedArtist.name, artist.name, "Unicode name should be preserved")
    }

    /// BDD: Given an artist with special characters, when I encode and decode it, then it should preserve them
    func testArtistWithSpecialCharacters() throws {
        // Given
        let artist = Artist(
            id: UUID(),
            name: "Artist & The Band / Feat. Guest",
            albumCount: 5,
            trackCount: 50
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(artist)
        let decoder = JSONDecoder()
        let decodedArtist = try decoder.decode(Artist.self, from: data)

        // Then
        XCTAssertEqual(decodedArtist.name, artist.name, "Special characters should be preserved")
    }
}
