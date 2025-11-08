//
//  ID3v2ParserTests.swift
//  MetadataEngineTests
//
//  TDD tests for ID3v2 tag parser
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for ID3v2Parser
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class ID3v2ParserTests: XCTestCase {
    
    var parser: ID3v2Parser!
    
    override func setUp() async throws {
        try await super.setUp()
        parser = ID3v2Parser()
    }
    
    override func tearDown() async throws {
        parser = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that ID3v2 parser supports MP3 files
    func testID3v2ParserSupportsMP3Files() {
        // Given - MP3 file extension
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        
        // When - Check if parser can handle MP3
        let canParse = parser.canParse(fileURL: mp3URL)
        
        // Then - Should support MP3
        XCTAssertTrue(canParse, "ID3v2 parser should support MP3 files")
        XCTAssertTrue(parser.supportedExtensions.contains("mp3"), "Supported extensions should include mp3")
    }
    
    /// Test that ID3v2 parser does not support non-MP3 files
    func testID3v2ParserDoesNotSupportNonMP3Files() {
        // Given - Non-MP3 file extensions
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When/Then - Should not support non-MP3 files
        XCTAssertFalse(parser.canParse(fileURL: flacURL), "ID3v2 parser should not support FLAC files")
        XCTAssertFalse(parser.canParse(fileURL: m4aURL), "ID3v2 parser should not support M4A files")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test parsing with non-existent file
    func testParseNonExistentFile() async {
        // Given - Non-existent file URL
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/file.mp3")
        
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
        let emptyFile = createTempFile(extension: "mp3", content: Data())
        
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
        // Given - A file with ID3v2 tags
        let testFile = createTestMP3FileWithTags(
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
        // Given - A file with known ID3v2 tags
        let testFile = createTestMP3FileWithTags(
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
    
    /// Test parsing corrupted ID3v2 tag
    func testParseCorruptedID3v2Tag() async throws {
        // Given - A file with corrupted ID3v2 tag
        let corruptedFile = createCorruptedMP3File()
        
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
    
    /// Test parsing file without ID3v2 tags
    func testParseFileWithoutID3v2Tags() async throws {
        // Given - A valid MP3 file without ID3v2 tags
        let fileWithoutTags = createMP3FileWithoutTags()
        
        // When - Parse the file
        let result = try await parser.parse(fileURL: fileWithoutTags)
        
        // Then - Should return nil or basic Track
        // Parser may return nil or a Track with default values
        if let track = result {
            // If a Track is returned, it should have basic file information
            XCTAssertFalse(track.title.isEmpty || track.filePath.isEmpty, "Should have at least file path")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileWithoutTags)
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that parsing is performant
    func testParsingPerformance() async throws {
        // Given - A file with ID3v2 tags
        let testFile = createTestMP3FileWithTags(
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
    
    /// Test parsing with very long tag values
    func testParseWithVeryLongTagValues() async throws {
        // Given - A file with very long tag values
        let longTitle = String(repeating: "A", count: 1000)
        let longArtist = String(repeating: "B", count: 1000)
        let testFile = createTestMP3FileWithTags(
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
    
    /// Test parsing with special characters in tags
    func testParseWithSpecialCharacters() async throws {
        // Given - A file with special characters in tags
        let specialTitle = "Song with \"quotes\" & <tags>"
        let specialArtist = "Artist with émojis 🎵 and unicode 中文"
        let testFile = createTestMP3FileWithTags(
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
    
    private func createTestMP3FileWithTags(
        title: String,
        artist: String,
        album: String,
        year: Int? = nil,
        trackNumber: Int? = nil
    ) -> URL {
        // Create a minimal MP3 file structure with ID3v2 tags
        // This is a simplified version - real implementation would need proper MP3 + ID3v2 structure
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp3")
        
        // For now, create a placeholder file
        // In real implementation, this would create a proper MP3 file with ID3v2 tags
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        
        return fileURL
    }
    
    private func createCorruptedMP3File() -> URL {
        // Create a file with corrupted ID3v2 tag structure
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp3")
        
        // Create file with invalid ID3v2 header
        var data = Data()
        data.append(contentsOf: "ID3".utf8) // Valid ID3 header start
        data.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF]) // Invalid version/flags
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        
        return fileURL
    }
    
    private func createMP3FileWithoutTags() -> URL {
        // Create a valid MP3 file without ID3v2 tags
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp3")
        
        // Create minimal MP3 file (just frame sync pattern)
        var data = Data()
        data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00]) // MP3 frame sync
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        
        return fileURL
    }
}
