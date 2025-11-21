//
//  FolderStructureBuilderTests.swift
//  DataLayerTests
//
//  TDD tests for FolderStructureBuilder (Right-BICEP)
//

@testable import DataLayer
@testable import Shared
import XCTest

final class FolderStructureBuilderTests: XCTestCase {
    
    private var builder: FolderStructureBuilder!
    
    override func setUp() {
        builder = FolderStructureBuilder()
    }
    
    override func tearDown() {
        builder = nil
    }
    
    // MARK: - [Right] Results Right
    
    func testBuildPathForFlatStructure() {
        // Given: A track with metadata
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path with flat structure
        let path = builder.buildPath(for: track, structure: .flat)
        
        // Then: Should return just the track title
        XCTAssertEqual(path, "Test Song", "Flat structure should return only track title")
    }
    
    func testBuildPathForArtistAlbumStructure() {
        // Given: A track with metadata
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path with artist/album structure
        let path = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Should return Artist/Album/Track format
        XCTAssertEqual(path, "Test Artist/Test Album/Test Song", "Artist/Album structure should format correctly")
    }
    
    func testBuildPathForAlbumArtistStructure() {
        // Given: A track with metadata
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path with album/artist structure
        let path = builder.buildPath(for: track, structure: .albumArtist)
        
        // Then: Should return Album/Artist/Track format
        XCTAssertEqual(path, "Test Album/Test Artist/Test Song", "Album/Artist structure should format correctly")
    }
    
    func testBuildPathForGenreArtistAlbumStructure() {
        // Given: A track with metadata including genre
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100,
            genre: "Rock"
        )
        
        // When: Building path with genre/artist/album structure
        let path = builder.buildPath(for: track, structure: .genreArtistAlbum)
        
        // Then: Should return Genre/Artist/Album/Track format
        XCTAssertEqual(path, "Rock/Test Artist/Test Album/Test Song", "Genre/Artist/Album structure should format correctly")
    }
    
    // MARK: - [B] Boundary Conditions
    
    func testBuildPathWithMissingMetadata() {
        // Given: A track with empty metadata
        let track = Track(
            title: "",
            artist: "",
            album: "",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path
        let path = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Should use "Unknown" placeholders
        XCTAssertTrue(path.contains("Unknown Artist"), "Should use Unknown Artist placeholder")
        XCTAssertTrue(path.contains("Unknown Album"), "Should use Unknown Album placeholder")
        XCTAssertTrue(path.contains("Unknown Track"), "Should use Unknown Track placeholder")
    }
    
    func testBuildPathWithEmptyStrings() {
        // Given: A track with empty string metadata
        let track = Track(
            title: "",
            artist: "",
            album: "",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path
        let path = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Should use "Unknown" placeholders
        XCTAssertTrue(path.contains("Unknown"), "Should use Unknown placeholders for empty strings")
    }
    
    func testBuildPathWithSpecialCharacters() {
        // Given: A track with special characters in metadata
        let track = Track(
            title: "Song: Test?",
            artist: "Artist/Name",
            album: "Album|Title",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path
        let path = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Special characters should be sanitized (replaced with underscores)
        // Note: "/" is used as path separator, so we check individual components
        let components = path.components(separatedBy: "/")
        for component in components {
            XCTAssertFalse(component.contains(":"), "Component should not contain colons: \(component)")
            XCTAssertFalse(component.contains("?"), "Component should not contain question marks: \(component)")
            XCTAssertFalse(component.contains("|"), "Component should not contain pipes: \(component)")
        }
        // Verify the path structure is correct
        XCTAssertEqual(components.count, 3, "Should have 3 components: Artist/Album/Title")
        XCTAssertTrue(components[0].contains("Artist"), "First component should contain artist")
        XCTAssertTrue(components[1].contains("Album"), "Second component should contain album")
        XCTAssertTrue(components[2].contains("Song"), "Third component should contain title")
    }
    
    func testBuildPathWithUnicodeCharacters() {
        // Given: A track with Unicode characters
        let track = Track(
            title: "Song 歌曲",
            artist: "Artist 艺术家",
            album: "Album 专辑",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path
        let path = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Unicode characters should be preserved
        XCTAssertTrue(path.contains("歌曲"), "Should preserve Unicode in title")
        XCTAssertTrue(path.contains("艺术家"), "Should preserve Unicode in artist")
        XCTAssertTrue(path.contains("专辑"), "Should preserve Unicode in album")
    }
    
    // MARK: - [I] Inverse Relationships
    
    func testDifferentStructuresProduceDifferentPaths() {
        // Given: A track
        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building paths with different structures
        let flat = builder.buildPath(for: track, structure: .flat)
        let artistAlbum = builder.buildPath(for: track, structure: .artistAlbum)
        let albumArtist = builder.buildPath(for: track, structure: .albumArtist)
        let genreArtistAlbum = builder.buildPath(for: track, structure: .genreArtistAlbum)
        
        // Then: All paths should be different
        XCTAssertNotEqual(flat, artistAlbum, "Flat should differ from Artist/Album")
        XCTAssertNotEqual(artistAlbum, albumArtist, "Artist/Album should differ from Album/Artist")
        XCTAssertNotEqual(albumArtist, genreArtistAlbum, "Album/Artist should differ from Genre/Artist/Album")
    }
    
    // MARK: - [C] Cross-Checking
    
    func testSameTrackSameStructureProducesSamePath() {
        // Given: A track
        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path twice with same structure
        let path1 = builder.buildPath(for: track, structure: .artistAlbum)
        let path2 = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Paths should be identical
        XCTAssertEqual(path1, path2, "Same track and structure should produce same path")
    }
    
    // MARK: - [E] Error Conditions
    
    func testBuildPathWithVeryLongNames() {
        // Given: A track with very long metadata
        let longString = String(repeating: "A", count: 1000)
        let track = Track(
            title: longString,
            artist: longString,
            album: longString,
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Building path
        let path = builder.buildPath(for: track, structure: .artistAlbum)
        
        // Then: Should handle long names (no crash)
        XCTAssertFalse(path.isEmpty, "Should handle long names without crashing")
    }
    
    // MARK: - [P] Performance
    
    func testBuildPathPerformance() {
        // Given: A track
        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 180,
            filePath: "/test/track.mp3",
            fileSize: 5 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        
        // When: Measuring performance
        measure {
            _ = builder.buildPath(for: track, structure: .artistAlbum)
        }
    }
}
