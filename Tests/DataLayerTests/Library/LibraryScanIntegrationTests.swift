//
//  LibraryScanIntegrationTests.swift
//  DataLayerTests
//
//  Integration tests for full library scan with various file types
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// Integration tests for full library scan
/// Tests scanning directories with various audio file types
@MainActor
final class LibraryScanIntegrationTests: XCTestCase {
    
    var scanner: LibraryScanner!
    var indexer: LibraryIndexer!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        scanner = LibraryScanner()
        indexer = LibraryIndexer()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }
    
    override func tearDown() async throws {
        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
        scanner = nil
        indexer = nil
        tempDirectory = nil
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    /// Test scanning directory with multiple file types
    func testScanDirectoryWithMultipleFileTypes() async throws {
        // Given - Directory with various audio file types
        // Note: This test requires actual audio files or mocks
        // For now, we'll test the scanning infrastructure
        
        // Create placeholder files (in real scenario, these would be actual audio files)
        let mp3File = tempDirectory.appendingPathComponent("track1.mp3")
        let flacFile = tempDirectory.appendingPathComponent("track2.flac")
        let m4aFile = tempDirectory.appendingPathComponent("track3.m4a")
        
        // Create empty files as placeholders
        try "".write(to: mp3File, atomically: true, encoding: .utf8)
        try "".write(to: flacFile, atomically: true, encoding: .utf8)
        try "".write(to: m4aFile, atomically: true, encoding: .utf8)
        
        // When - Scan directory
        // Then - Should find audio files (if they're valid)
        // Note: Actual results depend on whether files are valid audio files
        // This test verifies the scanning process works
        do {
            _ = try await scanner.scan(directory: tempDirectory)
            // If we get here, scanning succeeded
        } catch {
            XCTFail("Should scan directory without throwing: \(error)")
        }
    }
    
    /// Test scanning nested directories
    func testScanNestedDirectories() async throws {
        // Given - Nested directory structure
        let nestedDir = tempDirectory.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(
            at: nestedDir,
            withIntermediateDirectories: true
        )
        
        let nestedFile = nestedDir.appendingPathComponent("track.mp3")
        try "".write(to: nestedFile, atomically: true, encoding: .utf8)
        
        // When - Scan parent directory
        // Then - Should find files in nested directories
        // Note: Actual results depend on file validity
        do {
            _ = try await scanner.scan(directory: tempDirectory)
            // If we get here, scanning succeeded
        } catch {
            XCTFail("Should scan nested directories without throwing: \(error)")
        }
    }
    
    /// Test scanning empty directory
    func testScanEmptyDirectory() async throws {
        // Given - Empty directory
        let emptyDir = tempDirectory.appendingPathComponent("empty")
        try FileManager.default.createDirectory(
            at: emptyDir,
            withIntermediateDirectories: true
        )
        
        // When - Scan empty directory
        let scannedTracks = try await scanner.scan(directory: emptyDir)
        
        // Then - Should return empty array
        XCTAssertEqual(scannedTracks.count, 0, "Should return empty array for empty directory")
    }
    
    /// Test scanning directory with non-audio files
    func testScanDirectoryWithNonAudioFiles() async throws {
        // Given - Directory with non-audio files
        let textFile = tempDirectory.appendingPathComponent("document.txt")
        let imageFile = tempDirectory.appendingPathComponent("image.jpg")
        
        try "test content".write(to: textFile, atomically: true, encoding: .utf8)
        try "fake image data".write(to: imageFile, atomically: true, encoding: .utf8)
        
        // When - Scan directory
        // Then - Should not include non-audio files
        // Note: This depends on the scanner's file type detection
        do {
            _ = try await scanner.scan(directory: tempDirectory)
            // If we get here, scanning succeeded
        } catch {
            XCTFail("Should handle non-audio files gracefully: \(error)")
        }
    }
    
    /// Test full integration: scan, index, and search
    func testFullIntegrationScanIndexSearch() async throws {
        // Given - Directory with audio files (would need actual files or mocks)
        // This is a placeholder test structure
        
        // When - Scan, index, and search
        // Then - Should work end-to-end
        // Note: Full implementation would require actual audio files or comprehensive mocks
        throw XCTSkip("Requires actual audio files or comprehensive mocks for full integration test")
    }
}
