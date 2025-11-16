//
//  TagWriterCoordinatorTests.swift
//  MetadataEngineTests
//
//  TDD tests for TagWriterCoordinator following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for TagWriterCoordinator
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class TagWriterCoordinatorTests: XCTestCase {
    
    var coordinator: TagWriterCoordinator!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        coordinator = TagWriterCoordinator()
        
        // Create a unique temporary directory for each test run
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() async throws {
        coordinator = nil
        
        // Clean up the temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a mock audio file
    private func createMockAudioFile(fileName: String, fileSize: Int = 1024) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        let data = Data(repeating: 0x00, count: fileSize)
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that coordinator can write to MP3 files
    func testCoordinatorCanWriteMP3Files() {
        // Given - MP3 file extension
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        
        // When - Check if coordinator can handle MP3
        let canWrite = coordinator.canWrite(fileURL: mp3URL)
        
        // Then - Should support MP3
        XCTAssertTrue(canWrite, "Coordinator should support MP3 files")
    }
    
    /// Test that coordinator can write to FLAC files
    func testCoordinatorCanWriteFLACFiles() {
        // Given - FLAC file extension
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        
        // When - Check if coordinator can handle FLAC
        let canWrite = coordinator.canWrite(fileURL: flacURL)
        
        // Then - Should support FLAC
        XCTAssertTrue(canWrite, "Coordinator should support FLAC files")
    }
    
    /// Test that coordinator can write to M4A files
    func testCoordinatorCanWriteM4AFiles() {
        // Given - M4A file extension
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When - Check if coordinator can handle M4A
        let canWrite = coordinator.canWrite(fileURL: m4aURL)
        
        // Then - Should support M4A
        XCTAssertTrue(canWrite, "Coordinator should support M4A files")
    }
    
    /// Test that coordinator does not support unsupported formats
    func testCoordinatorDoesNotSupportUnsupportedFormats() {
        // Given - Unsupported file extensions
        let wavURL = URL(fileURLWithPath: "/test/song.wav")
        let aacURL = URL(fileURLWithPath: "/test/song.aac")
        
        // When/Then - Should not support unsupported formats
        XCTAssertFalse(coordinator.canWrite(fileURL: wavURL), "Coordinator should not support WAV files")
        XCTAssertFalse(coordinator.canWrite(fileURL: aacURL), "Coordinator should not support AAC files")
    }
    
    /// Test writing to MP3 file through coordinator
    func testWriteToMP3File() async throws {
        // Given
        let fileURL = try createMockAudioFile(fileName: "test.mp3")
        let track = Track(
            title: "Test Title",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
        
        // When
        try await coordinator.write(track: track, to: fileURL)
        
        // Then - File should exist and be writable
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    // MARK: - Boundary Conditions
    
    /// Test writing to file with empty extension
    func testWriteToFileWithEmptyExtension() async {
        // Given - File with no extension
        let fileURL = tempDirectory.appendingPathComponent("test")
        try? Data().write(to: fileURL)
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: fileURL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw unsupported format error
        do {
            try await coordinator.write(track: track, to: fileURL)
            XCTFail("Should throw error for file with empty extension")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .unsupportedFormat(format) = error as? TagWriterError {
                XCTAssertEqual(format, "", "Error should reference empty format")
            } else {
                XCTFail("Should throw unsupportedFormat error, but got \(error)")
            }
        }
    }
    
    /// Test writing to non-existent file
    func testWriteToNonExistentFile() async {
        // Given - Non-existent file URL
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.mp3")
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: nonExistentURL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw file not found error
        do {
            try await coordinator.write(track: track, to: nonExistentURL)
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
    
    // MARK: - Error Conditions
    
    /// Test writing to unsupported file type
    func testWriteToUnsupportedFileType() async {
        // Given - Unsupported file URL
        let unsupportedURL = tempDirectory.appendingPathComponent("unsupported.wav")
        try? Data().write(to: unsupportedURL)
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: unsupportedURL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw unsupported format error
        do {
            try await coordinator.write(track: track, to: unsupportedURL)
            XCTFail("Should throw error for unsupported file type")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .unsupportedFormat(format) = error as? TagWriterError {
                XCTAssertEqual(format, "wav", "Error should reference the correct format")
            } else {
                XCTFail("Should throw unsupportedFormat error, but got \(error)")
            }
        }
    }
    
    /// Test updating unsupported file type
    func testUpdateUnsupportedFileType() async {
        // Given - Unsupported file URL
        let unsupportedURL = tempDirectory.appendingPathComponent("unsupported_update.wav")
        try? Data().write(to: unsupportedURL)
        let track = Track(title: "Test", artist: "Artist", album: "Album", duration: 100, filePath: unsupportedURL.path, fileSize: 1000, bitrate: 320, sampleRate: 44100)
        
        // When/Then - Should throw unsupported format error
        do {
            try await coordinator.update(track: track, in: unsupportedURL)
            XCTFail("Should throw error for unsupported file type")
        } catch {
            XCTAssertTrue(error is TagWriterError, "Should throw TagWriterError")
            if case let .unsupportedFormat(format) = error as? TagWriterError {
                XCTAssertEqual(format, "wav", "Error should reference the correct format")
            } else {
                XCTFail("Should throw unsupportedFormat error, but got \(error)")
            }
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test coordinator routing performance
    func testCoordinatorRoutingPerformance() {
        // Given - Multiple file types
        let fileURLs = [
            URL(fileURLWithPath: "/test/song.mp3"),
            URL(fileURLWithPath: "/test/song.flac"),
            URL(fileURLWithPath: "/test/song.m4a")
        ]
        
        measure {
            // When - Check canWrite for each file type
            for url in fileURLs {
                _ = coordinator.canWrite(fileURL: url)
            }
        }
    }
}
