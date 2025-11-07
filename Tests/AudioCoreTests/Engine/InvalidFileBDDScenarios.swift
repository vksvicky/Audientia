//
//  InvalidFileBDDScenarios.swift
//  AudioCoreTests
//
//  BDD-style scenarios for invalid/corrupt file handling
//  Implements: "As a user, I want the app to gracefully handle invalid or corrupt audio files"
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for invalid/corrupt file handling scenarios
/// Implements: "As a user, I want the app to gracefully handle invalid or corrupt audio files"
@MainActor
final class InvalidFileBDDScenarios: XCTestCase {
    
    // MARK: - User Scenario: Handle Empty Files
    
    /// BDD: As a user, when I try to play an empty audio file, then the app should show an error message
    func testUserTriesToPlayEmptyFile() async throws {
        // Given - User has an empty audio file
        guard let emptyFile = TestFixtures.invalidEmptyFile(format: "mp3") else {
            XCTFail("Empty file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
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
        
        // When - User tries to play the empty file
        try await engine.loadTrack(track)
        
        // Then - App should detect the error and store it
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should detect empty file error"
        )
    }
    
    // MARK: - User Scenario: Handle Corrupt Files
    
    /// BDD: As a user, when I try to play a corrupt audio file, then the app should show an error message
    func testUserTriesToPlayCorruptFile() async throws {
        // Given - User has a corrupt audio file (corrupted payload)
        guard let corruptFile = TestFixtures.corruptPayloadFile(format: "mp3") else {
            XCTFail("Corrupt file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
        }
        
        let track = MockFactory.makeTrack(filePath: corruptFile.path)
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile(corruptFile.path)
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "File is corrupted"
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - User tries to play the corrupt file
        try await engine.loadTrack(track)
        
        // Then - App should detect corruption and show error
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should detect corrupt file error"
        )
        
        if let formatError = engine.lastFormatDetectionError as? FormatDecoderError {
            if case .decoderFailed = formatError {
                // Expected error type for corrupt file
            } else {
                XCTFail("Expected decoderFailed error for corrupt file")
            }
        }
    }
    
    // MARK: - User Scenario: Handle Files with Wrong Headers
    
    /// BDD: As a user, when I try to play a file with invalid header, then the app should reject it
    func testUserTriesToPlayFileWithInvalidHeader() async throws {
        // Given - User has a file with invalid header
        guard let invalidHeaderFile = TestFixtures.invalidHeaderFile(format: "mp3") else {
            XCTFail("Invalid header file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
        }
        
        let track = MockFactory.makeTrack(filePath: invalidHeaderFile.path)
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile(invalidHeaderFile.path)
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "Invalid file header"
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - User tries to play file with invalid header
        try await engine.loadTrack(track)
        
        // Then - App should reject the file
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should reject file with invalid header"
        )
    }
    
    // MARK: - User Scenario: Handle Truncated Files
    
    /// BDD: As a user, when I try to play a truncated (incomplete) file, then the app should show an error
    func testUserTriesToPlayTruncatedFile() async throws {
        // Given - User has a truncated audio file
        guard let truncatedFile = TestFixtures.truncatedFile(format: "mp3") else {
            XCTFail("Truncated file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
        }
        
        let track = MockFactory.makeTrack(filePath: truncatedFile.path)
        let mockFileSystem = MockFileSystem()
        if let attributes = try? FileManager.default.attributesOfItem(atPath: truncatedFile.path),
           let size = attributes[.size] as? Int64 {
            mockFileSystem.addFile(truncatedFile.path, size: size)
        } else {
            mockFileSystem.addFile(truncatedFile.path, size: 100)
        }
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "File is truncated or incomplete"
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - User tries to play truncated file
        try await engine.loadTrack(track)
        
        // Then - App should detect truncation and show error
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should detect truncated file error"
        )
    }
    
    // MARK: - User Scenario: Handle Files with Corrupted Magic Bytes
    
    /// BDD: As a user, when I try to play a file with corrupted magic bytes, then the app should reject it immediately
    func testUserTriesToPlayFileWithCorruptedMagicBytes() async throws {
        // Given - User has a file with corrupted magic bytes
        guard let corruptMagicFile = TestFixtures.corruptMagicFile(format: "mp3") else {
            XCTFail("Corrupt magic file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
        }
        
        let track = MockFactory.makeTrack(filePath: corruptMagicFile.path)
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile(corruptMagicFile.path)
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "Invalid magic bytes"
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - User tries to play file with corrupted magic bytes
        try await engine.loadTrack(track)
        
        // Then - App should reject immediately (magic bytes checked first)
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should reject file with corrupted magic bytes immediately"
        )
    }
    
    // MARK: - User Scenario: Handle Files with Partial Corruption
    
    /// BDD: As a user, when I try to play a file with corruption in the middle, then the app should detect it during playback
    func testUserTriesToPlayFileWithPartialCorruption() async throws {
        // Given - User has a file with corruption in the middle
        guard let corruptMiddleFile = TestFixtures.corruptMiddleFile(format: "mp3") else {
            XCTFail("Corrupt middle file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
        }
        
        let track = MockFactory.makeTrack(filePath: corruptMiddleFile.path)
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile(corruptMiddleFile.path)
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.failureReason = "Corruption detected in audio data"
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: mockCoordinator
        )
        
        // When - User tries to play file with partial corruption
        try await engine.loadTrack(track)
        
        // Then - App should detect corruption during decoding
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should detect partial corruption during decoding"
        )
    }
    
