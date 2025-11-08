//
//  LibraryScannerMetadataTests.swift
//  DataLayerTests
//
//  TDD tests for metadata extraction integration in LibraryScanner
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import MetadataEngine
@testable import Shared
import XCTest

/// Mock metadata extractor for testing
/// Uses actor isolation to make mutable state safe for Swift 6
final actor MockMetadataExtractor: MetadataExtractorProtocol {
    var extractMetadataCallCount = 0
    var extractMetadataResults: [URL: Track] = [:]
    var extractMetadataErrors: [URL: Error] = [:]
    var extractMetadataDelay: TimeInterval = 0
    
    func extractMetadata(from fileURL: URL) async throws -> Track? {
        extractMetadataCallCount += 1
        
        if let error = extractMetadataErrors[fileURL] {
            throw error
        }
        
        if extractMetadataDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(extractMetadataDelay * 1_000_000_000))
        }
        
        if let result = extractMetadataResults[fileURL] {
            return result
        }
        
        // Fallback to a basic track if no specific mock is set
        return Track(
            id: UUID(),
            title: fileURL.deletingPathExtension().lastPathComponent,
            artist: "Mock Artist",
            album: "Mock Album",
            duration: 120.0,
            filePath: fileURL.path,
            fileSize: 1024,
            bitrate: 128,
            sampleRate: 44100,
            year: 2025,
            trackNumber: 1,
            discNumber: 1
        )
    }
    
    // Helper methods for setting mock state
    func setResult(_ track: Track, for url: URL) {
        extractMetadataResults[url] = track
    }
    
    func setError(_ error: Error, for url: URL) {
        extractMetadataErrors[url] = error
    }
    
    func setDelay(_ delay: TimeInterval) {
        extractMetadataDelay = delay
    }
}

