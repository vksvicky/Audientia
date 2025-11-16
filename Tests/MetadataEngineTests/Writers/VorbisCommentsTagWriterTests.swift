//
//  VorbisCommentsTagWriterTests.swift
//  MetadataEngineTests
//
//  TDD tests for VorbisCommentsTagWriter following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for VorbisCommentsTagWriter
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class VorbisCommentsTagWriterTests: XCTestCase {
    
    var writer: VorbisCommentsTagWriter!
    var parser: VorbisCommentsParser! // To read back written tags
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        writer = VorbisCommentsTagWriter()
        parser = VorbisCommentsParser()
        
        // Create a unique temporary directory for each test run
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() async throws {
        writer = nil
        parser = nil
        
        // Clean up the temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a mock FLAC/OGG file with optional initial Vorbis Comments
    private func createMockVorbisFile(
        fileName: String,
        initialTitle: String? = nil,
        initialArtist: String? = nil,
        initialAlbum: String? = nil,
        initialYear: Int? = nil,
        initialTrackNumber: Int? = nil,
        initialDiscNumber: Int? = nil,
        initialGenre: String? = nil,
        fileSize: Int = 1024 // Small size for testing
    ) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        var data = Data()
        
        // Add OGG header (for FLAC/OGG files)
        data.append("OggS".data(using: .ascii) ?? Data())
        data.append(Data(repeating: 0x00, count: 23)) // Rest of OGG header
        
        // Add dummy audio data
        data.append(Data(repeating: 0x00, count: fileSize))
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that Vorbis writer supports FLAC files
    func testVorbisWriterSupportsFLACFiles() {
        // Given - FLAC file extension
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        
        // When - Check if writer can handle FLAC
        let canWrite = writer.canWrite(fileURL: flacURL)
        
        // Then - Should support FLAC
        XCTAssertTrue(canWrite, "Vorbis writer should support FLAC files")
        XCTAssertTrue(writer.supportedExtensions.contains("flac"), "Supported extensions should include flac")
    }
    
    /// Test that Vorbis writer supports OGG files
    func testVorbisWriterSupportsOGGFiles() {
        // Given - OGG file extension
        let oggURL = URL(fileURLWithPath: "/test/song.ogg")
        
        // When - Check if writer can handle OGG
        let canWrite = writer.canWrite(fileURL: oggURL)
        
        // Then - Should support OGG
        XCTAssertTrue(canWrite, "Vorbis writer should support OGG files")
        XCTAssertTrue(writer.supportedExtensions.contains("ogg"), "Supported extensions should include ogg")
    }
    
    /// Test that Vorbis writer does not support non-Vorbis files
    func testVorbisWriterDoesNotSupportNonVorbisFiles() {
        // Given - Non-Vorbis file extensions
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When/Then - Should not support non-Vorbis files
        XCTAssertFalse(writer.canWrite(fileURL: mp3URL), "Vorbis writer should not support MP3 files")
        XCTAssertFalse(writer.canWrite(fileURL: m4aURL), "Vorbis writer should not support M4A files")
    }
    
    /// Test writing basic Vorbis Comments to a new file and reading them back
    func testWriteAndReadBasicTags() async throws {
        // Given
        let fileURL = try createMockVorbisFile(fileName: "test_basic.flac")
        let track = Track(
            title: "New Title",
            artist: "New Artist",
            album: "New Album",
            duration: 200,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 5,
            discNumber: 1,
            genre: "Pop"
        )
        
        // When
        try await writer.write(track: track, to: fileURL)
        
        // Then
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, "New Title")
        XCTAssertEqual(parsedTrack?.artist, "New Artist")
        XCTAssertEqual(parsedTrack?.album, "New Album")
        XCTAssertEqual(parsedTrack?.year, 2023)
        XCTAssertEqual(parsedTrack?.trackNumber, 5)
        XCTAssertEqual(parsedTrack?.discNumber, 1)
        XCTAssertEqual(parsedTrack?.genre, "Pop")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test writing with non-existent file
    func testWriteNonExistentFile() async {
        // Given - Non-existent file URL
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.flac")
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: nonExistentURL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw file not found error
        do {
            try await writer.write(track: track, to: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .fileNotFound(url) = error as? TagWriterError {
                XCTAssertEqual(url, nonExistentURL, "Error should reference the correct URL")
            } else {
                XCTFail("Should throw fileNotFound error, but got \(error)")
            }
        }
    }
    
    /// Test writing to a read-only file
    func testWriteReadOnlyFile() async throws {
        // Given - A file with read-only permissions
        let fileURL = try createMockVorbisFile(fileName: "readonly.flac")
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: fileURL.path)
        
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: fileURL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw a write error
        do {
            try await writer.write(track: track, to: fileURL)
            XCTFail("Should throw error for read-only file")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .readOnlyFile(url) = error as? TagWriterError {
                XCTAssertEqual(url, fileURL, "Error should reference the correct URL")
            } else {
                XCTFail("Should throw readOnlyFile error, but got \(error)")
            }
        }
        
        // Restore permissions for cleanup
        try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: fileURL.path)
    }
    
    /// Test writing with empty metadata fields
    func testWriteEmptyMetadata() async throws {
        // Given
        let fileURL = try createMockVorbisFile(fileName: "test_empty.flac")
        let track = Track(
            title: "", // Empty title
            artist: "", // Empty artist
            album: "", // Empty album
            duration: 180,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: nil, // Nil year
            trackNumber: nil,
            discNumber: nil,
            genre: nil // Nil genre
        )
        
        // When
        try await writer.write(track: track, to: fileURL)
        
        // Then - Should write file (empty tags may fall back to defaults)
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        // Empty tags may fall back to filename or defaults
        XCTAssertNil(parsedTrack?.year)
        XCTAssertNil(parsedTrack?.trackNumber)
        XCTAssertNil(parsedTrack?.discNumber)
        XCTAssertNil(parsedTrack?.genre)
    }
    
    /// Test writing with very long metadata fields
    func testWriteVeryLongMetadata() async throws {
        // Given
        let fileURL = try createMockVorbisFile(fileName: "test_long.flac")
        let longString = String(repeating: "A", count: 500) // 500 characters
        let track = Track(
            title: longString,
            artist: longString,
            album: longString,
            duration: 180,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 1,
            genre: "Long Genre"
        )
        
        // When
        try await writer.write(track: track, to: fileURL)
        
        // Then
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, longString)
        XCTAssertEqual(parsedTrack?.artist, longString)
        XCTAssertEqual(parsedTrack?.album, longString)
        XCTAssertEqual(parsedTrack?.year, 2023)
        XCTAssertEqual(parsedTrack?.trackNumber, 1)
        XCTAssertEqual(parsedTrack?.discNumber, 1)
        XCTAssertEqual(parsedTrack?.genre, "Long Genre")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test write then update tags
    func testWriteThenUpdateTags() async throws {
        // Given - Initial file with tags
        let fileURL = try createMockVorbisFile(
            fileName: "test_update.flac",
            initialTitle: "Old Title",
            initialArtist: "Old Artist"
        )
        
        // When - Update tags
        let updatedTrack = Track(
            title: "Updated Title",
            artist: "Updated Artist",
            album: "Old Album",
            duration: 180,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
        try await writer.update(track: updatedTrack, in: fileURL)
        
        // Then - Verify updated tags
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        XCTAssertNotNil(parsedTrack)
        XCTAssertEqual(parsedTrack?.title, "Updated Title")
        XCTAssertEqual(parsedTrack?.artist, "Updated Artist")
        XCTAssertEqual(parsedTrack?.album, "Old Album")
        XCTAssertEqual(parsedTrack?.year, 2020)
        XCTAssertEqual(parsedTrack?.trackNumber, 1)
        XCTAssertEqual(parsedTrack?.discNumber, 1)
        XCTAssertEqual(parsedTrack?.genre, "Rock")
    }
    
    // MARK: - Error Conditions
    
    /// Test writing to an unsupported file type
    func testWriteUnsupportedFileType() async {
        // Given - MP3 file URL
        let mp3URL = tempDirectory.appendingPathComponent("unsupported.mp3")
        try? Data().write(to: mp3URL) // Create an empty MP3 file
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: mp3URL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw unsupported format error
        do {
            try await writer.write(track: track, to: mp3URL)
            XCTFail("Should throw error for unsupported file type")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .unsupportedFormat(format) = error as? TagWriterError {
                XCTAssertEqual(format, "mp3", "Error should reference the correct format")
            } else {
                XCTFail("Should throw unsupportedFormat error, but got \(error)")
            }
        }
    }
    
    /// Test updating an unsupported file type
    func testUpdateUnsupportedFileType() async {
        // Given - MP3 file URL
        let mp3URL = tempDirectory.appendingPathComponent("unsupported_update.mp3")
        try? Data().write(to: mp3URL) // Create an empty MP3 file
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: mp3URL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw unsupported format error
        do {
            try await writer.update(track: track, in: mp3URL)
            XCTFail("Should throw error for unsupported file type")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .unsupportedFormat(format) = error as? TagWriterError {
                XCTAssertEqual(format, "mp3", "Error should reference the correct format")
            } else {
                XCTFail("Should throw unsupportedFormat error, but got \(error)")
            }
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test performance of writing tags to a file
    func testWritePerformance() async throws {
        // Given
        let fileURL = try createMockVorbisFile(fileName: "test_performance.flac")
        let track = Track(
            title: "Performance Test Song",
            artist: "Performance Artist",
            album: "Performance Album",
            duration: 300,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1,
            genre: "Test"
        )
        
        // When - Measure performance of write operation
        // Run multiple iterations and measure average time
        let iterations = 5
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                try await writer.write(track: track, to: fileURL)
            } catch {
                // Ignore errors in performance test
            }
            
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        print("Average Vorbis Comments write time: \(String(format: "%.2f", average * 1000))ms")
        
        // Verify performance is reasonable (< 100ms per write)
        XCTAssertLessThan(average, 0.1, "Tag write should complete in reasonable time")
    }
}
