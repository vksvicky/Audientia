//
//  VorbisCommentsParserTests.swift
//  MetadataEngineTests
//
//  TDD tests for Vorbis Comments tag parser
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for VorbisCommentsParser
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class VorbisCommentsParserTests: XCTestCase {
    
    var parser: VorbisCommentsParser!
    
    override func setUp() async throws {
        try await super.setUp()
        parser = VorbisCommentsParser()
    }
    
    override func tearDown() async throws {
        parser = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that Vorbis Comments parser supports OGG and FLAC files
    func testVorbisCommentsParserSupportsOGGAndFLACFiles() {
        // Given - OGG and FLAC file extensions
        let oggURL = URL(fileURLWithPath: "/test/song.ogg")
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        
        // When - Check if parser can handle these files
        let canParseOGG = parser.canParse(fileURL: oggURL)
        let canParseFLAC = parser.canParse(fileURL: flacURL)
        
        // Then - Should support both formats
        XCTAssertTrue(canParseOGG, "Vorbis Comments parser should support OGG files")
        XCTAssertTrue(canParseFLAC, "Vorbis Comments parser should support FLAC files")
        XCTAssertTrue(parser.supportedExtensions.contains("ogg"), "Supported extensions should include ogg")
        XCTAssertTrue(parser.supportedExtensions.contains("flac"), "Supported extensions should include flac")
    }
    
    /// Test that Vorbis Comments parser does not support non-Vorbis files
    func testVorbisCommentsParserDoesNotSupportNonVorbisFiles() {
        // Given - Non-Vorbis file extensions
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When/Then - Should not support non-Vorbis files
        XCTAssertFalse(parser.canParse(fileURL: mp3URL), "Vorbis Comments parser should not support MP3 files")
        XCTAssertFalse(parser.canParse(fileURL: m4aURL), "Vorbis Comments parser should not support M4A files")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test parsing with non-existent file
    func testParseNonExistentFile() async {
        // Given - Non-existent file URL
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/file.ogg")
        
        // When/Then - Should throw file not found error
        do {
            _ = try await parser.parse(fileURL: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            XCTAssertTrue(error is TagParserError, "Should throw TagParserError")
            if case let .fileNotFound(url) = error as? TagParserError {
                XCTAssertEqual(url, nonExistentURL, "Error should reference the correct URL")
            } else {
                XCTFail("Should throw fileNotFound error")
            }
        }
    }
    
    /// Test parsing with empty file
    func testParseEmptyFile() async throws {
        // Given - Empty file
        let emptyFile = createTempFile(extension: "ogg", content: Data())
        
        // When/Then - Should handle empty file gracefully
        do {
            _ = try await parser.parse(fileURL: emptyFile)
            // Parser may return nil or throw error - both are acceptable
        } catch {
            // Error is acceptable for empty files
            XCTAssertTrue(error is TagParserError, "Should throw TagParserError if error occurs")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: emptyFile)
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that parsing same file twice produces consistent results
    func testParseSameFileTwiceProducesConsistentResults() async throws {
        // Given - A file with Vorbis Comments
        let testFile = createTestOGGFileWithComments(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album"
        )
        
        // When - Parse twice
        let result1 = try await parser.parse(fileURL: testFile)
        let result2 = try await parser.parse(fileURL: testFile)
        
        // Then - Results should be consistent
        XCTAssertEqual(result1?.title, result2?.title, "Title should be consistent")
        XCTAssertEqual(result1?.artist, result2?.artist, "Artist should be consistent")
        XCTAssertEqual(result1?.album, result2?.album, "Album should be consistent")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that parsed metadata matches expected values
    func testParsedMetadataMatchesExpectedValues() async throws {
        // Given - A file with known Vorbis Comments
        let testFile = createTestOGGFileWithComments(
            title: "Cross-Check Song",
            artist: "Cross-Check Artist",
            album: "Cross-Check Album",
            year: 2024,
            trackNumber: 5
        )
        
        // When - Parse the file
        let result = try await parser.parse(fileURL: testFile)
        
        // Then - Metadata should match expected values
        XCTAssertNotNil(result, "Should parse metadata successfully")
        XCTAssertEqual(result?.title, "Cross-Check Song", "Title should match")
        XCTAssertEqual(result?.artist, "Cross-Check Artist", "Artist should match")
        XCTAssertEqual(result?.album, "Cross-Check Album", "Album should match")
        XCTAssertEqual(result?.year, 2024, "Year should match")
        XCTAssertEqual(result?.trackNumber, 5, "Track number should match")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
    }
    
    // MARK: - Error Conditions
    
    /// Test parsing corrupted Vorbis Comments
    func testParseCorruptedVorbisComments() async throws {
        // Given - A file with corrupted Vorbis Comments
        let corruptedFile = createCorruptedOGGFile()
        
        // When/Then - Should handle corruption gracefully
        do {
            _ = try await parser.parse(fileURL: corruptedFile)
            // Parser may return nil or throw error - both are acceptable
        } catch {
            XCTAssertTrue(error is TagParserError, "Should throw TagParserError if error occurs")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: corruptedFile)
    }
    
    /// Test parsing file without Vorbis Comments
    func testParseFileWithoutVorbisComments() async throws {
        // Given - A valid OGG file without Vorbis Comments
        let fileWithoutComments = createOGGFileWithoutComments()
        
        // When - Parse the file
        let result = try await parser.parse(fileURL: fileWithoutComments)
        
        // Then - Should return nil or basic Track
        // Parser may return nil or a Track with default values
        if let track = result {
            // If a Track is returned, it should have basic file information
            XCTAssertFalse(track.title.isEmpty || track.filePath.isEmpty, "Should have at least file path")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileWithoutComments)
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that parsing is performant
    func testParsingPerformance() async throws {
        // Given - A file with Vorbis Comments
        let testFile = createTestOGGFileWithComments(
            title: "Performance Test",
            artist: "Performance Artist",
            album: "Performance Album"
        )
        
        // When - Parse the file
        let startTime = Date()
        _ = try await parser.parse(fileURL: testFile)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (< 100ms)
        XCTAssertLessThan(duration, 0.1, "Parsing should complete within 100ms")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
    }
    
    // MARK: - Edge Cases
    
    /// Test parsing with very long comment values
    func testParseWithVeryLongCommentValues() async throws {
        // Given - A file with very long comment values
        let longTitle = String(repeating: "A", count: 1000)
        let longArtist = String(repeating: "B", count: 1000)
        let testFile = createTestOGGFileWithComments(
            title: longTitle,
            artist: longArtist,
            album: "Test Album"
        )
        
        // When - Parse the file
        let result = try await parser.parse(fileURL: testFile)
        
        // Then - Should handle long values correctly
        XCTAssertNotNil(result, "Should parse metadata with long values")
        XCTAssertEqual(result?.title, longTitle, "Should preserve long title")
        XCTAssertEqual(result?.artist, longArtist, "Should preserve long artist")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
    }
    
    /// Test parsing with special characters in comments
    func testParseWithSpecialCharacters() async throws {
        // Given - A file with special characters in comments
        let specialTitle = "Song with \"quotes\" & <tags>"
        let specialArtist = "Artist with émojis 🎵 and unicode 中文"
        let testFile = createTestOGGFileWithComments(
            title: specialTitle,
            artist: specialArtist,
            album: "Test Album"
        )
        
        // When - Parse the file
        let result = try await parser.parse(fileURL: testFile)
        
        // Then - Should handle special characters correctly
        XCTAssertNotNil(result, "Should parse metadata with special characters")
        XCTAssertEqual(result?.title, specialTitle, "Should preserve special characters in title")
        XCTAssertEqual(result?.artist, specialArtist, "Should preserve special characters in artist")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
    }
    
    // MARK: - Helper Methods
    
    private func createTempFile(extension ext: String, content: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
        FileManager.default.createFile(atPath: fileURL.path, contents: content)
        return fileURL
    }
    
    private func createTestOGGFileWithComments(
        title: String,
        artist: String,
        album: String,
        year: Int? = nil,
        trackNumber: Int? = nil
    ) -> URL {
        // Create a minimal OGG file structure with Vorbis Comments
        // The VorbisCommentsParser uses a simple string search, so we just need:
        // 1. "OggS" header at the start
        // 2. Comment strings like "TITLE=...", "ARTIST=...", etc. in the data
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).ogg")
        
        var oggData = Data()
        oggData.append(Data("OggS".utf8)) // OGG header
        
        // Add padding
        oggData.append(contentsOf: Data(repeating: 0x00, count: 20))
        
        // Add comment strings that the parser will search for
        var comments: [String] = [
            "TITLE=\(title)",
            "ARTIST=\(artist)",
            "ALBUM=\(album)"
        ]
        
        if let year = year {
            comments.append("DATE=\(year)")
        }
        
        if let trackNumber = trackNumber {
            comments.append("TRACKNUMBER=\(trackNumber)")
        }
        
        // Add comment strings with null terminators
        for comment in comments {
            oggData.append(Data(comment.utf8))
            oggData.append(0x00) // Null terminator
        }
        
        FileManager.default.createFile(atPath: fileURL.path, contents: oggData)
        return fileURL
    }
    
    private func createCorruptedOGGFile() -> URL {
        // Create a file with corrupted Vorbis Comments structure
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).ogg")
        
        // Create file with invalid OGG header
        var data = Data()
        data.append(contentsOf: "OggS".utf8) // Valid OGG header start
        data.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF]) // Invalid version/flags
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        
        return fileURL
    }
    
    private func createOGGFileWithoutComments() -> URL {
        // Create a valid OGG file without Vorbis Comments
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).ogg")
        
        // Create minimal OGG file (just header)
        var data = Data()
        data.append(contentsOf: "OggS".utf8) // OGG header
        data.append(contentsOf: [0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) // Minimal header
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        
        return fileURL
    }
}