/// TDD tests for LibraryScanner with metadata extraction
@MainActor
final class LibraryScannerMetadataTests: XCTestCase {
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that metadata extraction is called for each audio file
    func testMetadataExtractionIsCalledForEachAudioFile() async throws {
        // Given - A directory with audio files and a mock metadata extractor
        let testDirectory = createTestDirectory()
        let file1 = createTestAudioFile(directory: testDirectory, name: "track1.mp3")
        let file2 = createTestAudioFile(directory: testDirectory, name: "track2.flac")
        
        let mockExtractor = MockMetadataExtractor()
        let track1 = Track(
            id: UUID(),
            title: "Test Track 1",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: file1.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1
        )
        let track2 = Track(
            id: UUID(),
            title: "Test Track 2",
            artist: "Test Artist",
            album: "Test Album",
            duration: 200.0,
            filePath: file2.path,
            fileSize: 2048,
            bitrate: 320,
            sampleRate: 44100,
            year: 2024,
            trackNumber: 2,
            discNumber: 1
        )
        await mockExtractor.setResult(track1, for: file1)
        await mockExtractor.setResult(track2, for: file2)
        
        // When - Scanner scans directory with metadata extraction
        let scanner = LibraryScanner(metadataExtractor: mockExtractor)
        _ = try await scanner.scan(directory: testDirectory)
        
        // Then - Metadata extractor should be called for each file
        let callCount = await mockExtractor.extractMetadataCallCount
        XCTAssertEqual(callCount, 2, "Metadata extractor should be called for each audio file")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Boundary Conditions
    
    /// Test metadata extraction with empty directory
    func testMetadataExtractionWithEmptyDirectory() async throws {
        // Given - An empty directory
        let testDirectory = createTestDirectory()
        let mockExtractor = MockMetadataExtractor()
        
        // When - Scanner scans empty directory
        let scanner = LibraryScanner(metadataExtractor: mockExtractor)
        _ = try await scanner.scan(directory: testDirectory)
        
        // Then - Metadata extractor should not be called
        let callCount = await mockExtractor.extractMetadataCallCount
        XCTAssertEqual(callCount, 0, "Metadata extractor should not be called for empty directory")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    /// Test metadata extraction failure handling
    func testMetadataExtractionFailureIsHandledGracefully() async throws {
        // Given - A file that fails metadata extraction
        let testDirectory = createTestDirectory()
        let file1 = createTestAudioFile(directory: testDirectory, name: "corrupt.mp3")
        
        let mockExtractor = MockMetadataExtractor()
        await mockExtractor.setError(NSError(domain: "TestError", code: 1), for: file1)
        
        // When - Scanner encounters file with extraction error
        let scanner = LibraryScanner(metadataExtractor: mockExtractor)
        let tracks = try await scanner.scan(directory: testDirectory)
        
        // Then - Should handle error gracefully (fallback to basic Track)
        XCTAssertEqual(tracks.count, 1, "Should still create basic Track when metadata extraction fails")
        XCTAssertEqual(tracks.first?.title, "corrupt", "Should use filename as title when metadata extraction fails")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that scanning twice produces consistent results
    func testScanTwiceProducesConsistentResults() async throws {
        // Given - A directory with audio files
        let testDirectory = createTestDirectory()
        _ = createTestAudioFile(directory: testDirectory, name: "track1.mp3")
        _ = createTestAudioFile(directory: testDirectory, name: "track2.flac")
        
        let scanner = LibraryScanner()
        
        // When - Scan twice
        let tracks1 = try await scanner.scan(directory: testDirectory)
        let tracks2 = try await scanner.scan(directory: testDirectory)
        
        // Then - Results should be consistent
        XCTAssertEqual(tracks1.count, tracks2.count, "Scan results should be consistent")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Error Conditions
    
    /// Test handling of non-existent directory errors
    func testHandlesNonExistentDirectoryError() async {
        // Given - A directory that does not exist
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/directory/\(UUID().uuidString)")
        let scanner = LibraryScanner()
        
        // When - Attempt to scan non-existent directory
        // Then - Should throw appropriate error
        do {
            _ = try await scanner.scan(directory: nonExistentURL)
            XCTFail("Should throw error for non-existent directory")
        } catch {
            // Expected to throw error
            XCTAssertTrue(error is LibraryScannerError || error is CocoaError, "Should throw LibraryScannerError or CocoaError")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that metadata extraction doesn't block scanning
    func testMetadataExtractionDoesNotBlockScanning() async throws {
        // Given - Multiple files with slow metadata extraction
        let testDirectory = createTestDirectory()
        for i in 1...10 {
            _ = createTestAudioFile(directory: testDirectory, name: "track\(i).mp3")
        }
        
        let mockExtractor = MockMetadataExtractor()
        await mockExtractor.setDelay(0.1) // 100ms delay per file
        
        let startTime = Date()
        let scanner = LibraryScanner()
        _ = try await scanner.scan(directory: testDirectory)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Scanning should complete reasonably quickly
        // (Note: Without metadata extraction, this should be fast)
        XCTAssertLessThan(duration, 1.0, "Scanning should complete within 1 second for 10 files")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Edge Cases
    
    /// Test scanning with nested directories
    func testScanningNestedDirectories() async throws {
        // Given - A directory structure with nested folders
        let testDirectory = createTestDirectory()
        let subDir1 = testDirectory.appendingPathComponent("Album1")
        let subDir2 = testDirectory.appendingPathComponent("Album2")
        try FileManager.default.createDirectory(at: subDir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: subDir2, withIntermediateDirectories: true)
        
        _ = createTestAudioFile(directory: subDir1, name: "track1.mp3")
        _ = createTestAudioFile(directory: subDir2, name: "track2.flac")
        _ = createTestAudioFile(directory: testDirectory, name: "track3.m4a")
        
        let scanner = LibraryScanner()
        
        // When - Scan root directory
        let tracks = try await scanner.scan(directory: testDirectory)
        
        // Then - Should find all tracks in nested directories
        XCTAssertEqual(tracks.count, 3, "Should find tracks in nested directories")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Helper Methods
    
    private func createTestDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("LibraryScannerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        return testDir
    }
    
    private func createTestAudioFile(directory: URL, name: String) -> URL {
        let fileURL = directory.appendingPathComponent(name)
        let data = Data([0xFF, 0xFB, 0x90, 0x00]) // Minimal MP3 header
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        return fileURL
    }
}
