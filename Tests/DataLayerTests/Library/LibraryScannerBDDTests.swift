//
//  LibraryScannerBDDTests.swift
//  DataLayerTests
//
//  BDD-style tests for library scanning functionality
//  Implements: "As a user, I want to scan my music folder and see all tracks"
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// BDD-style test suite for library scanning
/// Implements: "As a user, I want to scan my music folder and see all tracks"
@MainActor
final class LibraryScannerBDDTests: XCTestCase {
    
    // MARK: - User Scenario: Scan Music Folder
    
    /// BDD: As a user, when I scan my music folder, then I should see all audio tracks
    func testUserScansMusicFolderAndSeesAllTracks() async throws {
        // Given - User has a music folder with audio files
        let testDirectory = createTestDirectory()
        _ = createTestAudioFile(directory: testDirectory, name: "track1.mp3")
        _ = createTestAudioFile(directory: testDirectory, name: "track2.flac")
        _ = createTestAudioFile(directory: testDirectory, name: "track3.m4a")
        
        let scanner = LibraryScanner()
        
        // When - User scans the music folder
        let tracks = try await scanner.scan(directory: testDirectory)
        
        // Then - All audio tracks should be found
        XCTAssertEqual(tracks.count, 3, "Should find all 3 audio tracks")
        XCTAssertTrue(tracks.contains { $0.filePath.contains("track1.mp3") }, "Should find track1.mp3")
        XCTAssertTrue(tracks.contains { $0.filePath.contains("track2.flac") }, "Should find track2.flac")
        XCTAssertTrue(tracks.contains { $0.filePath.contains("track3.m4a") }, "Should find track3.m4a")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    /// BDD: As a user, when I scan an empty folder, then I should see no tracks
    func testUserScansEmptyFolderAndSeesNoTracks() async throws {
        // Given - User has an empty folder
        let testDirectory = createTestDirectory()
        let scanner = LibraryScanner()
        
        // When - User scans the empty folder
        let tracks = try await scanner.scan(directory: testDirectory)
        
        // Then - No tracks should be found
        XCTAssertEqual(tracks.count, 0, "Should find no tracks in empty folder")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    /// BDD: As a user, when I scan a folder with non-audio files, then only audio files should be found
    func testUserScansFolderWithMixedFilesAndOnlyAudioFilesFound() async throws {
        // Given - User has a folder with audio and non-audio files
        let testDirectory = createTestDirectory()
        _ = createTestAudioFile(directory: testDirectory, name: "track1.mp3")
        _ = createTestFile(directory: testDirectory, name: "document.pdf")
        _ = createTestFile(directory: testDirectory, name: "image.jpg")
        _ = createTestAudioFile(directory: testDirectory, name: "track2.flac")
        
        let scanner = LibraryScanner()
        
        // When - User scans the folder
        let tracks = try await scanner.scan(directory: testDirectory)
        
        // Then - Only audio files should be found
        XCTAssertEqual(tracks.count, 2, "Should find only 2 audio tracks")
        XCTAssertTrue(
            tracks.allSatisfy { $0.filePath.hasSuffix(".mp3") || $0.filePath.hasSuffix(".flac") },
            "All found files should be audio files"
        )
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Helper Methods
    
    private func createTestDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("LibraryScannerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    private func createTestAudioFile(directory: URL, name: String) -> URL {
        let fileURL = directory.appendingPathComponent(name)
        // Create a minimal valid audio file header (simplified for testing)
        let data = Data([0xFF, 0xFB, 0x90, 0x00]) // Minimal MP3 header
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        return fileURL
    }
    
    private func createTestFile(directory: URL, name: String) -> URL {
        let fileURL = directory.appendingPathComponent(name)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("test content".utf8))
        return fileURL
    }
}
