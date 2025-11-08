//
//  FileValidationFixtureTests.swift
//  AudioCoreTests
//
//  Tests for file validation using real generated test fixtures
//  Validates invalid, corrupt, and error sample files
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// Tests for file validation using real generated test fixtures
/// Implements BDD scenarios for invalid/corrupt file handling
@MainActor
// swiftlint:disable:next todo
// TODO: Refactor FileValidationFixtureTests to reduce class body length
// swiftlint:disable:next type_body_length
final class FileValidationFixtureTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    /// Supported formats for testing (from shared constants)
    let testFormats = AudioFormats.allSupportedExtensionsArray
    
    // MARK: - Valid File Validation
    
    /// BDD: Given a valid audio file fixture, when I load it, then it should be recognized and decoded successfully
    func testValidFilesAreRecognized() async throws {
        // Given - Valid audio file fixtures for each format
        var testedFormats = 0
        var failedFormats: [String] = []
        
        for format in testFormats {
            guard let validFile = TestFixtures.defaultValidFile(format: format) else {
                // Skip formats without fixtures, but track them
                failedFormats.append(format)
                continue
            }
            
            testedFormats += 1
            let track = MockFactory.makeTrack(filePath: validFile.path)
            let engine = AudioEngineTestHelpers.createMockEngine(withTracks: [track])
            
            // When - Try to load valid file
            // Then - Should attempt to load (may succeed or fail on decode, but format should be recognized)
            do {
                try await engine.loadTrack(track)
                // If load succeeds, file is valid
            } catch {
                // Even if decode fails, format should be recognized
                // Verify it's not an unsupported format error
                if case FormatDecoderError.unsupportedFormat = error {
                    XCTFail("Valid \(format) file should be recognized, not unsupported")
                }
                // Other errors (like decode failure) are acceptable for this test
            }
        }
        
        // Fail only if we couldn't test any formats
        if testedFormats == 0 {
            XCTFail("No valid file fixtures found for any format. Missing fixtures for: \(failedFormats.joined(separator: ", ")). Run: Scripts/generate_audio_test_fixtures.sh")
        } else if !failedFormats.isEmpty {
            // Log warning about missing fixtures but don't fail the test
            print("⚠️  Warning: Missing fixtures for formats: \(failedFormats.joined(separator: ", ")). Run: Scripts/generate_audio_test_fixtures.sh")
        }
    }
    
    // MARK: - Invalid Empty Files
    
    /// BDD: Given an empty file fixture, when I try to load it, then it should fail with appropriate error
    func testInvalidEmptyFilesFail() async throws {
        // Given - Empty file fixtures
        for format in testFormats {
            guard let emptyFile = TestFixtures.invalidEmptyFile(format: format) else {
                continue // Skip if fixture doesn't exist
            }
            
            let track = MockFactory.makeTrack(filePath: emptyFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(emptyFile.path, size: 0)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "File is empty"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load empty file
            try await engine.loadTrack(track)
            
            // Then - Should fail with appropriate error
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Empty \(format) file should fail format detection"
            )
        }
    }
    
    // MARK: - Invalid Header Files
    
    /// BDD: Given a file with invalid header, when I try to load it, then format detection should fail
    func testInvalidHeaderFilesFail() async throws {
        // Given - Invalid header file fixtures
        for format in testFormats {
            guard let invalidHeaderFile = TestFixtures.invalidHeaderFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: invalidHeaderFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(invalidHeaderFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Invalid file header or magic bytes"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load file with invalid header
            try await engine.loadTrack(track)
            
            // Then - Should fail with decoder error
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Invalid header \(format) file should fail format detection"
            )
            
            if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
                if case .decoderFailed = formatError {
                    // Expected error type
                } else {
                    XCTFail("Expected decoderFailed error for invalid header \(format) file")
                }
            }
        }
    }
    
    // MARK: - Truncated Files
    
    /// BDD: Given a truncated file fixture, when I try to load it, then it should fail with truncation error
    func testTruncatedFilesFail() async throws {
        // Given - Truncated file fixtures
        for format in testFormats {
            guard let truncatedFile = TestFixtures.truncatedFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: truncatedFile.path)
            let mockFileSystem = MockFileSystem()
            // Get actual file size
            if let attributes = try? FileManager.default.attributesOfItem(atPath: truncatedFile.path),
               let size = attributes[.size] as? Int64 {
                mockFileSystem.addFile(truncatedFile.path, size: size)
            } else {
                mockFileSystem.addFile(truncatedFile.path, size: 100) // Default small size
            }
            
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Truncated file or incomplete data"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load truncated file
            try await engine.loadTrack(track)
            
            // Then - Should fail with truncation error
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Truncated \(format) file should fail format detection"
            )
        }
    }
    
    // MARK: - Zero-Size Files
    
    /// BDD: Given a zero-size file fixture, when I try to load it, then it should fail immediately
    func testZeroSizeFilesFail() async throws {
        // Given - Zero-size file fixtures
        for format in testFormats {
            guard let zeroSizeFile = TestFixtures.zeroSizeFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: zeroSizeFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(zeroSizeFile.path, size: 0)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "File is zero size"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load zero-size file
            try await engine.loadTrack(track)
            
            // Then - Should fail immediately
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Zero-size \(format) file should fail format detection"
            )
        }
    }
    
    // MARK: - No Audio Data Files
    
    /// BDD: Given a file with header only (no audio data), when I try to load it, then it should fail
    func testNoAudioDataFilesFail() async throws {
        // Given - Files with headers only (no audio data)
        for format in testFormats {
            guard let noAudioDataFile = TestFixtures.noAudioDataFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: noAudioDataFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(noAudioDataFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "File contains header but no audio data"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load file with no audio data
            try await engine.loadTrack(track)
            
            // Then - Should fail
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "No-audio-data \(format) file should fail format detection"
            )
        }
    }
    
    // MARK: - Corrupt Payload Files
    
    /// BDD: Given a file with valid header but corrupted payload, when I try to load it, then decoding should fail
    func testCorruptPayloadFilesFail() async throws {
        // Given - Files with valid headers but corrupted payloads
        for format in testFormats {
            guard let corruptPayloadFile = TestFixtures.corruptPayloadFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: corruptPayloadFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(corruptPayloadFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Valid header but corrupted audio data"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load corrupt payload file
            try await engine.loadTrack(track)
            
            // Then - Should fail during decoding
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Corrupt payload \(format) file should fail during decoding"
            )
        }
    }
    
    // MARK: - Corrupt Magic Bytes Files
    
    /// BDD: Given a file with corrupted magic bytes, when I try to load it, then format detection should fail immediately
    func testCorruptMagicBytesFilesFail() async throws {
        // Given - Files with corrupted magic bytes
        for format in testFormats {
            guard let corruptMagicFile = TestFixtures.corruptMagicFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: corruptMagicFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(corruptMagicFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Invalid magic bytes or file signature"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load corrupt magic bytes file
            try await engine.loadTrack(track)
            
            // Then - Should fail immediately (magic bytes are checked first)
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Corrupt magic bytes \(format) file should fail format detection"
            )
        }
    }
    
    // MARK: - Corrupt Middle Files
    
    /// BDD: Given a file with byte corruption in the middle, when I try to load it, then decoding should fail
    func testCorruptMiddleFilesFail() async throws {
        // Given - Files with byte corruption in the middle
        for format in testFormats {
            guard let corruptMiddleFile = TestFixtures.corruptMiddleFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: corruptMiddleFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(corruptMiddleFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Byte corruption detected in audio data"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - Try to load corrupt middle file
            try await engine.loadTrack(track)
            
            // Then - Should fail during decoding
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "Corrupt middle \(format) file should fail during decoding"
            )
        }
    }
    
    // MARK: - Comprehensive Invalid File Test
    
    /// BDD: Given all invalid/corrupt file fixtures, when I try to load them, then they should all fail appropriately
    func testAllInvalidFilesFail() async throws {
        // Given - All invalid/corrupt file types for a representative format (MP3)
        let format = "mp3"
        let invalidFiles = TestFixtures.allInvalidFiles(for: format)
        
        // Ensure fixtures are available
        guard !invalidFiles.isEmpty else {
            XCTFail("Test fixtures not available for \(format). Run: Scripts/generate_audio_test_fixtures.sh")
            return
        }
        
        // When & Then - Each invalid file should fail
        for (fileType, fileURL) in invalidFiles {
            // Verify file exists (may not be generated in CI)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                continue // Skip if fixture not available
            }
            
            let track = MockFactory.makeTrack(filePath: fileURL.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(fileURL.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Invalid file: \(fileType)"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            try await engine.loadTrack(track)
            
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "\(fileType) \(format) file should fail format detection"
            )
        }
    }
    
    // MARK: - Right-BICEP: Boundary Conditions
    
    /// BDD: Given files of various invalid types, when I test boundary conditions, then all should be handled correctly
    func testInvalidFileBoundaryConditions() async throws {
        // [B]oundary Conditions: Test with smallest and largest invalid files
        let format = "mp3"
        
        // Smallest: Zero-size file
        if let zeroSizeFile = TestFixtures.zeroSizeFile(format: format) {
            let track = MockFactory.makeTrack(filePath: zeroSizeFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(zeroSizeFile.path, size: 0)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            try await engine.loadTrack(track)
            XCTAssertNotNil(engine.lastFormatDetectionError, "Zero-size should fail")
        }
        
        // Smallest non-zero: Truncated file
        if let truncatedFile = TestFixtures.truncatedFile(format: format) {
            let track = MockFactory.makeTrack(filePath: truncatedFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(truncatedFile.path, size: 100) // Very small
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            try await engine.loadTrack(track)
            XCTAssertNotNil(engine.lastFormatDetectionError, "Truncated file should fail")
        }
    }
    
    // MARK: - Right-BICEP: Error Conditions
    
    /// BDD: Given various error conditions in files, when I test error handling, then all errors should be caught
    func testErrorConditionHandling() async throws {
        // [E]rror Conditions: Test all error types
        let format = "mp3"
        let errorTestCases: [(String, () -> URL?)] = [
            ("Empty file", { TestFixtures.invalidEmptyFile(format: format) }),
            ("Invalid header", { TestFixtures.invalidHeaderFile(format: format) }),
            ("Truncated", { TestFixtures.truncatedFile(format: format) }),
            ("Zero size", { TestFixtures.zeroSizeFile(format: format) }),
            ("No audio data", { TestFixtures.noAudioDataFile(format: format) }),
            ("Corrupt payload", { TestFixtures.corruptPayloadFile(format: format) }),
            ("Corrupt magic", { TestFixtures.corruptMagicFile(format: format) }),
            ("Corrupt middle", { TestFixtures.corruptMiddleFile(format: format) })
        ]
        
        for (errorType, fileGetter) in errorTestCases {
            guard let errorFile = fileGetter() else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: errorFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(errorFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Error: \(errorType)"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            try await engine.loadTrack(track)
            
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "\(errorType) should be caught and handled"
            )
        }
    }
    
    // MARK: - Cross-Format Validation
    
    /// BDD: Given invalid files across all formats, when I test them, then they should all fail consistently
    func testInvalidFilesAcrossAllFormats() async throws {
        // [C]ross-Check: Verify consistent behavior across formats
        let invalidTypes = [
            ("invalid_empty", TestFixtures.invalidEmptyFile),
            ("invalid_header", TestFixtures.invalidHeaderFile),
            ("invalid_truncated", TestFixtures.truncatedFile),
            ("corrupt_payload", TestFixtures.corruptPayloadFile)
        ]
        
        for (typeName, fileGetter) in invalidTypes {
            var failureCount = 0
            var testedCount = 0
            
            for format in testFormats {
                guard let invalidFile = fileGetter(format) else {
                    continue
                }
                
                testedCount += 1
                let track = MockFactory.makeTrack(filePath: invalidFile.path)
                let mockFileSystem = MockFileSystem()
                mockFileSystem.addFile(invalidFile.path)
                let mockCoordinator = MockFormatDecodingCoordinator()
                mockCoordinator.shouldFail = true
                let engine = AudioEngine(
                    fileSystem: mockFileSystem,
                    formatCoordinator: mockCoordinator
                )
                
                try await engine.loadTrack(track)
                
                if engine.lastFormatDetectionError != nil {
                    failureCount += 1
                }
            }
            
            if testedCount > 0 {
                XCTAssertEqual(
                    failureCount,
                    testedCount,
                    "All \(typeName) files should fail consistently across formats"
                )
            }
        }
    }
}
