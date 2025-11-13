//
//  MetadataNormalizerTests.swift
//  MetadataEngineTests
//
//  TDD tests for MetadataNormalizer
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for MetadataNormalizer
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class MetadataNormalizerTests: XCTestCase {
    
    var normalizer: MetadataNormalizer!
    
    override func setUp() async throws {
        try await super.setUp()
        normalizer = MetadataNormalizer()
    }
    
    override func tearDown() async throws {
        normalizer = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that normalizer trims leading and trailing whitespace
    func testNormalizerTrimsWhitespace() {
        // Given - String with leading and trailing whitespace
        let input = "  The Beatles  "
        
        // When - Normalize the string
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should trim whitespace
        XCTAssertEqual(normalized, "The Beatles", "Should trim leading and trailing whitespace")
    }
    
    /// Test that normalizer collapses multiple spaces into single space
    func testNormalizerCollapsesMultipleSpaces() {
        // Given - String with multiple spaces
        let input = "The   Beatles   And   More"
        
        // When - Normalize the string
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should collapse multiple spaces
        XCTAssertEqual(normalized, "The Beatles And More", "Should collapse multiple spaces into single space")
    }
    
    /// Test that normalizer handles tabs and newlines
    func testNormalizerHandlesTabsAndNewlines() {
        // Given - String with tabs and newlines
        let input = "The\tBeatles\nAnd\rMore"
        
        // When - Normalize the string
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should normalize whitespace characters
        XCTAssertEqual(normalized, "The Beatles And More", "Should normalize tabs and newlines to spaces")
    }
    
    /// Test normalizing artist name
    func testNormalizeArtist() {
        // Given - Artist name with extra whitespace
        let artist = "  The Beatles  "
        
        // When - Normalize artist
        let normalized = normalizer.normalizeArtist(artist)
        
        // Then - Should be normalized
        XCTAssertEqual(normalized, "The Beatles", "Should normalize artist name")
    }
    
    /// Test normalizing album name
    func testNormalizeAlbum() {
        // Given - Album name with multiple spaces
        let album = "Abbey   Road"
        
        // When - Normalize album
        let normalized = normalizer.normalizeAlbum(album)
        
        // Then - Should be normalized
        XCTAssertEqual(normalized, "Abbey Road", "Should normalize album name")
    }
    
    /// Test normalizing track title
    func testNormalizeTitle() {
        // Given - Title with whitespace
        let title = "  Here Comes The Sun  "
        
        // When - Normalize title
        let normalized = normalizer.normalizeTitle(title)
        
        // Then - Should be normalized
        XCTAssertEqual(normalized, "Here Comes The Sun", "Should normalize track title")
    }
    
    /// Test normalizing genre
    func testNormalizeGenre() {
        // Given - Genre with extra spaces
        let genre = "Rock   &   Roll"
        
        // When - Normalize genre
        let normalized = normalizer.normalizeGenre(genre)
        
        // Then - Should be normalized
        XCTAssertEqual(normalized, "Rock & Roll", "Should normalize genre")
    }
    
    /// Test normalizing entire Track
    func testNormalizeTrack() {
        // Given - Track with unnormalized metadata
        let track = Track(
            id: UUID(),
            title: "  Here Comes The Sun  ",
            artist: "  The Beatles  ",
            album: "Abbey   Road",
            duration: 185.0,
            filePath: "/path/to/file.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: 1969,
            trackNumber: 7,
            discNumber: 1,
            genre: "Rock   &   Roll"
        )
        
        // When - Normalize track
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - All fields should be normalized
        XCTAssertEqual(normalized.title, "Here Comes The Sun", "Title should be normalized")
        XCTAssertEqual(normalized.artist, "The Beatles", "Artist should be normalized")
        XCTAssertEqual(normalized.album, "Abbey Road", "Album should be normalized")
        XCTAssertEqual(normalized.genre, "Rock & Roll", "Genre should be normalized")
        // Other fields should remain unchanged
        XCTAssertEqual(normalized.id, track.id, "ID should remain unchanged")
        XCTAssertEqual(normalized.duration, track.duration, "Duration should remain unchanged")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test normalizing empty string
    func testNormalizeEmptyString() {
        // Given - Empty string
        let input = ""
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should return empty string
        XCTAssertEqual(normalized, "", "Empty string should remain empty")
    }
    
    /// Test normalizing string with only whitespace
    func testNormalizeStringWithOnlyWhitespace() {
        // Given - String with only spaces
        let input = "     "
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should return empty string
        XCTAssertEqual(normalized, "", "String with only whitespace should become empty")
    }
    
    /// Test normalizing nil values
    func testNormalizeNilValues() {
        // Given - Nil values
        let nilArtist = normalizer.normalizeArtist(nil)
        let nilAlbum = normalizer.normalizeAlbum(nil)
        let nilTitle = normalizer.normalizeTitle(nil)
        let nilGenre = normalizer.normalizeGenre(nil)
        
        // Then - Should return nil
        XCTAssertNil(nilArtist, "Nil artist should return nil")
        XCTAssertNil(nilAlbum, "Nil album should return nil")
        XCTAssertNil(nilTitle, "Nil title should return nil")
        XCTAssertNil(nilGenre, "Nil genre should return nil")
    }
    
    /// Test normalizing already normalized string
    func testNormalizeAlreadyNormalizedString() {
        // Given - Already normalized string
        let input = "The Beatles"
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should remain unchanged
        XCTAssertEqual(normalized, "The Beatles", "Already normalized string should remain unchanged")
    }
    
    /// Test normalizing string with many spaces
    func testNormalizeStringWithManySpaces() {
        // Given - String with many consecutive spaces
        let input = "The        Beatles"
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should collapse to single space
        XCTAssertEqual(normalized, "The Beatles", "Should collapse many spaces to single space")
    }
    
    /// Test normalizing very long string
    func testNormalizeVeryLongString() {
        // Given - Very long string with whitespace
        let longString = "  " + String(repeating: "Word ", count: 1000) + "  "
        
        // When - Normalize
        let normalized = normalizer.normalizeString(longString)
        
        // Then - Should normalize without issues
        XCTAssertFalse(normalized.isEmpty, "Should handle very long strings")
        XCTAssertFalse(normalized.hasPrefix(" "), "Should trim leading whitespace")
        XCTAssertFalse(normalized.hasSuffix(" "), "Should trim trailing whitespace")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that normalizing twice yields same result
    func testNormalizeTwiceYieldsSameResult() {
        // Given - String with whitespace
        let input = "  The   Beatles  "
        
        // When - Normalize twice
        let normalized1 = normalizer.normalizeString(input)
        let normalized2 = normalizer.normalizeString(normalized1)
        
        // Then - Should yield same result
        XCTAssertEqual(normalized1, normalized2, "Normalizing twice should yield same result")
        XCTAssertEqual(normalized1, "The Beatles", "Result should be normalized")
    }
    
    /// Test that normalizing a track twice yields same result
    func testNormalizeTrackTwiceYieldsSameResult() {
        // Given - Track with unnormalized metadata
        let track = Track(
            id: UUID(),
            title: "  Song Title  ",
            artist: "  Artist Name  ",
            album: "Album   Name",
            duration: 180.0,
            filePath: "/path/to/file.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: "Genre   Name"
        )
        
        // When - Normalize twice
        let normalized1 = normalizer.normalizeTrack(track)
        let normalized2 = normalizer.normalizeTrack(normalized1)
        
        // Then - Should yield same result
        XCTAssertEqual(normalized1.title, normalized2.title, "Title should remain same after second normalization")
        XCTAssertEqual(normalized1.artist, normalized2.artist, "Artist should remain same after second normalization")
        XCTAssertEqual(normalized1.album, normalized2.album, "Album should remain same after second normalization")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that normalization matches manual string manipulation
    func testNormalizationMatchesManualManipulation() {
        // Given - String with whitespace
        let input = "  The   Beatles  "
        
        // When - Normalize using normalizer
        let normalized = normalizer.normalizeString(input)
        
        // And - Manually normalize
        let manualNormalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Then - Should match manual normalization
        XCTAssertEqual(normalized, manualNormalized, "Should match manual normalization")
    }
    
    // MARK: - Error Conditions
    
    /// Test that normalizer handles strings with only special characters
    func testNormalizeStringWithOnlySpecialCharacters() {
        // Given - String with only special characters
        let input = "!@#$%^&*()"
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should handle gracefully (no crash)
        XCTAssertEqual(normalized, input, "Special characters should remain unchanged")
    }
    
    /// Test that normalizer handles Unicode characters
    func testNormalizeStringWithUnicode() {
        // Given - String with Unicode characters
        let input = "  Café   Música  "
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should preserve Unicode and normalize whitespace
        XCTAssertEqual(normalized, "Café Música", "Should preserve Unicode characters")
    }
    
    /// Test that normalizer handles mixed whitespace types
    func testNormalizeStringWithMixedWhitespace() {
        // Given - String with mixed whitespace (spaces, tabs, newlines)
        let input = "  The\t\tBeatles\n\n  "
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should normalize all whitespace
        XCTAssertEqual(normalized, "The Beatles", "Should normalize mixed whitespace types")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that normalization completes quickly
    func testNormalizationPerformance() {
        // Given - Long string with whitespace
        let longString = "  " + String(repeating: "Word ", count: 1000) + "  "
        
        // When - Measure normalization time
        let startTime = Date()
        _ = normalizer.normalizeString(longString)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 100ms (SLA: < 100ms)
        XCTAssertLessThan(duration, 0.1, "Normalization should complete within 100ms")
    }
    
    /// Test that track normalization completes quickly
    func testTrackNormalizationPerformance() {
        // Given - Track with unnormalized metadata
        let track = Track(
            id: UUID(),
            title: "  " + String(repeating: "Word ", count: 100) + "  ",
            artist: "  " + String(repeating: "Word ", count: 100) + "  ",
            album: "  " + String(repeating: "Word ", count: 100) + "  ",
            duration: 180.0,
            filePath: "/path/to/file.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: "  " + String(repeating: "Word ", count: 100) + "  "
        )
        
        // When - Measure normalization time
        let startTime = Date()
        _ = normalizer.normalizeTrack(track)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 10ms (SLA: < 10ms per track)
        XCTAssertLessThan(duration, 0.01, "Track normalization should complete within 10ms")
    }
    
    // MARK: - Edge Cases
    
    /// Test normalizing string with zero-width spaces
    func testNormalizeStringWithZeroWidthSpaces() {
        // Given - String with zero-width spaces
        let input = "\u{200B}The\u{200B}Beatles\u{200B}"
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should handle gracefully
        // Zero-width spaces are not standard whitespace, so they may or may not be removed
        // The important thing is it doesn't crash
        XCTAssertFalse(normalized.isEmpty, "Should handle zero-width spaces")
    }
    
    /// Test normalizing string with only newlines
    func testNormalizeStringWithOnlyNewlines() {
        // Given - String with only newlines
        let input = "\n\n\n"
        
        // When - Normalize
        let normalized = normalizer.normalizeString(input)
        
        // Then - Should return empty string
        XCTAssertEqual(normalized, "", "String with only newlines should become empty")
    }
    
    /// Test normalizing track with all nil optional fields
    func testNormalizeTrackWithAllNilFields() {
        // Given - Track with nil optional fields
        let track = Track(
            id: UUID(),
            title: "  Title  ",
            artist: "  Artist  ",
            album: "  Album  ",
            duration: 180.0,
            filePath: "/path/to/file.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: nil
        )
        
        // When - Normalize
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - Should normalize non-nil fields and preserve nil fields
        XCTAssertEqual(normalized.title, "Title", "Title should be normalized")
        XCTAssertEqual(normalized.artist, "Artist", "Artist should be normalized")
        XCTAssertEqual(normalized.album, "Album", "Album should be normalized")
        XCTAssertNil(normalized.genre, "Nil genre should remain nil")
    }
}
