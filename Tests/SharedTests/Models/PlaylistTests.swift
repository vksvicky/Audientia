// PlaylistTests.swift
// Audientia - TDD/BDD Tests for Playlist Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import Shared
import XCTest

/// BDD-style test suite for Playlist model
/// Following Right-BICEP principles
final class PlaylistTests: XCTestCase {

    // MARK: - [Right] Tests

    /// BDD: Given a valid playlist, when I create it, then all properties should be set correctly
    func testPlaylistCreationWithAllProperties() {
        // Given
        let id = UUID()
        let name = "My Favorites"
        let trackCount = 25
        let totalDuration: TimeInterval = 5400.0
        let isSmart = false

        // When
        let playlist = Playlist(
            id: id,
            name: name,
            trackCount: trackCount,
            totalDuration: totalDuration,
            isSmart: isSmart
        )

        // Then
        XCTAssertEqual(playlist.id, id, "Playlist ID should match")
        XCTAssertEqual(playlist.name, name, "Playlist name should match")
        XCTAssertEqual(playlist.trackCount, trackCount, "Track count should match")
        XCTAssertEqual(playlist.totalDuration, totalDuration, accuracy: 0.01, "Total duration should match")
        XCTAssertEqual(playlist.isSmart, isSmart, "isSmart flag should match")
    }

    /// BDD: Given a minimal playlist, when I create it, then counts should be zero
    func testPlaylistCreationWithMinimalProperties() {
        // Given & When
        let playlist = MockFactory.makeMinimalPlaylist()

        // Then
        XCTAssertNotNil(playlist.id, "Playlist ID should be generated")
        XCTAssertFalse(playlist.name.isEmpty, "Playlist name should not be empty")
        XCTAssertEqual(playlist.trackCount, 0, "Track count should be 0 for minimal playlist")
        XCTAssertEqual(playlist.totalDuration, 0.0, "Total duration should be 0 for minimal playlist")
        XCTAssertFalse(playlist.isSmart, "isSmart should be false for minimal playlist")
    }

    /// BDD: Given a smart playlist, when I create it, then isSmart should be true
    func testSmartPlaylistCreation() {
        // Given & When
        let playlist = MockFactory.makeSmartPlaylist()

        // Then
        XCTAssertTrue(playlist.isSmart, "Smart playlist should have isSmart = true")
    }

    // MARK: - [B]oundary Condition Tests

    /// BDD: Given a playlist with zero tracks, when I create it, then it should be valid
    func testPlaylistWithZeroTracks() {
        // Given & When
        let playlist = Playlist(
            id: UUID(),
            name: "Empty Playlist",
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: false
        )

        // Then
        XCTAssertEqual(playlist.trackCount, 0, "Zero track count should be valid")
        XCTAssertEqual(playlist.totalDuration, 0.0, "Zero duration should be valid")
    }

    /// BDD: Given a playlist with very many tracks, when I create it, then it should be valid
    func testPlaylistWithManyTracks() {
        // Given & When
        let playlist = Playlist(
            id: UUID(),
            name: "Large Playlist",
            trackCount: 10000,
            totalDuration: 360000.0,
            isSmart: false
        )

        // Then
        XCTAssertEqual(playlist.trackCount, 10000, "Large track count should be valid")
        XCTAssertEqual(playlist.totalDuration, 360000.0, accuracy: 0.01, "Large duration should be valid")
    }

    /// BDD: Given a playlist with empty name, when I create it, then it should be valid
    func testPlaylistWithEmptyName() {
        // Given & When
        let playlist = Playlist(
            id: UUID(),
            name: "",
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: false
        )

        // Then
        XCTAssertTrue(playlist.name.isEmpty, "Empty name should be valid")
    }

    // MARK: - [I]nverse Relationship Tests

    /// BDD: Given a playlist, when I encode and decode it, then the result should match the original
    func testPlaylistEncodingAndDecodingRoundtrip() throws {
        // Given
        let originalPlaylist = MockFactory.makePlaylist()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPlaylist)
        let decoder = JSONDecoder()
        let decodedPlaylist = try decoder.decode(Playlist.self, from: data)

