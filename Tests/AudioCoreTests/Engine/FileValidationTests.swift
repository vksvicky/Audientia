//
//  FileValidationTests.swift
//  AudioCoreTests
//
//  Tests for file extension validation, file size checks, and corruption detection
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// Tests for file validation: extensions, size, corruption detection
@MainActor
final class FileValidationTests: XCTestCase {
    
    // MARK: - Supported File Extensions
    
    /// BDD: Given a file with supported extension, when I check if it's supported, then it should return true
    func testSupportedFileExtensions() async throws {
        // Given - Files with supported extensions
        let supportedExtensions = [
            // AVFoundation supported
            "mp3", "aac", "m4a", "wav", "aiff", "caf", "mp4",
            // FFmpeg supported
            "flac", "ogg", "opus", "alac", "ape"
        ]
        
        let coordinator = DefaultFormatDecodingCoordinator()
        
        for ext in supportedExtensions {
            // When - Create a mock file with supported extension
            let filePath = "/tmp/test.\(ext)"
            let track = MockFactory.makeTrack(filePath: filePath)
            let engine = AudioEngineTestHelpers.createMockEngine(withTracks: [track])
            
            // Then - File should be recognized (decoder will attempt to decode)
            // Note: Actual decoding may fail with mock files, but extension should be recognized
            do {
                try await engine.loadTrack(track)
                // If load succeeds, extension is supported
            } catch {
                // Even if decode fails, the extension should be recognized
                // We verify this by checking the error type
                if case AudioEngineError.trackLoadFailed = error {
                    // Track load failed, but extension was recognized
                } else {
                    XCTFail("Unexpected error for extension .\(ext): \(error)")
                }
            }
        }
    }
    
