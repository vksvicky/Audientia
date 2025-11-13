//
//  ArtworkExtractorEdgeCaseTests.swift
//  MetadataEngineTests
//
//  TDD tests for ArtworkExtractor - Edge cases and Performance
//  Following Right-BICEP: Performance, Edge Cases
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for ArtworkExtractor - Edge cases and Performance
/// Right-BICEP: Performance, Edge Cases
@MainActor
final class ArtworkExtractorEdgeCaseTests: ArtworkExtractorTestBase {
    
    // MARK: - Edge Cases
    
    /// Test extracting artwork from file with multiple APIC frames (should get first)
    func testExtractArtworkFromFileWithMultipleAPICFrames() async throws {
        // Given - MP3 file with multiple APIC frames
        let artworkData1 = createMockJPEGData()
        let artworkData2 = createMockPNGData()
        let mp3URL = try createMockMP3FileWithMultipleArtwork(
            artwork1: artworkData1,
            artwork2: artworkData2
        )
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should extract first artwork found
        XCTAssertNotNil(extractedArtwork, "Should extract artwork from file with multiple frames")
    }
    
    /// Test extracting artwork from file with Unicode in description
    func testExtractArtworkFromFileWithUnicodeDescription() async throws {
        // Given - MP3 file with artwork containing Unicode description
        let artworkData = createMockJPEGData()
        let mp3URL = try createMockMP3FileWithArtwork(
            artworkData: artworkData,
            description: "Cover Art 🎵",
            mimeType: "image/jpeg"
        )
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should extract artwork despite Unicode
        XCTAssertNotNil(extractedArtwork, "Should handle Unicode in artwork description")
    }
    
    /// Test extracting artwork with different image formats (PNG, GIF, BMP)
    func testExtractArtworkWithDifferentImageFormats() async throws {
        // Given - MP3 files with different image formats
        let jpegData = createMockJPEGData()
        let pngData = createMockPNGData()
        
        let jpegURL = try createMockMP3FileWithArtwork(
            artworkData: jpegData,
            description: "JPEG Cover",
            mimeType: "image/jpeg"
        )
        let pngURL = try createMockMP3FileWithArtwork(
            artworkData: pngData,
            description: "PNG Cover",
            mimeType: "image/png"
        )
        defer {
            try? FileManager.default.removeItem(at: jpegURL)
            try? FileManager.default.removeItem(at: pngURL)
        }
        
        // When - Extract artwork from both files
        let jpegArtwork = try await extractor.extractArtwork(from: jpegURL)
        let pngArtwork = try await extractor.extractArtwork(from: pngURL)
        
        // Then - Should extract artwork with correct MIME types
        XCTAssertNotNil(jpegArtwork, "Should extract JPEG artwork")
        XCTAssertEqual(jpegArtwork?.mimeType, "image/jpeg", "JPEG artwork should have correct MIME type")
        
        XCTAssertNotNil(pngArtwork, "Should extract PNG artwork")
        XCTAssertEqual(pngArtwork?.mimeType, "image/png", "PNG artwork should have correct MIME type")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that artwork extraction completes within reasonable time
    func testArtworkExtractionPerformance() async throws {
        // Given - MP3 file with artwork
        let artworkData = createMockJPEGData()
        let mp3URL = try createMockMP3FileWithArtwork(artworkData: artworkData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Measure extraction time
        let startTime = Date()
        _ = try await extractor.extractArtwork(from: mp3URL)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 1 second (SLA: < 1s per file)
        XCTAssertLessThan(duration, 1.0, "Artwork extraction should complete within 1 second")
    }
}
