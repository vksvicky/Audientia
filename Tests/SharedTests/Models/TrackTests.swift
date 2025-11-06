// TrackTests.swift
// Audientia - TDD/BDD Tests for Track Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import Shared
import XCTest

/// BDD-style test suite for Track model
/// Following Right-BICEP principles:
/// - [Right]: Verify results are correct
/// - [B]oundary: Test edge cases and boundaries
/// - [I]nverse: Test reversible operations
/// - [C]ross-check: Verify with alternative methods
/// - [E]rror: Test error conditions
/// - [P]erformance: Verify performance characteristics
/// - Edge cases: Unicode, special characters, etc.
final class TrackTests: XCTestCase {

    // MARK: - [Right] Tests: Are the Results Right?

    /// BDD: Given a valid track, when I create it, then all properties should be set correctly
    func testTrackCreationWithAllProperties() {
        // Given
        let id = UUID()
        let title = "Bohemian Rhapsody"
        let artist = "Queen"
        let album = "A Night at the Opera"
        let duration: TimeInterval = 355.0
        let filePath = "/Music/Queen/A Night at the Opera/01 - Bohemian Rhapsody.mp3"
        let fileSize: Int64 = 8_500_000
        let bitrate = 320
        let sampleRate = 44100
        let year = 1975
        let trackNumber = 1
        let discNumber = 1
        let genre = "Rock"
        let rating = 5

        // When
        let track = Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre,
            rating: rating
        )