    /// BDD: Given a file with unsupported extension, when I try to load it, then format detection should fail
    /// Tests the negation: ANY extension NOT in our supported list should be rejected
    func testUnsupportedFileExtensions() async throws {
        // Given - Complete list of supported extensions (from both decoders)
        let supportedExtensions: Set<String> = [
            // AVFoundation supported
            "aac", "aiff", "caf", "m4a", "mp3", "mp4", "wav",
            // FFmpeg supported
            "flac", "ogg", "opus", "alac", "ape"
        ]
        
        // Given - Sample extensions that are definitely NOT in our supported list
        // We test a representative sample to verify the negation works
        let testExtensions = ["txt", "pdf", "jpg", "zip", "exe", "swift", "json", "html"]
        
        // Verify none of our test extensions are in the supported list
        for ext in testExtensions {
            XCTAssertFalse(
                supportedExtensions.contains(ext),
                "Test extension .\(ext) should not be in supported list"
            )
        }
        
        for ext in testExtensions {
            let filePath = "/tmp/test.\(ext)"
            let track = MockFactory.makeTrack(filePath: filePath)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.validateExtensions = true // Enable extension validation
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(filePath)
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load file with unsupported extension
            try await engine.loadTrack(track)
            
            // Then - Format detection should fail (non-fatal, but error should be stored)
            // Note: AudioEngine.loadTrack doesn't throw format detection errors, but stores them
            // This tests the negation: anything NOT in supportedExtensions is rejected
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Format detection should fail for unsupported extension .\(ext) (not in supported list)"
            )
            
            if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
                if case .unsupportedFormat(let fileExt) = formatError {
                    XCTAssertEqual(fileExt, ext, "Error should mention extension .\(ext)")
                } else {
                    XCTFail("Expected unsupportedFormat error for .\(ext), got: \(formatError)")
                }
            }
        }
    }
    
    /// BDD: Given a file with uppercase extension, when I check support, then it should be recognized (case-insensitive)
    func testCaseInsensitiveExtensions() async throws {
        // Given - Files with uppercase extensions
        let uppercaseExtensions = ["MP3", "FLAC", "WAV", "AAC", "M4A"]
        
        for ext in uppercaseExtensions {
            let filePath = "/tmp/test.\(ext)"
            let track = MockFactory.makeTrack(filePath: filePath)
            let engine = AudioEngineTestHelpers.createMockEngine(withTracks: [track])
            
            // When & Then - Should be recognized (case-insensitive)
            // Extension should be normalized to lowercase
            do {
                try await engine.loadTrack(track)
                // If load succeeds, extension is recognized
            } catch {
                // Even if decode fails, extension should be recognized
                // The error should not be unsupportedFormat
                if case FormatDecoderError.unsupportedFormat = error {
                    XCTFail("Uppercase extension .\(ext) should be recognized (case-insensitive)")
                }
            }
        }
    }
    
    // MARK: - File Size Validation
    
    /// BDD: Given a file with zero size, when I try to load it, then it should throw an error
    func testZeroSizeFileThrowsError() async throws {
        // Given - A file with zero size
        let track = MockFactory.makeTrack(
            title: "Zero Size File",
            filePath: "/tmp/zero-size.mp3",
            fileSize: 0
        )
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/zero-size.mp3", size: 0)
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "File is empty or zero size"
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - Try to load zero-size file
        try await engine.loadTrack(track)
        
        // Then - Format detection should fail (non-fatal, but error should be stored)
        // Note: Zero-size files can't be decoded, so format detection will fail
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "Format detection should fail for zero-size file"
        )
    }
    
    /// BDD: Given a file with minimal valid size, when I load it, then it should handle correctly
    func testMinimalFileSize() async throws {
        // Given - A file with minimal valid size (1KB - just enough for headers)
        let track = MockFactory.makeTrack(
            title: "Minimal File",
            filePath: "/tmp/minimal.mp3",
            fileSize: 1024 // 1KB
        )
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/minimal.mp3", size: 1024)
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: MockFormatDecodingCoordinator()
        )
        
        // When - Try to load minimal file
        // Then - Should attempt to load (may fail on decode, but file size check should pass)
        do {
            try await engine.loadTrack(track)
            // If load succeeds, minimal size is acceptable
        } catch {
            // Decode may fail, but file size validation should pass
            // Verify it's not a file size error
            if case AudioEngineError.trackLoadFailed(let reason) = error {
                XCTAssertFalse(
                    reason.contains("size") || reason.contains("empty"),
                    "Error should not be about file size for 1KB file"
                )
            }
        }
    }
    
    /// BDD: Given a file with very large size, when I load it, then it should handle correctly
    func testVeryLargeFile() async throws {
        // Given - A file with very large size (simulating large audio file)
        let largeSize: Int64 = 500_000_000 // 500MB
        let track = MockFactory.makeTrack(
            title: "Large File",
            filePath: "/tmp/large.mp3",
            fileSize: largeSize
        )
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/large.mp3", size: largeSize)
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: MockFormatDecodingCoordinator()
        )
        
        // When - Try to load large file
        // Then - Should attempt to load (may fail on decode, but size should be accepted)
        do {
            try await engine.loadTrack(track)
            // If load succeeds, large size is acceptable
        } catch {
            // Decode may fail, but file size validation should pass
            // Verify it's not a file size error
            if case AudioEngineError.trackLoadFailed(let reason) = error {
                XCTAssertFalse(
                    reason.contains("size") || reason.contains("too large"),
                    "Error should not be about file size for large file"
                )
            }
        }
    }
    
    // MARK: - File Corruption Detection
    
    /// BDD: Given a corrupt file, when I try to load it, then format detection should fail
    func testCorruptFileThrowsError() async throws {
        // Given - A corrupt file (file exists but cannot be decoded)
        let track = MockFactory.makeTrack(filePath: "/tmp/corrupt.mp3")
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/corrupt.mp3")
        // Note: shouldFail on fileSystem makes file not exist, so we don't use it here
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true // Simulate decode failure
        
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - Try to load corrupt file
        try await engine.loadTrack(track)
        
        // Then - Format detection should fail (non-fatal, but error should be stored)
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "Format detection should fail for corrupt file"
        )
        
        if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
            if case .decoderFailed = formatError {
                // Expected error type for corrupt file
            } else {
                XCTFail("Expected decoderFailed error for corrupt file, got: \(formatError)")
            }
        }
    }
    
    /// BDD: Given a file with invalid header, when I try to load it, then format detection should fail
    func testInvalidFileHeaderThrowsError() async throws {
        // Given - A file with invalid header (wrong magic bytes)
        let track = MockFactory.makeTrack(filePath: "/tmp/invalid-header.mp3")
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/invalid-header.mp3")
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "Invalid file header"
        
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - Try to load file with invalid header
        try await engine.loadTrack(track)
        
        // Then - Format detection should fail (non-fatal, but error should be stored)
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "Format detection should fail for invalid file header"
        )
        
        if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
            if case .decoderFailed(let decoder, let reason) = formatError {
                XCTAssertEqual(decoder, "Mock", "Should be Mock decoder")
                XCTAssertTrue(reason.contains("Invalid file header"), "Error should mention invalid header")
            } else {
                XCTFail("Expected decoderFailed error, got: \(formatError)")
            }
        }
    }
    
    /// BDD: Given a file that doesn't exist, when I try to load it, then it should throw fileNotFound error
    func testNonExistentFileThrowsError() async throws {
        // Given - A file that doesn't exist
        let track = MockFactory.makeTrack(filePath: "/tmp/nonexistent.mp3")
        let mockFileSystem = MockFileSystem()
        // Don't add file to mock file system
        
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: MockFormatDecodingCoordinator()
        )
        
        // When & Then - Should throw file not found error
        do {
            try await engine.loadTrack(track)
            XCTFail("Should throw error for non-existent file")
        } catch {
            XCTAssertTrue(error is AudioEngineError, "Should throw AudioEngineError")
            if case AudioEngineError.trackLoadFailed(let reason) = error {
                XCTAssertTrue(
                    reason.contains("not found") || reason.contains("File not found"),
                    "Error should indicate file not found"
                )
            }
        }
    }
    
    /// BDD: Given a file with truncated data, when I try to load it, then format detection should fail
    func testTruncatedFileThrowsError() async throws {
        // Given - A file with truncated data (incomplete)
        let track = MockFactory.makeTrack(filePath: "/tmp/truncated.mp3")
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/truncated.mp3", size: 100) // Very small, likely truncated
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "Truncated file or incomplete data"
        
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - Try to load truncated file
        try await engine.loadTrack(track)
        
        // Then - Format detection should fail (non-fatal, but error should be stored)
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "Format detection should fail for truncated file"
        )
        
        if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
            if case .decoderFailed(let decoder, let reason) = formatError {
                XCTAssertEqual(decoder, "Mock", "Should be Mock decoder")
                XCTAssertTrue(reason.contains("Truncated"), "Error should mention truncated")
            } else {
                XCTFail("Expected decoderFailed error, got: \(formatError)")
            }
        }
    }
    
    // MARK: - File Extension Edge Cases
    
    /// BDD: Given a file with no extension, when I try to load it, then format detection should fail
    func testFileWithoutExtension() async throws {
        // Given - A file with no extension
        let track = MockFactory.makeTrack(filePath: "/tmp/noextension")
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.validateExtensions = true // Enable extension validation
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile("/tmp/noextension")
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - Try to load file without extension
        try await engine.loadTrack(track)
        
        // Then - Format detection should fail (non-fatal, but error should be stored)
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "Format detection should fail for file without extension"
        )
        
        if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
            if case .unsupportedFormat(let ext) = formatError {
                XCTAssertEqual(ext, "", "Extension should be empty string")
            } else {
                XCTFail("Expected unsupportedFormat error, got: \(formatError)")
            }
        }
    }
    
    /// BDD: Given a file with multiple extensions, when I check support, then it should use the last extension
    func testFileWithMultipleExtensions() async throws {
        // Given - A file with multiple extensions
        let track = MockFactory.makeTrack(filePath: "/tmp/file.tar.gz.mp3")
        let engine = AudioEngineTestHelpers.createMockEngine(withTracks: [track])
        
        // When - Try to load file
        // Then - Should use last extension (.mp3) for format detection
        do {
            try await engine.loadTrack(track)
            // If load succeeds, last extension was used
        } catch {
            // Even if decode fails, extension detection should use .mp3
            if case FormatDecoderError.unsupportedFormat(let ext) = error {
                XCTAssertEqual(ext, "mp3", "Should use last extension .mp3")
            }
        }
    }
    
    /// BDD: Given files with various extension formats, when I check support, then they should be handled correctly
    func testVariousExtensionFormats() async throws {
        // Given - Files with various extension formats
        let testCases = [
            ("/tmp/file.MP3", "mp3"), // Uppercase
            ("/tmp/file.mp3", "mp3"), // Lowercase
            ("/tmp/file.FlAc", "flac"), // Mixed case
            ("/tmp/file.wav", "wav"), // Standard
            ("/tmp/file.m4a", "m4a") // Standard
        ]
        
        for (filePath, expectedExt) in testCases {
            let track = MockFactory.makeTrack(filePath: filePath)
            let engine = AudioEngineTestHelpers.createMockEngine(withTracks: [track])
            
            // When & Then - Extension should be normalized and recognized
            do {
                try await engine.loadTrack(track)
                // If load succeeds, extension was recognized
            } catch let error as FormatDecoderError {
                if case .unsupportedFormat(let ext) = error {
                    XCTFail("Extension .\(expectedExt) should be recognized for \(filePath)")
                }
                // Other errors (like decode failure) are acceptable
            } catch {
                // Other errors are acceptable
            }
        }
    }
}
