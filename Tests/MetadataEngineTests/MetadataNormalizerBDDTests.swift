//
//  MetadataNormalizerBDDTests.swift
//  MetadataEngineTests
//
//  BDD scenarios for metadata normalization
//  Following user-centric behavior-driven development
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for Metadata Normalization
/// Following user-centric scenarios: "As a user, I want to..."
@MainActor
final class MetadataNormalizerBDDTests: XCTestCase {
    
    var normalizer: MetadataNormalizer!
    
    override func setUp() async throws {
        try await super.setUp()
        normalizer = MetadataNormalizer()
    }
    
    override func tearDown() async throws {
        normalizer = nil
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Normalize Metadata for Consistency
    
    /// BDD: As a user, when I scan my music library, then metadata should be consistently formatted
    func testUserScansLibraryAndSeesConsistentMetadata() {
        // Given - Track with inconsistent metadata formatting
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
        
        // When - I normalize the track metadata
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - I should see consistently formatted metadata
        XCTAssertEqual(normalized.title, "Here Comes The Sun", "Title should be consistently formatted")
        XCTAssertEqual(normalized.artist, "The Beatles", "Artist should be consistently formatted")
        XCTAssertEqual(normalized.album, "Abbey Road", "Album should be consistently formatted")
        XCTAssertEqual(normalized.genre, "Rock & Roll", "Genre should be consistently formatted")
    }
    
    /// BDD: As a user, when I view track metadata, then extra spaces should be removed
    func testUserViewsTrackMetadataWithoutExtraSpaces() {
        // Given - Track with extra spaces in metadata
        let track = Track(
            id: UUID(),
            title: "Song   Title",
            artist: "Artist   Name",
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
        
        // When - I normalize the track
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - I should see metadata without extra spaces
        XCTAssertFalse(normalized.title.contains("  "), "Title should not contain multiple spaces")
        XCTAssertFalse(normalized.artist.contains("  "), "Artist should not contain multiple spaces")
        XCTAssertFalse(normalized.album.contains("  "), "Album should not contain multiple spaces")
    }
    
    // MARK: - User Scenario: Handle Missing Metadata
    
    /// BDD: As a user, when I scan files with missing metadata, then normalization should handle it gracefully
    func testUserScansFilesWithMissingMetadata() {
        // Given - Track with some empty metadata fields
        let track = Track(
            id: UUID(),
            title: "  Song Title  ",
            artist: "",
            album: "  Album Name  ",
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
        
        // When - I normalize the track
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - I should see normalized fields where present, empty strings where missing
        // Note: Track requires non-nil strings for title, artist, album, so empty strings remain as empty strings
        XCTAssertEqual(normalized.title, "Song Title", "Title should be normalized")
        XCTAssertEqual(normalized.artist, "", "Empty artist should remain empty string (Track requires non-nil String)")
        XCTAssertEqual(normalized.album, "Album Name", "Album should be normalized")
        XCTAssertNil(normalized.genre, "Nil genre should remain nil")
    }
    
    // MARK: - User Scenario: Preserve Special Characters
    
    /// BDD: As a user, when I have metadata with special characters, then they should be preserved
    func testUserHasMetadataWithSpecialCharacters() {
        // Given - Track with special characters
        let track = Track(
            id: UUID(),
            title: "  Song (Remix)  ",
            artist: "Artist & Band",
            album: "Album: Volume 1",
            duration: 180.0,
            filePath: "/path/to/file.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: "Rock & Roll"
        )
        
        // When - I normalize the track
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - I should see special characters preserved
        XCTAssertEqual(normalized.title, "Song (Remix)", "Special characters in title should be preserved")
        XCTAssertEqual(normalized.artist, "Artist & Band", "Ampersand in artist should be preserved")
        XCTAssertEqual(normalized.album, "Album: Volume 1", "Colon in album should be preserved")
    }
    
    /// BDD: As a user, when I have metadata with Unicode characters, then they should be preserved
    func testUserHasMetadataWithUnicodeCharacters() {
        // Given - Track with Unicode characters
        let track = Track(
            id: UUID(),
            title: "  Café Música  ",
            artist: "  José González  ",
            album: "Album   Name",
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
        
        // When - I normalize the track
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - I should see Unicode characters preserved
        XCTAssertEqual(normalized.title, "Café Música", "Unicode characters in title should be preserved")
        XCTAssertEqual(normalized.artist, "José González", "Unicode characters in artist should be preserved")
    }
    
    // MARK: - User Scenario: Batch Normalization
    
    /// BDD: As a user, when I normalize multiple tracks, then all should be consistently formatted
    func testUserNormalizesMultipleTracks() {
        // Given - Multiple tracks with inconsistent formatting
        let tracks = [
            Track(
                id: UUID(),
                title: "  Song 1  ",
                artist: "  Artist 1  ",
                album: "Album   1",
                duration: 180.0,
                filePath: "/path/to/file1.mp3",
                fileSize: 5000000,
                bitrate: 320,
                sampleRate: 44100,
                year: nil,
                trackNumber: nil,
                discNumber: nil,
                genre: nil
            ),
            Track(
                id: UUID(),
                title: "  Song 2  ",
                artist: "  Artist 2  ",
                album: "Album   2",
                duration: 200.0,
                filePath: "/path/to/file2.mp3",
                fileSize: 6000000,
                bitrate: 320,
                sampleRate: 44100,
                year: nil,
                trackNumber: nil,
                discNumber: nil,
                genre: nil
            )
        ]
        
        // When - I normalize all tracks
        let normalizedTracks = tracks.map { normalizer.normalizeTrack($0) }
        
        // Then - All tracks should be consistently formatted
        for normalized in normalizedTracks {
            XCTAssertFalse(normalized.title.hasPrefix(" "), "Title should not have leading space")
            XCTAssertFalse(normalized.title.hasSuffix(" "), "Title should not have trailing space")
            XCTAssertFalse(normalized.title.contains("  "), "Title should not have multiple spaces")
            XCTAssertFalse(normalized.artist.hasPrefix(" "), "Artist should not have leading space")
            XCTAssertFalse(normalized.artist.hasSuffix(" "), "Artist should not have trailing space")
        }
    }
    
    // MARK: - User Scenario: Normalize Individual Fields
    
    /// BDD: As a user, when I normalize just the artist name, then it should be formatted correctly
    func testUserNormalizesJustArtistName() {
        // Given - Artist name with extra whitespace
        let artist = "  The Beatles  "
        
        // When - I normalize the artist name
        let normalized = normalizer.normalizeArtist(artist)
        
        // Then - I should see correctly formatted artist name
        XCTAssertEqual(normalized, "The Beatles", "Artist name should be correctly formatted")
    }
    
    /// BDD: As a user, when I normalize just the album name, then it should be formatted correctly
    func testUserNormalizesJustAlbumName() {
        // Given - Album name with multiple spaces
        let album = "Abbey   Road"
        
        // When - I normalize the album name
        let normalized = normalizer.normalizeAlbum(album)
        
        // Then - I should see correctly formatted album name
        XCTAssertEqual(normalized, "Abbey Road", "Album name should be correctly formatted")
    }
    
    /// BDD: As a user, when I normalize just the track title, then it should be formatted correctly
    func testUserNormalizesJustTrackTitle() {
        // Given - Track title with whitespace
        let title = "  Here Comes The Sun  "
        
        // When - I normalize the track title
        let normalized = normalizer.normalizeTitle(title)
        
        // Then - I should see correctly formatted track title
        XCTAssertEqual(normalized, "Here Comes The Sun", "Track title should be correctly formatted")
    }
    
    /// BDD: As a user, when I normalize just the genre, then it should be formatted correctly
    func testUserNormalizesJustGenre() {
        // Given - Genre with extra spaces
        let genre = "Rock   &   Roll"
        
        // When - I normalize the genre
        let normalized = normalizer.normalizeGenre(genre)
        
        // Then - I should see correctly formatted genre
        XCTAssertEqual(normalized, "Rock & Roll", "Genre should be correctly formatted")
    }
}