        // Then
        XCTAssertEqual(track.id, id, "Track ID should match")
        XCTAssertEqual(track.title, title, "Track title should match")
        XCTAssertEqual(track.artist, artist, "Track artist should match")
        XCTAssertEqual(track.album, album, "Track album should match")
        XCTAssertEqual(track.duration, duration, accuracy: 0.01, "Track duration should match")
        XCTAssertEqual(track.filePath, filePath, "Track file path should match")
        XCTAssertEqual(track.fileSize, fileSize, "Track file size should match")
        XCTAssertEqual(track.bitrate, bitrate, "Track bitrate should match")
        XCTAssertEqual(track.sampleRate, sampleRate, "Track sample rate should match")
        XCTAssertEqual(track.year, year, "Track year should match")
        XCTAssertEqual(track.trackNumber, trackNumber, "Track number should match")
        XCTAssertEqual(track.discNumber, discNumber, "Disc number should match")
        XCTAssertEqual(track.genre, genre, "Track genre should match")
        XCTAssertEqual(track.rating, rating, "Track rating should match")
    }

    /// BDD: Given a minimal track, when I create it, then optional properties should be nil
    func testTrackCreationWithMinimalProperties() {
        // Given & When
        let track = MockFactory.makeMinimalTrack()

        // Then
        XCTAssertNotNil(track.id, "Track ID should be generated")
        XCTAssertFalse(track.title.isEmpty, "Track title should not be empty")
        XCTAssertNil(track.year, "Year should be nil for minimal track")
        XCTAssertNil(track.trackNumber, "Track number should be nil for minimal track")
        XCTAssertNil(track.discNumber, "Disc number should be nil for minimal track")
        XCTAssertNil(track.genre, "Genre should be nil for minimal track")
        XCTAssertNil(track.rating, "Rating should be nil for minimal track")
    }

    // MARK: - [B]oundary Condition Tests

    /// BDD: Given a track with zero duration, when I create it, then it should be valid
    func testTrackWithZeroDuration() {
        // Given & When
        let track = Track(
            id: UUID(),
            title: "Silent Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 0.0,
            filePath: "/path/to/silent.mp3",
            fileSize: 0,
            bitrate: 0,
            sampleRate: 0
        )

        // Then
        XCTAssertEqual(track.duration, 0.0, "Zero duration should be valid")
        XCTAssertEqual(track.fileSize, 0, "Zero file size should be valid")
    }

    /// BDD: Given a track with very long duration, when I create it, then it should be valid
    func testTrackWithVeryLongDuration() {
        // Given & When
        let veryLongDuration: TimeInterval = 86_400.0 // 24 hours
        let track = Track(
            id: UUID(),
            title: "Very Long Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: veryLongDuration,
            filePath: "/path/to/long.mp3",
            fileSize: 1_000_000_000,
            bitrate: 320,
            sampleRate: 44100
        )

        // Then
        XCTAssertEqual(track.duration, veryLongDuration, accuracy: 0.01, "Very long duration should be valid")
    }

    /// BDD: Given a track with maximum rating, when I create it, then rating should be 5
    func testTrackWithMaximumRating() {
        // Given & When
        let track = MockFactory.makeTrack(rating: 5)

        // Then
        XCTAssertEqual(track.rating, 5, "Maximum rating should be 5")
    }

    /// BDD: Given a track with minimum rating, when I create it, then rating should be 1
    func testTrackWithMinimumRating() {
        // Given & When
        let track = MockFactory.makeTrack(rating: 1)

        // Then
        XCTAssertEqual(track.rating, 1, "Minimum rating should be 1")
    }

    /// BDD: Given a track with empty strings, when I create it, then it should be valid
    func testTrackWithEmptyStrings() {
        // Given & When
        let track = Track(
            id: UUID(),
            title: "",
            artist: "",
            album: "",
            duration: 0.0,
            filePath: "",
            fileSize: 0,
            bitrate: 0,
            sampleRate: 0
        )

        // Then
        XCTAssertTrue(track.title.isEmpty, "Empty title should be valid")
        XCTAssertTrue(track.artist.isEmpty, "Empty artist should be valid")
        XCTAssertTrue(track.album.isEmpty, "Empty album should be valid")
    }

    // MARK: - [I]nverse Relationship Tests

    /// BDD: Given a track, when I encode and decode it, then the result should match the original
    func testTrackEncodingAndDecodingRoundtrip() throws {
        // Given
        let originalTrack = MockFactory.makeTrack()

        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(originalTrack)

        let decoder = JSONDecoder()
        let decodedTrack = try decoder.decode(Track.self, from: data)

        // Then
        XCTAssertEqual(decodedTrack.id, originalTrack.id, "ID should match after roundtrip")
        XCTAssertEqual(decodedTrack.title, originalTrack.title, "Title should match after roundtrip")
        XCTAssertEqual(decodedTrack.artist, originalTrack.artist, "Artist should match after roundtrip")
        XCTAssertEqual(decodedTrack.album, originalTrack.album, "Album should match after roundtrip")
        XCTAssertEqual(decodedTrack.duration, originalTrack.duration, accuracy: 0.01, "Duration should match after roundtrip")
        XCTAssertEqual(decodedTrack.filePath, originalTrack.filePath, "File path should match after roundtrip")
        XCTAssertEqual(decodedTrack.fileSize, originalTrack.fileSize, "File size should match after roundtrip")
        XCTAssertEqual(decodedTrack.bitrate, originalTrack.bitrate, "Bitrate should match after roundtrip")
        XCTAssertEqual(decodedTrack.sampleRate, originalTrack.sampleRate, "Sample rate should match after roundtrip")
        XCTAssertEqual(decodedTrack.year, originalTrack.year, "Year should match after roundtrip")
        XCTAssertEqual(decodedTrack.trackNumber, originalTrack.trackNumber, "Track number should match after roundtrip")
        XCTAssertEqual(decodedTrack.discNumber, originalTrack.discNumber, "Disc number should match after roundtrip")
        XCTAssertEqual(decodedTrack.genre, originalTrack.genre, "Genre should match after roundtrip")
        XCTAssertEqual(decodedTrack.rating, originalTrack.rating, "Rating should match after roundtrip")
    }

    /// BDD: Given two tracks with same properties, when I compare them, then they should be equal
    func testTrackEquality() {
        // Given
        let id = UUID()
        let track1 = Track(
            id: id,
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
        let track2 = Track(
            id: id,
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )

        // When & Then
        XCTAssertEqual(track1, track2, "Tracks with same properties should be equal")
        XCTAssertEqual(track1.hashValue, track2.hashValue, "Tracks with same properties should have same hash")
    }

    /// BDD: Given two tracks with different IDs, when I compare them, then they should not be equal
    func testTrackInequality() {
        // Given
        let track1 = MockFactory.makeTrack(id: UUID())
        let track2 = MockFactory.makeTrack(id: UUID())

        // When & Then
        XCTAssertNotEqual(track1, track2, "Tracks with different IDs should not be equal")
    }

    // MARK: - [C]ross-Check Tests

    /// BDD: Given a track JSON, when I decode it, then it should match the expected structure
    func testTrackDecodingFromJSON() throws {
        // Given
        let json = TestFixtures.sampleTrackJSON

        // When
        let track = try TestFixtures.decodeTrack(from: json)

        // Then
        XCTAssertEqual(track.title, "Bohemian Rhapsody", "Decoded title should match")
        XCTAssertEqual(track.artist, "Queen", "Decoded artist should match")
        XCTAssertEqual(track.album, "A Night at the Opera", "Decoded album should match")
        XCTAssertEqual(track.duration, 355.0, accuracy: 0.01, "Decoded duration should match")
        XCTAssertEqual(track.year, 1975, "Decoded year should match")
        XCTAssertEqual(track.rating, 5, "Decoded rating should match")
    }

    /// BDD: Given a track, when I encode it to JSON, then it should be valid JSON
    func testTrackEncodingToJSON() throws {
        // Given
        let track = MockFactory.makeTrack()

        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(track)
        let jsonString = String(data: data, encoding: .utf8)

        // Then
        XCTAssertNotNil(jsonString, "Encoded JSON should not be nil")
        XCTAssertTrue(jsonString?.contains("\"title\"") ?? false, "JSON should contain title field")
        XCTAssertTrue(jsonString?.contains("\"artist\"") ?? false, "JSON should contain artist field")

        // Cross-check: Decode it back
        let decoder = JSONDecoder()
        let decodedTrack = try decoder.decode(Track.self, from: data)
        XCTAssertEqual(decodedTrack.id, track.id, "Roundtrip should preserve ID")
    }

    // MARK: - [E]rror Condition Tests

    /// BDD: Given invalid JSON, when I decode it, then it should throw an error
    func testTrackDecodingWithInvalidJSON() {
        // Given
        let invalidJSON = "{ invalid json }"

        // When & Then
        XCTAssertThrowsError(try TestFixtures.decodeTrack(from: invalidJSON), "Invalid JSON should throw error")
    }

    /// BDD: Given JSON with missing required fields, when I decode it, then it should throw an error
    func testTrackDecodingWithMissingRequiredFields() {
        // Given
        let incompleteJSON = """
        {
            "title": "Test Track"
        }
        """

        // When & Then
        XCTAssertThrowsError(try TestFixtures.decodeTrack(from: incompleteJSON), "Missing required fields should throw error")
    }

    /// BDD: Given JSON with wrong types, when I decode it, then it should throw an error
    func testTrackDecodingWithWrongTypes() {
        // Given
        let wrongTypeJSON = """
        {
            "id": "not-a-uuid",
            "title": 123,
            "duration": "not-a-number"
        }
        """

        // When & Then
        XCTAssertThrowsError(try TestFixtures.decodeTrack(from: wrongTypeJSON), "Wrong types should throw error")
    }

    // MARK: - [P]erformance Tests

    /// BDD: Given many tracks, when I encode them, then it should complete quickly
    func testTrackEncodingPerformance() {
        // Given
        let tracks = MockFactory.makeTracks(count: 1000)

        // When & Then
        measure {
            let encoder = JSONEncoder()
            for track in tracks {
                _ = try? encoder.encode(track)
            }
        }
    }

    /// BDD: Given many tracks, when I decode them, then it should complete quickly
    func testTrackDecodingPerformance() throws {
        // Given
        let track = MockFactory.makeTrack()
        let encoder = JSONEncoder()
        let data = try encoder.encode(track)
        _ = String(data: data, encoding: .utf8) ?? ""
        let decoder = JSONDecoder()

        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = try? decoder.decode(Track.self, from: data)
            }
        }
    }

    // MARK: - Edge Case Tests

    /// BDD: Given a track with Unicode characters, when I encode and decode it, then it should preserve Unicode
    func testTrackWithUnicodeCharacters() throws {
        // Given
        let track = MockFactory.makeUnicodeTrack()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(track)
        let decoder = JSONDecoder()
        let decodedTrack = try decoder.decode(Track.self, from: data)

        // Then
        XCTAssertEqual(decodedTrack.title, track.title, "Unicode title should be preserved")
        XCTAssertEqual(decodedTrack.artist, track.artist, "Unicode artist should be preserved")
        XCTAssertEqual(decodedTrack.album, track.album, "Unicode album should be preserved")
    }

    /// BDD: Given a track with very long file path, when I create it, then it should be valid
    func testTrackWithVeryLongFilePath() {
        // Given
        let veryLongPath = "/" + String(repeating: "very/long/path/", count: 100) + "track.mp3"

        // When
        let track = Track(
            id: UUID(),
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: veryLongPath,
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )

        // Then
        XCTAssertEqual(track.filePath, veryLongPath, "Very long file path should be valid")
        XCTAssertGreaterThan(track.filePath.count, 1000, "File path should be very long")
    }

    /// BDD: Given a track with special characters in title, when I encode and decode it, then it should preserve them
    func testTrackWithSpecialCharacters() throws {
        // Given
        let track = Track(
            id: UUID(),
            title: "Track \"With\" 'Special' & Characters < > &",
            artist: "Artist/Name",
            album: "Album: Subtitle",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(track)
        let decoder = JSONDecoder()
        let decodedTrack = try decoder.decode(Track.self, from: data)

        // Then
        XCTAssertEqual(decodedTrack.title, track.title, "Special characters should be preserved")
        XCTAssertEqual(decodedTrack.artist, track.artist, "Special characters in artist should be preserved")
    }

    /// BDD: Given a track with negative values, when I create it, then it should handle them appropriately
    func testTrackWithNegativeValues() {
        // Given & When
        let track = Track(
            id: UUID(),
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: -100.0, // Negative duration
            filePath: "/path/to/track.mp3",
            fileSize: -1000, // Negative file size
            bitrate: -320, // Negative bitrate
            sampleRate: -44100 // Negative sample rate
        )

        // Then - The model should accept these values (validation can be done at a higher level)
        XCTAssertEqual(track.duration, -100.0, accuracy: 0.01, "Negative duration should be stored")
        XCTAssertEqual(track.fileSize, -1000, "Negative file size should be stored")
        XCTAssertEqual(track.bitrate, -320, "Negative bitrate should be stored")
        XCTAssertEqual(track.sampleRate, -44100, "Negative sample rate should be stored")
    }
}