        // Then
        XCTAssertEqual(decodedPlaylist.id, originalPlaylist.id, "ID should match after roundtrip")
        XCTAssertEqual(decodedPlaylist.name, originalPlaylist.name, "Name should match after roundtrip")
        XCTAssertEqual(decodedPlaylist.trackCount, originalPlaylist.trackCount, "Track count should match after roundtrip")
        XCTAssertEqual(decodedPlaylist.totalDuration, originalPlaylist.totalDuration, accuracy: 0.01, "Duration should match after roundtrip")
        XCTAssertEqual(decodedPlaylist.isSmart, originalPlaylist.isSmart, "isSmart flag should match after roundtrip")
    }

    /// BDD: Given two playlists with same properties, when I compare them, then they should be equal
    func testPlaylistEquality() {
        // Given
        let id = UUID()
        let playlist1 = Playlist(
            id: id,
            name: "Test Playlist",
            trackCount: 20,
            totalDuration: 3600.0,
            isSmart: false
        )
        let playlist2 = Playlist(
            id: id,
            name: "Test Playlist",
            trackCount: 20,
            totalDuration: 3600.0,
            isSmart: false
        )

        // When & Then
        XCTAssertEqual(playlist1, playlist2, "Playlists with same properties should be equal")
    }

    /// BDD: Given a regular and smart playlist, when I compare them, then they should not be equal
    func testPlaylistInequalityForSmartFlag() {
        // Given
        let id = UUID()
        let regularPlaylist = Playlist(
            id: id,
            name: "Regular Playlist",
            trackCount: 10,
            totalDuration: 1800.0,
            isSmart: false
        )
        let smartPlaylist = Playlist(
            id: id,
            name: "Regular Playlist",
            trackCount: 10,
            totalDuration: 1800.0,
            isSmart: true
        )

        // When & Then
        XCTAssertNotEqual(regularPlaylist, smartPlaylist, "Regular and smart playlists should not be equal")
    }

    // MARK: - [C]ross-Check Tests

    /// BDD: Given a playlist JSON, when I decode it, then it should match the expected structure
    func testPlaylistDecodingFromJSON() throws {
        // Given
        let json = TestFixtures.samplePlaylistJSON

        // When
        let playlist = try TestFixtures.decodePlaylist(from: json)

        // Then
        XCTAssertEqual(playlist.name, "My Favorites", "Decoded name should match")
        XCTAssertEqual(playlist.trackCount, 25, "Decoded track count should match")
        XCTAssertFalse(playlist.isSmart, "Decoded isSmart should be false")
    }

    /// BDD: Given a smart playlist JSON, when I decode it, then isSmart should be true
    func testSmartPlaylistDecodingFromJSON() throws {
        // Given
        let json = TestFixtures.sampleSmartPlaylistJSON

        // When
        let playlist = try TestFixtures.decodePlaylist(from: json)

        // Then
        XCTAssertEqual(playlist.name, "5-Star Songs", "Decoded name should match")
        XCTAssertTrue(playlist.isSmart, "Decoded isSmart should be true")
    }

    // MARK: - [E]rror Condition Tests

    /// BDD: Given invalid JSON, when I decode it, then it should throw an error
    func testPlaylistDecodingWithInvalidJSON() {
        // Given
        let invalidJSON = "{ invalid json }"

        // When & Then
        XCTAssertThrowsError(try TestFixtures.decodePlaylist(from: invalidJSON), "Invalid JSON should throw error")
    }

    // MARK: - [P]erformance Tests

    /// BDD: Given many playlists, when I encode them, then it should complete quickly
    func testPlaylistEncodingPerformance() {
        // Given
        let playlists = (0..<1000).map { index in
            MockFactory.makePlaylist(name: "Playlist \(index)")
        }

        // When & Then
        measure {
            let encoder = JSONEncoder()
            for playlist in playlists {
                _ = try? encoder.encode(playlist)
            }
        }
    }

    // MARK: - Edge Case Tests

    /// BDD: Given a playlist with Unicode characters, when I encode and decode it, then it should preserve Unicode
    func testPlaylistWithUnicodeCharacters() throws {
        // Given
        let playlist = Playlist(
            id: UUID(),
            name: "プレイリスト 🎵",
            trackCount: 10,
            totalDuration: 1800.0,
            isSmart: false
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        let decoder = JSONDecoder()
        let decodedPlaylist = try decoder.decode(Playlist.self, from: data)

        // Then
        XCTAssertEqual(decodedPlaylist.name, playlist.name, "Unicode name should be preserved")
    }

    /// BDD: Given a playlist with special characters, when I encode and decode it, then it should preserve them
    func testPlaylistWithSpecialCharacters() throws {
        // Given
        let playlist = Playlist(
            id: UUID(),
            name: "Playlist \"With\" 'Special' & Characters",
            trackCount: 10,
            totalDuration: 1800.0,
            isSmart: false
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        let decoder = JSONDecoder()
        let decodedPlaylist = try decoder.decode(Playlist.self, from: data)

        // Then
        XCTAssertEqual(decodedPlaylist.name, playlist.name, "Special characters should be preserved")
    }
}