    // MARK: - User Scenario: Handle Files with No Audio Data
    
    /// BDD: As a user, when I try to play a file that has a header but no audio data, then the app should show an error
    func testUserTriesToPlayFileWithNoAudioData() async throws {
        // Given - User has a file with header but no audio data
        guard let noAudioDataFile = TestFixtures.noAudioDataFile(format: "mp3") else {
            XCTFail("No audio data file fixture not available. Run: Scripts/generate_audio_test_fixtures.sh")
            return
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
        
        // When - User tries to play file with no audio data
        try await engine.loadTrack(track)
        
        // Then - App should detect missing audio data
        XCTAssertNotNil(
            engine.lastFormatDetectionError,
            "App should detect file with no audio data"
        )
    }
    
    // MARK: - User Scenario: Graceful Error Handling
    
    /// BDD: As a user, when I try to play various invalid files, then the app should handle all errors gracefully
    func testUserTriesVariousInvalidFiles() async throws {
        // Given - User has various types of invalid files
        let invalidFileTypes = [
            ("empty", TestFixtures.invalidEmptyFile(format: "mp3")),
            ("corrupt payload", TestFixtures.corruptPayloadFile(format: "mp3")),
            ("corrupt magic", TestFixtures.corruptMagicFile(format: "mp3")),
            ("truncated", TestFixtures.truncatedFile(format: "mp3")),
            ("no audio data", TestFixtures.noAudioDataFile(format: "mp3"))
        ]
        
        // When & Then - Each invalid file should be handled gracefully
        for (fileType, fileURL) in invalidFileTypes {
            guard let invalidFile = fileURL else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: invalidFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(invalidFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Invalid file: \(fileType)"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - User tries to play invalid file
            try await engine.loadTrack(track)
            
            // Then - App should handle error gracefully (not crash)
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "App should handle \(fileType) file error gracefully"
            )
        }
    }
    
    // MARK: - User Scenario: Cross-Format Consistency
    
    /// BDD: As a user, when I have invalid files in different formats, then the app should handle them consistently
    func testUserHasInvalidFilesInDifferentFormats() async throws {
        // Given - User has invalid files in different formats
        let formats = ["mp3", "flac", "wav", "aac"]
        let invalidType = "invalid_header"
        
        for format in formats {
            guard let invalidFile = TestFixtures.invalidHeaderFile(format: format) else {
                continue
            }
            
            let track = MockFactory.makeTrack(filePath: invalidFile.path)
            let mockFileSystem = MockFileSystem()
            mockFileSystem.addFile(invalidFile.path)
            let mockCoordinator = MockFormatDecodingCoordinator()
            mockCoordinator.shouldFail = true
            mockCoordinator.failureReason = "Invalid header"
            let engine = AudioEngine(
                fileSystem: mockFileSystem,
                formatCoordinator: mockCoordinator
            )
            
            // When - User tries to play invalid file in \(format) format
            try await engine.loadTrack(track)
            
            // Then - App should handle error consistently across formats
            XCTAssertNotNil(
                engine.lastFormatDetectionError,
                "App should handle \(invalidType) \(format) file consistently"
            )
        }
    }
}
