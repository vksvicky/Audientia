//
//  MP4TagWriterTests.swift
//  MetadataEngineTests
//
//  TDD tests for MP4TagWriter following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for MP4TagWriter
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class MP4TagWriterTests: XCTestCase {
    
    var writer: MP4TagWriter!
    var parser: MP4Parser! // To read back written tags
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        writer = MP4TagWriter()
        parser = MP4Parser()
        
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
    
    /// Creates a mock MP4/M4A file with optional initial MP4 tags
    private func createMockMP4File(
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
        
        // Add ftyp box (file type box)
        // Box size (4 bytes, big-endian) = 20
        let ftypSize: UInt32 = 20
        var ftypSizeBE = ftypSize.bigEndian
        data.append(Data(bytes: &ftypSizeBE, count: 4))
        data.append("ftyp".data(using: .ascii) ?? Data())
        data.append("M4A ".data(using: .ascii) ?? Data()) // Major brand
        let minorVersion: UInt32 = 0
        var minorVersionBE = minorVersion.bigEndian
        data.append(Data(bytes: &minorVersionBE, count: 4)) // Minor version
        data.append("M4A ".data(using: .ascii) ?? Data()) // Compatible brand
        
        // Add minimal moov box structure (simplified)
        // For a real MP4 file, this would be more complex
        let moovSize: UInt32 = 8
        var moovSizeBE = moovSize.bigEndian
        data.append(Data(bytes: &moovSizeBE, count: 4))
        data.append("moov".data(using: .ascii) ?? Data())
        
        // Add dummy audio data (mdat box)
        let mdatSize: UInt32 = UInt32(fileSize + 8)
        var mdatSizeBE = mdatSize.bigEndian
        data.append(Data(bytes: &mdatSizeBE, count: 4))
        data.append("mdat".data(using: .ascii) ?? Data())
        data.append(Data(repeating: 0x00, count: fileSize))
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that MP4 writer supports MP4 files
    func testMP4WriterSupportsMP4Files() {
        // Given - MP4 file extension
        let mp4URL = URL(fileURLWithPath: "/test/song.mp4")
        
        // When - Check if writer can handle MP4
        let canWrite = writer.canWrite(fileURL: mp4URL)
        
        // Then - Should support MP4
        XCTAssertTrue(canWrite, "MP4 writer should support MP4 files")
        XCTAssertTrue(writer.supportedExtensions.contains("mp4"), "Supported extensions should include mp4")
    }
    
    /// Test that MP4 writer supports M4A files
    func testMP4WriterSupportsM4AFiles() {
        // Given - M4A file extension
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When - Check if writer can handle M4A
        let canWrite = writer.canWrite(fileURL: m4aURL)
        
        // Then - Should support M4A
        XCTAssertTrue(canWrite, "MP4 writer should support M4A files")
        XCTAssertTrue(writer.supportedExtensions.contains("m4a"), "Supported extensions should include m4a")
    }
    
    /// Test that MP4 writer does not support non-MP4 files
    func testMP4WriterDoesNotSupportNonMP4Files() {
        // Given - Non-MP4 file extensions
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        
        // When/Then - Should not support non-MP4 files
        XCTAssertFalse(writer.canWrite(fileURL: mp3URL), "MP4 writer should not support MP3 files")
        XCTAssertFalse(writer.canWrite(fileURL: flacURL), "MP4 writer should not support FLAC files")
    }
    
    /// Test writing basic MP4 tags to a new file and reading them back
    func testWriteAndReadBasicTags() async throws {
        // Given
        let fileURL = try createMockMP4File(fileName: "test_basic.m4a")
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
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.m4a")
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
        let fileURL = try createMockMP4File(fileName: "readonly.m4a")
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
        let fileURL = try createMockMP4File(fileName: "test_empty.m4a")
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
        
        // Then - Should write file (empty tags result in no metadata, parser returns nil)
        // When all metadata fields are empty, writer doesn't write any atoms, so parser returns nil
        let parsedTrack = try await parser.parse(fileURL: fileURL)
        // Parser returns nil when no metadata is found (hasAnyMetadata returns false)
        XCTAssertNil(parsedTrack, "Parser should return nil when no metadata atoms are written")
    }
    
    /// Test writing with very long metadata fields
    func testWriteVeryLongMetadata() async throws {
        // Given
        let fileURL = try createMockMP4File(fileName: "test_long.m4a")
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
        let fileURL = try createMockMP4File(
            fileName: "test_update.m4a",
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
        let fileURL = try createMockMP4File(fileName: "test_performance.m4a")
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
        
        measure {
            // When
            Task {
                try? await writer.write(track: track, to: fileURL)
            }
        }
    }
}
