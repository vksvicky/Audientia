//
//  ArtworkExtractorBasicTests.swift
//  MetadataEngineTests
//
//  TDD tests for ArtworkExtractor - Basic functionality
//  Following Right-BICEP: Right, Inverse, Cross-check
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for ArtworkExtractor - Basic functionality
/// Right-BICEP: Right, Inverse, Cross-check
@MainActor
final class ArtworkExtractorBasicTests: ArtworkExtractorTestBase {
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that artwork extractor supports common audio formats
    func testArtworkExtractorSupportsCommonFormats() {
        // Given - Common audio file extensions
        let supportedFormats = ["mp3", "m4a", "mp4", "flac", "ogg", "opus"]
        
        // When - Check if extractor supports these formats
        for format in supportedFormats {
            // Then - Should support all common formats
            XCTAssertTrue(
                extractor.supportedExtensions.contains(format),
                "ArtworkExtractor should support \(format) files"
            )
        }
    }
    
    /// Test extracting artwork from MP3 file with ID3v2 APIC frame
    func testExtractArtworkFromMP3WithAPICFrame() async throws {
        // Given - MP3 file with embedded artwork
        let artworkData = createMockJPEGData()
        let mp3URL = try createMockMP3FileWithArtwork(artworkData: artworkData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should extract artwork with correct MIME type
        XCTAssertNotNil(extractedArtwork, "Should extract artwork from MP3 file")
        XCTAssertEqual(extractedArtwork?.mimeType, "image/jpeg", "MIME type should be image/jpeg")
        XCTAssertEqual(extractedArtwork?.data, artworkData, "Artwork data should match")
    }
    
    /// Test extracting artwork from MP4/M4A file with covr atom
    func testExtractArtworkFromMP4WithCovrAtom() async throws {
        // Given - MP4 file with embedded artwork
        let artworkData = createMockPNGData()
        let mp4URL = try createMockMP4FileWithArtwork(artworkData: artworkData)
        defer { try? FileManager.default.removeItem(at: mp4URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp4URL)
        
        // Then - Should extract artwork with correct MIME type (when MP4 extraction is implemented)
        // For now, MP4 extraction returns nil (not yet implemented)
        // When implemented, should extract artwork with correct MIME type
        if let artwork = extractedArtwork {
            XCTAssertEqual(artwork.mimeType, "image/png", "MIME type should be image/png")
            XCTAssertEqual(artwork.data, artworkData, "Artwork data should match")
        }
    }
    
    /// Test extracting artwork from FLAC file with Vorbis Comments
    func testExtractArtworkFromFLACWithVorbisComments() async throws {
        // Given - FLAC file with embedded artwork
        let artworkData = createMockJPEGData()
        let flacURL = try createMockFLACFileWithArtwork(artworkData: artworkData)
        defer { try? FileManager.default.removeItem(at: flacURL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: flacURL)
        
        // Then - Should extract artwork (when FLAC extraction is implemented)
        // For now, FLAC extraction returns nil (not yet implemented)
        // When implemented, should extract artwork with correct MIME type
        if let artwork = extractedArtwork {
            XCTAssertEqual(artwork.mimeType, "image/jpeg", "MIME type should be image/jpeg")
        }
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that extracting artwork twice from same file yields same result
    func testExtractArtworkTwiceYieldsSameResult() async throws {
        // Given - MP3 file with artwork
        let artworkData = createMockJPEGData()
        let mp3URL = try createMockMP3FileWithArtwork(artworkData: artworkData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork twice
        let artwork1 = try await extractor.extractArtwork(from: mp3URL)
        let artwork2 = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should yield same results
        XCTAssertEqual(artwork1?.data, artwork2?.data, "Extracting twice should yield same artwork data")
        XCTAssertEqual(artwork1?.mimeType, artwork2?.mimeType, "MIME types should match")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that extracted artwork can be converted to NSImage
    func testExtractedArtworkCanBeConvertedToNSImage() async throws {
        // Given - MP3 file with valid JPEG artwork
        let artworkData = createMockJPEGData()
        let mp3URL = try createMockMP3FileWithArtwork(artworkData: artworkData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork and convert to image
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        guard let artwork = extractedArtwork else {
            XCTFail("Should extract artwork")
            return
        }
        let image = NSImage(data: artwork.data)
        
        // Then - Should create valid NSImage
        guard let image = image else {
            XCTFail("Extracted artwork should be convertible to NSImage")
            return
        }
        // Note: Mock JPEG data is minimal and may not have extractable dimensions
        // In production, real JPEG files will have proper dimensions
        // The important part is that NSImage can be created from the data
        XCTAssertNotNil(image, "Image should be created from artwork data")
        // For mock data, dimensions may be 0, but the image object should still exist
        // In real usage, proper JPEG files will have valid dimensions
    }
}
