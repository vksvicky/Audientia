//
//  LibraryScannerFullScanIntegrationTests.swift
//  DataLayerTests
//
//  Integration tests for full library scan with various file types
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
import Foundation
@testable import Shared
import XCTest

/// Integration tests for full library scan
@MainActor
final class LibraryScannerFullScanIntegrationTests: XCTestCase {
    
    var tempDirectory: URL!
    var scanner: LibraryScanner!
    var indexer: LibraryIndexer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        
        indexer = LibraryIndexer()
        scanner = LibraryScanner()
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        try? await indexer.clear()
        scanner = nil
        indexer = nil
        
        try await super.tearDown()
    }
    
    /// Test full library scan with various file types
    func testFullLibraryScanWithVariousFileTypes() async throws {
        // Given - Create test files of various types (simulated)
        // Note: In a real test, we'd create actual audio files or use fixtures
        [
            "song1.mp3",
            "song2.flac",
            "song3.m4a",
            "song4.ogg",
            "song5.wav"
        ].forEach { _ = createTestFile(name: $0) }
        
        // When - Scan the directory
        let scannedTracks = try await scanner.scan(directory: tempDirectory)
        
        // Then - Should discover all audio file types
        XCTAssertEqual(
            scannedTracks.count,
            5,
            "Should discover all 5 audio files"
        )
        
        // Verify file types are recognized
        let fileExtensions = Set(scannedTracks.map { URL(fileURLWithPath: $0.filePath).pathExtension.lowercased() })
        XCTAssertTrue(fileExtensions.contains("mp3"), "Should find MP3 files")
        XCTAssertTrue(fileExtensions.contains("flac"), "Should find FLAC files")
        XCTAssertTrue(fileExtensions.contains("m4a"), "Should find M4A files")
        XCTAssertTrue(fileExtensions.contains("ogg"), "Should find OGG files")
        XCTAssertTrue(fileExtensions.contains("wav"), "Should find WAV files")
    }
    
    /// Test full library scan with nested directories
    func testFullLibraryScanWithNestedDirectories() async throws {
        // Given - Create nested directory structure
        let subDir1 = tempDirectory.appendingPathComponent("Artist1")
        let subDir2 = tempDirectory.appendingPathComponent("Artist2")
        
        try FileManager.default.createDirectory(
            at: subDir1,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: subDir2,
            withIntermediateDirectories: true
        )
        
        _ = createTestFile(name: "song1.mp3", in: subDir1)
        _ = createTestFile(name: "song2.mp3", in: subDir2)
        
        // When - Scan the root directory
        let scannedTracks = try await scanner.scan(directory: tempDirectory)
        
        // Then - Should discover tracks in nested directories
        XCTAssertEqual(
            scannedTracks.count,
            2,
            "Should discover both tracks from nested directories"
        )
        
        // Verify tracks are from both subdirectories
        let trackPaths = scannedTracks.map { $0.filePath }
        let hasSong1 = trackPaths.contains { $0.contains("Artist1") && $0.contains("song1") }
        let hasSong2 = trackPaths.contains { $0.contains("Artist2") && $0.contains("song2") }
        XCTAssertTrue(hasSong1, "Should find song1 in Artist1 directory")
        XCTAssertTrue(hasSong2, "Should find song2 in Artist2 directory")
    }
    
    /// Test full library scan handles invalid files gracefully
    func testFullLibraryScanHandlesInvalidFiles() async throws {
        // Given - Create mix of valid and invalid files
        _ = createTestFile(name: "valid.mp3")
        _ = createTestFile(name: "invalid.txt") // Non-audio file
        _ = createTestFile(name: "corrupt.mp3", content: Data("not audio".utf8))
        
        // When - Scan directory
        let scannedTracks = try await scanner.scan(directory: tempDirectory)
        
        // Then - Should handle invalid files gracefully
        // Should only return valid audio files, not .txt files
        XCTAssertEqual(
            scannedTracks.count,
            2,
            "Should only return valid audio files (valid.mp3 and corrupt.mp3)"
        )
        
        // Verify .txt file is not included
        let trackPaths = scannedTracks.map { URL(fileURLWithPath: $0.filePath).lastPathComponent }
        XCTAssertFalse(
            trackPaths.contains("invalid.txt"),
            "Should not include non-audio files"
        )
        
        // Verify valid .mp3 files are included
        XCTAssertTrue(
            trackPaths.contains("valid.mp3"),
            "Should include valid audio files"
        )
    }
    
    /// Test full library scan performance with many files
    func testFullLibraryScanPerformance() async throws {
        // Given - Create many test files (100)
        for i in 1...100 {
            _ = createTestFile(name: "song\(i).mp3")
        }
        
        // When - Scan directory
        let startTime = Date()
        let scannedTracks = try await scanner.scan(directory: tempDirectory)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should discover all files and complete in reasonable time
        XCTAssertEqual(
            scannedTracks.count,
            100,
            "Should discover all 100 audio files"
        )
        XCTAssertLessThan(
            duration,
            10.0,
            "Should scan 100 files in less than 10 seconds"
        )
    }
    
    // MARK: - Helpers
    
    private func createTestFile(name: String, in directory: URL? = nil, content: Data? = nil) -> URL {
        guard let dir = directory ?? tempDirectory else {
            fatalError("tempDirectory must be set")
        }
        let fileURL = dir.appendingPathComponent(name)
        let data = content ?? Data("fake audio content".utf8)
        FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        return fileURL
    }
}
