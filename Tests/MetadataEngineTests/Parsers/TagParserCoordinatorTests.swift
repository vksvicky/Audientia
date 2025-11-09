//
//  TagParserCoordinatorTests.swift
//  MetadataEngineTests
//
//  TDD tests for Tag Parser Coordinator
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for TagParserCoordinator
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class TagParserCoordinatorTests: XCTestCase {
    
    var coordinator: TagParserCoordinator!
    var id3v2Parser: ID3v2Parser!
    var vorbisParser: VorbisCommentsParser!
    var mp4Parser: MP4Parser!
    
    override func setUp() async throws {
        try await super.setUp()
        id3v2Parser = ID3v2Parser()
        vorbisParser = VorbisCommentsParser()
        mp4Parser = MP4Parser()
        coordinator = TagParserCoordinator(parsers: [id3v2Parser, vorbisParser, mp4Parser])
    }
    
    override func tearDown() async throws {
        coordinator = nil
        id3v2Parser = nil
        vorbisParser = nil
        mp4Parser = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that coordinator routes MP3 files to ID3v2 parser
    func testCoordinatorRoutesMP3ToID3v2Parser() async throws {
        // Given - An MP3 file
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        
        // When - Check which parser can handle it
        let canParse = coordinator.canParse(fileURL: mp3URL)
        
        // Then - Should be able to parse (ID3v2 parser supports MP3)
        XCTAssertTrue(canParse, "Coordinator should route MP3 files to ID3v2 parser")
    }
    
    /// Test that coordinator routes FLAC files to Vorbis parser
    func testCoordinatorRoutesFLACToVorbisParser() async throws {
        // Given - A FLAC file
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        
        // When - Check which parser can handle it
        let canParse = coordinator.canParse(fileURL: flacURL)
        
        // Then - Should be able to parse (Vorbis parser supports FLAC)
        XCTAssertTrue(canParse, "Coordinator should route FLAC files to Vorbis parser")
    }
    
    /// Test that coordinator routes M4A files to MP4 parser
    func testCoordinatorRoutesM4AToMP4Parser() async throws {
        // Given - An M4A file
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When - Check which parser can handle it
        let canParse = coordinator.canParse(fileURL: m4aURL)
        
        // Then - Should be able to parse (MP4 parser supports M4A)
        XCTAssertTrue(canParse, "Coordinator should route M4A files to MP4 parser")
    }
    
    /// Test that coordinator routes OGG files to Vorbis parser
    func testCoordinatorRoutesOGGToVorbisParser() async throws {
        // Given - An OGG file
        let oggURL = URL(fileURLWithPath: "/test/song.ogg")
        
        // When - Check which parser can handle it
        let canParse = coordinator.canParse(fileURL: oggURL)
        
        // Then - Should be able to parse (Vorbis parser supports OGG)
        XCTAssertTrue(canParse, "Coordinator should route OGG files to Vorbis parser")
    }
    
    /// Test that coordinator routes MP4 files to MP4 parser
    func testCoordinatorRoutesMP4ToMP4Parser() async throws {
        // Given - An MP4 file
        let mp4URL = URL(fileURLWithPath: "/test/song.mp4")
        
        // When - Check which parser can handle it
        let canParse = coordinator.canParse(fileURL: mp4URL)
        
        // Then - Should be able to parse (MP4 parser supports MP4)
        XCTAssertTrue(canParse, "Coordinator should route MP4 files to MP4 parser")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test that coordinator returns false for unsupported formats
    func testCoordinatorReturnsFalseForUnsupportedFormats() {
        // Given - Files with unsupported extensions
        let txtURL = URL(fileURLWithPath: "/test/document.txt")
        let pdfURL = URL(fileURLWithPath: "/test/document.pdf")
        
        // When - Check if coordinator can parse them
        let canParseTxt = coordinator.canParse(fileURL: txtURL)
        let canParsePdf = coordinator.canParse(fileURL: pdfURL)
        
        // Then - Should return false
        XCTAssertFalse(canParseTxt, "Coordinator should not parse .txt files")
        XCTAssertFalse(canParsePdf, "Coordinator should not parse .pdf files")
    }
    
    /// Test that coordinator handles files with no extension
    func testCoordinatorHandlesFilesWithNoExtension() {
        // Given - A file with no extension
        let noExtURL = URL(fileURLWithPath: "/test/song")
        
        // When - Check if coordinator can parse it
        let canParse = coordinator.canParse(fileURL: noExtURL)
        
        // Then - Should return false
        XCTAssertFalse(canParse, "Coordinator should not parse files without extensions")
    }
    
    /// Test that coordinator handles case-insensitive extensions
    func testCoordinatorHandlesCaseInsensitiveExtensions() {
        // Given - Files with uppercase extensions
        let mp3UpperURL = URL(fileURLWithPath: "/test/song.MP3")
        let flacUpperURL = URL(fileURLWithPath: "/test/song.FLAC")
        
        // When - Check if coordinator can parse them
        let canParseMP3 = coordinator.canParse(fileURL: mp3UpperURL)
        let canParseFLAC = coordinator.canParse(fileURL: flacUpperURL)
        
        // Then - Should handle case-insensitively
        XCTAssertTrue(canParseMP3, "Coordinator should handle uppercase .MP3")
        XCTAssertTrue(canParseFLAC, "Coordinator should handle uppercase .FLAC")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that coordinator with no parsers returns false for all files
    func testCoordinatorWithNoParsersReturnsFalse() {
        // Given - A coordinator with no parsers
        let emptyCoordinator = TagParserCoordinator(parsers: [])
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        
        // When - Check if it can parse
        let canParse = emptyCoordinator.canParse(fileURL: mp3URL)
        
        // Then - Should return false
        XCTAssertFalse(canParse, "Coordinator with no parsers should return false")
    }
    
    // MARK: - Error Conditions
    
    /// Test that coordinator throws error for unsupported format when parsing
    func testCoordinatorThrowsErrorForUnsupportedFormat() async {
        // Given - A file with unsupported format
        let txtURL = URL(fileURLWithPath: "/test/document.txt")
        
        // When - Attempt to parse
        // Then - Should throw unsupportedFormat error
        do {
            _ = try await coordinator.parse(fileURL: txtURL)
            XCTFail("Should throw error for unsupported format")
        } catch let error as TagParserError {
            if case .unsupportedFormat = error {
                // Expected
            } else {
                XCTFail("Should throw unsupportedFormat error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw TagParserError, got: \(error)")
        }
    }
    
    /// Test that coordinator throws error for non-existent file
    func testCoordinatorThrowsErrorForNonExistentFile() async {
        // Given - A non-existent file
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/song.mp3")
        
        // When - Attempt to parse
        // Then - Should throw fileNotFound error
        do {
            _ = try await coordinator.parse(fileURL: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch let error as TagParserError {
            if case .fileNotFound = error {
                // Expected
            } else {
                XCTFail("Should throw fileNotFound error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw TagParserError, got: \(error)")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that coordinator efficiently selects the correct parser
    func testCoordinatorEfficientlySelectsParser() {
        // Given - Multiple file types
        let files = [
            URL(fileURLWithPath: "/test/song1.mp3"),
            URL(fileURLWithPath: "/test/song2.flac"),
            URL(fileURLWithPath: "/test/song3.m4a"),
            URL(fileURLWithPath: "/test/song4.ogg"),
            URL(fileURLWithPath: "/test/song5.mp4")
        ]
        
        // When - Check canParse for all files
        measure {
            for file in files {
                _ = coordinator.canParse(fileURL: file)
            }
        }
        // Then - Should complete quickly (e.g., < 1ms per file)
    }
    
    // MARK: - Edge Cases
    
    /// Test that coordinator handles files with multiple dots in name
    func testCoordinatorHandlesFilesWithMultipleDots() {
        // Given - A file with multiple dots (e.g., "song.backup.mp3")
        let multiDotURL = URL(fileURLWithPath: "/test/song.backup.mp3")
        
        // When - Check if coordinator can parse it
        let canParse = coordinator.canParse(fileURL: multiDotURL)
        
        // Then - Should use the last extension
        XCTAssertTrue(canParse, "Coordinator should handle files with multiple dots")
    }
    
    /// Test that coordinator handles empty file URLs
    func testCoordinatorHandlesEmptyFileURLs() {
        // Given - An empty file URL
        let emptyURL = URL(fileURLWithPath: "")
        
        // When - Check if coordinator can parse it
        let canParse = coordinator.canParse(fileURL: emptyURL)
        
        // Then - Should return false
        XCTAssertFalse(canParse, "Coordinator should return false for empty URLs")
    }
    
    /// Test that coordinator uses default parsers when initialized without parameters
    func testCoordinatorUsesDefaultParsers() {
        // Given - A coordinator with default initialization
        let defaultCoordinator = TagParserCoordinator()
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When - Check if it can parse various formats
        let canParseMP3 = defaultCoordinator.canParse(fileURL: mp3URL)
        let canParseFLAC = defaultCoordinator.canParse(fileURL: flacURL)
        let canParseM4A = defaultCoordinator.canParse(fileURL: m4aURL)
        
        // Then - Should support all default formats
        XCTAssertTrue(canParseMP3, "Default coordinator should support MP3")
        XCTAssertTrue(canParseFLAC, "Default coordinator should support FLAC")
        XCTAssertTrue(canParseM4A, "Default coordinator should support M4A")
    }
}
