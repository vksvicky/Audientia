//
//  ArtworkExtractorErrorTests.swift
//  MetadataEngineTests
//
//  TDD tests for ArtworkExtractor - Error and Boundary conditions
//  Following Right-BICEP: Boundary, Error
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for ArtworkExtractor - Error and Boundary conditions
/// Right-BICEP: Boundary, Error
@MainActor
final class ArtworkExtractorErrorTests: ArtworkExtractorTestBase {
    
    // MARK: - Boundary Conditions
    
    /// Test extracting artwork from file with no artwork
    func testExtractArtworkFromFileWithNoArtwork() async throws {
        // Given - MP3 file without artwork
        let mp3URL = try createMockMP3FileWithoutArtwork()
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should return nil (no artwork found)
        XCTAssertNil(extractedArtwork, "Should return nil when no artwork is present")
    }
    
    /// Test extracting artwork from very large artwork file
    func testExtractArtworkFromFileWithLargeArtwork() async throws {
        // Given - MP3 file with large artwork (5MB)
        let largeArtworkData = Data(repeating: 0xFF, count: 5 * 1024 * 1024)
        let mp3URL = try createMockMP3FileWithArtwork(artworkData: largeArtworkData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should extract large artwork
        XCTAssertNotNil(extractedArtwork, "Should extract large artwork")
        XCTAssertEqual(extractedArtwork?.data.count, largeArtworkData.count, "Large artwork size should match")
    }
    
    /// Test extracting artwork from file with very small artwork
    func testExtractArtworkFromFileWithSmallArtwork() async throws {
        // Given - MP3 file with tiny artwork (1x1 pixel)
        let smallArtworkData = createMockTinyJPEGData()
        let mp3URL = try createMockMP3FileWithArtwork(artworkData: smallArtworkData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When - Extract artwork
        let extractedArtwork = try await extractor.extractArtwork(from: mp3URL)
        
        // Then - Should extract small artwork
        XCTAssertNotNil(extractedArtwork, "Should extract small artwork")
    }
    
    /// Test extracting artwork from unsupported file format
    func testExtractArtworkFromUnsupportedFormat() async throws {
        // Given - Unsupported file format
        let txtURL = tempDirectory.appendingPathComponent("test.txt")
        try "test content".write(to: txtURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: txtURL) }
        
        // When/Then - Should throw unsupported format error
        do {
            _ = try await extractor.extractArtwork(from: txtURL)
            XCTFail("Should throw unsupported format error")
        } catch ArtworkExtractorError.unsupportedFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Error Conditions
    
    /// Test extracting artwork from non-existent file
    func testExtractArtworkFromNonExistentFile() async throws {
        // Given - Non-existent file URL
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.mp3")
        
        // When/Then - Should throw file not found error
        do {
            _ = try await extractor.extractArtwork(from: nonExistentURL)
            XCTFail("Should throw file not found error")
        } catch ArtworkExtractorError.fileNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test extracting artwork from corrupted file
    func testExtractArtworkFromCorruptedFile() async throws {
        // Given - Corrupted MP3 file
        let corruptedURL = tempDirectory.appendingPathComponent("corrupted.mp3")
        let corruptedData = Data([0xFF, 0xFE, 0xFD, 0xFC]) // Invalid data
        try corruptedData.write(to: corruptedURL)
        defer { try? FileManager.default.removeItem(at: corruptedURL) }
        
        // When/Then - Should handle gracefully (return nil or throw appropriate error)
        do {
            let artwork = try await extractor.extractArtwork(from: corruptedURL)
            // May return nil if no artwork found in corrupted file
            XCTAssertNil(artwork, "Corrupted file should not yield artwork")
        } catch {
            // Or may throw extraction failed error
            if case ArtworkExtractorError.extractionFailed = error {
                // Expected error
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    /// Test extracting artwork from file with invalid image data
    func testExtractArtworkFromFileWithInvalidImageData() async throws {
        // Given - MP3 file with invalid image data in APIC frame
        let invalidImageData = Data([0x00, 0x01, 0x02, 0x03]) // Not valid image data
        let mp3URL = try createMockMP3FileWithInvalidArtwork(artworkData: invalidImageData)
        defer { try? FileManager.default.removeItem(at: mp3URL) }
        
        // When/Then - Should handle gracefully
        do {
            let artwork = try await extractor.extractArtwork(from: mp3URL)
            // May return nil or throw error
            if let artwork = artwork {
                // If returned, data should be present but may not be valid image
                XCTAssertFalse(artwork.data.isEmpty, "Artwork data should not be empty")
            }
        } catch {
            // May throw invalid image data error
            if case ArtworkExtractorError.invalidImageData = error {
                // Expected error
            } else if case ArtworkExtractorError.extractionFailed = error {
                // Also acceptable
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
