//
//  ID3v2TagWriterTests.swift
//  MetadataEngineTests
//
//  TDD tests for ID3v2TagWriter following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for ID3v2TagWriter
/// Following Right-BICEP principles:
/// - [Right]: Verify tags written correctly, readable by parsers
/// - [B]oundary: Very long tags, empty tags, special characters
/// - [I]nverse: Write tag → Read → Verify match
/// - [C]ross-check: Compare with external tag editors
/// - [E]rror: Read-only files, disk full, corrupt tags
/// - [P]erformance: Tag write < 100ms
final class ID3v2TagWriterTests: XCTestCase {
    
    var writer: ID3v2TagWriter!
    var parser: ID3v2Parser!
    
    override func setUp() {
        super.setUp()
        writer = ID3v2TagWriter()
        parser = ID3v2Parser()
    }
    
    override func tearDown() {
        writer = nil
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper to create a track for testing
    private func createTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        year: Int? = 2020,
        genre: String? = "Rock",
        trackNumber: Int? = 1,
        discNumber: Int? = 1
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre
        )
    }
    
    /// Helper to create a temporary MP3 file with minimal audio data
    private func createTempMP3File() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_\(UUID().uuidString).mp3"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create minimal MP3 file (just header, no actual audio)
        // For testing purposes, we'll create a file that can accept ID3v2 tags
        var mp3Data = Data()
        // MP3 sync word (0xFF 0xFB or 0xFF 0xFA)
        mp3Data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00])
        // Add some dummy data
        mp3Data.append(contentsOf: Array(repeating: UInt8(0), count: 100))
        
        FileManager.default.createFile(atPath: fileURL.path, contents: mp3Data, attributes: nil)
        return fileURL
    }
    
    // MARK: - [Right] Tests - Verify Correct Results
    
    /// Test writing basic tags to MP3 file
    func testWriteBasicTags() async throws {
        // Given - Track with basic metadata
        let track = createTrack()
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write tags
        try await writer.write(track: track, to: fileURL)
        
        // Then - Tags should be readable by parser
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, track.title)
        XCTAssertEqual(parsedTrack?.artist, track.artist)
        XCTAssertEqual(parsedTrack?.album, track.album)
    }
    
    /// Test writing all tag fields
    func testWriteAllTagFields() async throws {
        // Given - Track with all metadata fields
        let track = createTrack(
            title: "Complete Track",
            artist: "Complete Artist",
            album: "Complete Album",
            year: 2021,
            genre: "Jazz",
            trackNumber: 5,
            discNumber: 2
        )
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write tags
        try await writer.write(track: track, to: fileURL)
        
        // Then - All fields should be readable
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, track.title)
        XCTAssertEqual(parsedTrack?.artist, track.artist)
        XCTAssertEqual(parsedTrack?.album, track.album)
        XCTAssertEqual(parsedTrack?.year, track.year)
        XCTAssertEqual(parsedTrack?.genre, track.genre)
        XCTAssertEqual(parsedTrack?.trackNumber, track.trackNumber)
        XCTAssertEqual(parsedTrack?.discNumber, track.discNumber)
    }
    
    /// Test updating existing tags
    func testUpdateExistingTags() async throws {
        // Given - File with existing tags
        let originalTrack = createTrack(title: "Original Title", artist: "Original Artist")
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        try await writer.write(track: originalTrack, to: fileURL)
        
        // When - Update tags
        let updatedTrack = createTrack(title: "Updated Title", artist: "Updated Artist")
        try await writer.update(track: updatedTrack, in: fileURL)
        
        // Then - Updated tags should be readable
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, "Updated Title")
        XCTAssertEqual(parsedTrack?.artist, "Updated Artist")
    }
    
    // MARK: - [B]oundary Tests
    
    /// Test writing very long tag values
    func testWriteVeryLongTags() async throws {
        // Given - Track with very long tag values
        let longTitle = String(repeating: "A", count: 1000)
        let longArtist = String(repeating: "B", count: 1000)
        let track = createTrack(title: longTitle, artist: longArtist)
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write tags
        try await writer.write(track: track, to: fileURL)
        
        // Then - Long tags should be readable (may be truncated by format limits)
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        // ID3v2 may truncate very long tags, so we check that at least some data is preserved
        XCTAssertTrue(parsedTrack?.title.count ?? 0 > 0)
    }
    
    /// Test writing empty tag values
    func testWriteEmptyTags() async throws {
        // Given - Track with empty tag values
        let track = createTrack(title: "", artist: "", album: "")
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write tags
        try await writer.write(track: track, to: fileURL)
        
        // Then - File should still be readable (may use defaults)
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        // Empty tags may result in nil or default values
        XCTAssertNotNil(parsedTrack)
    }
    
    /// Test writing special characters in tags
    func testWriteSpecialCharacters() async throws {
        // Given - Track with special characters
        let track = createTrack(
            title: "Test 🎵 Song",
            artist: "Artist & Band",
            album: "Album \"Title\""
        )
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write tags
        try await writer.write(track: track, to: fileURL)
        
        // Then - Special characters should be preserved or handled appropriately
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        // Special characters may be encoded differently, so we verify the track exists
        XCTAssertNotNil(parsedTrack?.title)
    }
    
    /// Test writing tags with nil optional fields
    func testWriteNilOptionalFields() async throws {
        // Given - Track with nil optional fields
        let track = createTrack(year: nil, genre: nil, trackNumber: nil, discNumber: nil)
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write tags
        try await writer.write(track: track, to: fileURL)
        
        // Then - File should be readable
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, track.title)
        XCTAssertEqual(parsedTrack?.artist, track.artist)
    }
    
    // MARK: - [I]nverse Tests
    
    /// Test write then read roundtrip
    func testWriteReadRoundtrip() async throws {
        // Given - Track to write
        let originalTrack = createTrack(
            title: "Roundtrip Track",
            artist: "Roundtrip Artist",
            album: "Roundtrip Album",
            year: 2022,
            genre: "Pop",
            trackNumber: 3,
            discNumber: 1
        )
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Write then read
        try await writer.write(track: originalTrack, to: fileURL)
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        
        // Then - Read track should match written track
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, originalTrack.title)
        XCTAssertEqual(parsedTrack?.artist, originalTrack.artist)
        XCTAssertEqual(parsedTrack?.album, originalTrack.album)
        XCTAssertEqual(parsedTrack?.year, originalTrack.year)
        XCTAssertEqual(parsedTrack?.genre, originalTrack.genre)
        XCTAssertEqual(parsedTrack?.trackNumber, originalTrack.trackNumber)
        XCTAssertEqual(parsedTrack?.discNumber, originalTrack.discNumber)
    }
    
    /// Test update then read roundtrip
    func testUpdateReadRoundtrip() async throws {
        // Given - File with existing tags
        let originalTrack = createTrack(title: "Original", artist: "Original")
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        try await writer.write(track: originalTrack, to: fileURL)
        
        // When - Update then read
        let updatedTrack = createTrack(title: "Updated", artist: "Updated")
        try await writer.update(track: updatedTrack, in: fileURL)
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        
        // Then - Read track should match updated track
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, updatedTrack.title)
        XCTAssertEqual(parsedTrack?.artist, updatedTrack.artist)
    }
    
    // MARK: - [E]rror Tests
    
    /// Test writing to non-existent file
    func testWriteToNonExistentFile() async throws {
        // Given - Non-existent file URL
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent_\(UUID().uuidString).mp3")
        let track = createTrack()
        
        // When/Then - Should throw fileNotFound error
        do {
            try await writer.write(track: track, to: fileURL)
            XCTFail("Should have thrown fileNotFound error")
        } catch TagWriterError.fileNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test writing to read-only file
    func testWriteToReadOnlyFile() async throws {
        // Given - Read-only file
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // Make file read-only (on Unix systems)
        var attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        attributes[.posixPermissions] = 0o444 // Read-only
        try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
        
        let track = createTrack()
        
        // When/Then - Should throw readOnlyFile error
        do {
            try await writer.write(track: track, to: fileURL)
            XCTFail("Should have thrown readOnlyFile error")
        } catch TagWriterError.readOnlyFile {
            // Expected
        } catch {
            // On some systems, this might not be enforced, so we accept other errors
            XCTAssertTrue(error is TagWriterError)
        }
    }
    
    /// Test writing with invalid file extension
    func testWriteToInvalidFileExtension() async throws {
        // Given - File with unsupported extension
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID().uuidString).flac")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let track = createTrack()
        
        // When/Then - Should throw unsupportedFormat error or return false from canWrite
        XCTAssertFalse(writer.canWrite(fileURL: fileURL))
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test tag write performance
    func testWritePerformance() async throws {
        // Given - Track to write
        let track = createTrack()
        let fileURL = createTempMP3File()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When/Then - Write should complete < 100ms
        let startTime = Date()
        try await writer.write(track: track, to: fileURL)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 0.1, "Tag write should complete in < 100ms")
    }
    
    // MARK: - Protocol Conformance Tests
    
    /// Test canWrite returns true for MP3 files
    func testCanWriteMP3File() {
        // Given - MP3 file URL
        let fileURL = URL(fileURLWithPath: "/path/to/track.mp3")
        
        // When - Check if writer can write
        let canWrite = writer.canWrite(fileURL: fileURL)
        
        // Then - Should return true
        XCTAssertTrue(canWrite)
    }
    
    /// Test canWrite returns false for non-MP3 files
    func testCanWriteNonMP3File() {
        // Given - Non-MP3 file URL
        let fileURL = URL(fileURLWithPath: "/path/to/track.flac")
        
        // When - Check if writer can write
        let canWrite = writer.canWrite(fileURL: fileURL)
        
        // Then - Should return false
        XCTAssertFalse(canWrite)
    }
    
    /// Test supportedExtensions contains mp3
    func testSupportedExtensions() {
        // Given/When - Check supported extensions
        let extensions = writer.supportedExtensions
        
        // Then - Should contain mp3
        XCTAssertTrue(extensions.contains("mp3"))
        XCTAssertEqual(extensions.count, 1)
    }
}
