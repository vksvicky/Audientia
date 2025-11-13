//
//  ArtworkExtractorTests.swift
//  MetadataEngineTests
//
//  TDD tests for artwork extraction
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
import XCTest

/// TDD tests for ArtworkExtractor
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class ArtworkExtractorTests: XCTestCase {
    
    var extractor: ArtworkExtractor!
    
    override func setUp() async throws {
        try await super.setUp()
        extractor = ArtworkExtractor()
    }
    
    override func tearDown() async throws {
        extractor = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that artwork can be extracted from MP3 file with embedded artwork
    func testExtractArtworkFromMP3WithEmbeddedArtwork() async throws {
        // Given - MP3 file with embedded artwork
        let tempFile = createTempMP3FileWithArtwork()
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // When - Extract artwork
        let artwork = try await extractor.extractArtwork(from: tempFile)
        
        // Then - Should return artwork data
        guard let artwork = artwork else {
            XCTFail("Should extract artwork from MP3 file")
            return
        }
        XCTAssertFalse(artwork.data.isEmpty, "Artwork data should not be empty")
        XCTAssertTrue(artwork.mimeType.hasPrefix("image/"), "MIME type should be an image type")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test extracting artwork from file with no artwork
    func testExtractArtworkFromFileWithNoArtwork() async throws {
        // Given - File with no embedded artwork (create a minimal MP3 file without artwork)
        let tempFile = createTempMP3FileWithoutArtwork()
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // When - Extract artwork
        let artwork = try await extractor.extractArtwork(from: tempFile)
        
        // Then - Should return nil
        XCTAssertNil(artwork, "Should return nil for file with no artwork")
    }
    
    /// Test extracting artwork from non-existent file
    func testExtractArtworkFromNonExistentFile() async {
        // Given - Non-existent file
        let fileURL = URL(fileURLWithPath: "/nonexistent/song.mp3")
        
        // When/Then - Should throw error
        do {
            _ = try await extractor.extractArtwork(from: fileURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            XCTAssertTrue(error is ArtworkExtractorError || error is CocoaError, "Should throw appropriate error")
        }
    }
    
    // MARK: - Error Conditions
    
    /// Test extracting artwork from unsupported file format
    func testExtractArtworkFromUnsupportedFormat() async {
        // Given - Unsupported file format
        let fileURL = URL(fileURLWithPath: "/test/song.txt")
        
        // When/Then - Should throw error
        do {
            _ = try await extractor.extractArtwork(from: fileURL)
            XCTFail("Should throw error for unsupported format")
        } catch {
            XCTAssertTrue(error is ArtworkExtractorError, "Should throw ArtworkExtractorError")
        }
    }
    
    /// Test extracting artwork from corrupted file
    func testExtractArtworkFromCorruptedFile() async {
        // Given - Corrupted MP3 file (invalid ID3v2 header)
        let tempFile = createCorruptedMP3File()
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // When/Then - Should handle gracefully (either return nil or throw appropriate error)
        do {
            let artwork = try await extractor.extractArtwork(from: tempFile)
            // If it returns nil, that's acceptable for corrupted files
            // If it throws, we'll catch it below
            if artwork == nil {
                // This is acceptable - corrupted file with no artwork
                return
            }
        } catch {
            // Throwing an error is also acceptable for corrupted files
            XCTAssertTrue(
                error is ArtworkExtractorError || error is CocoaError,
                "Should throw appropriate error for corrupted file: \(error)"
            )
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that artwork extraction completes quickly
    func testArtworkExtractionPerformance() async throws {
        // Given - File with artwork
        let tempFile = createTempMP3FileWithArtwork()
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // When - Measure extraction time (run multiple times)
        let iterations = 10
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            _ = try await extractor.extractArtwork(from: tempFile)
        }
        
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = elapsedTime / Double(iterations)
        
        // Then - Extraction should complete quickly (< 100ms per extraction)
        XCTAssertLessThan(averageTime, 0.1, "Artwork extraction should complete in < 100ms on average")
        
        // Verify extraction works
        let artwork = try await extractor.extractArtwork(from: tempFile)
        XCTAssertNotNil(artwork, "Should extract artwork for performance test")
    }
    
    // MARK: - Helper Methods
    
    /// Create a temporary MP3 file without artwork (minimal ID3v2 tag with no APIC frame)
    private func createTempMP3FileWithoutArtwork() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp3")
        
        var mp3Data = Data()
        
        // ID3v2.3 header (10 bytes) - minimal tag with no frames
        mp3Data.append(Data("ID3".utf8)) // Magic (3 bytes)
        mp3Data.append(0x03) // Version (1 byte) - ID3v2.3
        mp3Data.append(0x00) // Revision (1 byte)
        mp3Data.append(0x00) // Flags (1 byte)
        
        // Tag size: 0 (synchsafe integer, 4 bytes)
        mp3Data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        // Add minimal MP3 frame header to make it look like a valid MP3
        mp3Data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00]) // MP3 sync word + header
        
        FileManager.default.createFile(atPath: fileURL.path, contents: mp3Data)
        return fileURL
    }
    
    /// Create a temporary MP3 file with embedded artwork (ID3v2 APIC frame)
    private func createTempMP3FileWithArtwork() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp3")
        
        var mp3Data = Data()
        
        // Create a minimal 1x1 pixel PNG image (smallest valid PNG)
        // PNG signature + minimal IHDR + IEND chunks
        let pngImageData = createMinimalPNGImage()
        
        // Build APIC frame
        var apicFrameData = Data()
        apicFrameData.append(0x03) // Text encoding: UTF-8
        apicFrameData.append(Data("image/png".utf8)) // MIME type
        apicFrameData.append(0x00) // Null terminator for MIME type
        apicFrameData.append(0x03) // Picture type: Cover (front)
        apicFrameData.append(Data("Cover".utf8)) // Description
        apicFrameData.append(0x00) // Null terminator for description
        apicFrameData.append(pngImageData) // Image data
        
        // Calculate APIC frame size (synchsafe integer)
        let apicFrameSize = apicFrameData.count
        let apicFrameSizeBytes = [
            UInt8((apicFrameSize >> 21) & 0x7F),
            UInt8((apicFrameSize >> 14) & 0x7F),
            UInt8((apicFrameSize >> 7) & 0x7F),
            UInt8(apicFrameSize & 0x7F)
        ]
        
        // Calculate total tag size (APIC frame header + frame data)
        let tagSize = 10 + apicFrameData.count // 10 bytes for frame header + frame data
        let tagSizeBytes = [
            UInt8((tagSize >> 21) & 0x7F),
            UInt8((tagSize >> 14) & 0x7F),
            UInt8((tagSize >> 7) & 0x7F),
            UInt8(tagSize & 0x7F)
        ]
        
        // ID3v2.3 header
        mp3Data.append(Data("ID3".utf8)) // Magic (3 bytes)
        mp3Data.append(0x03) // Version (1 byte) - ID3v2.3
        mp3Data.append(0x00) // Revision (1 byte)
        mp3Data.append(0x00) // Flags (1 byte)
        mp3Data.append(contentsOf: tagSizeBytes) // Tag size (4 bytes, synchsafe)
        
        // APIC frame header
        mp3Data.append(Data("APIC".utf8)) // Frame ID (4 bytes)
        mp3Data.append(contentsOf: apicFrameSizeBytes) // Frame size (4 bytes, synchsafe)
        mp3Data.append(contentsOf: [0x00, 0x00]) // Flags (2 bytes)
        
        // APIC frame data
        mp3Data.append(apicFrameData)
        
        // Add minimal MP3 frame header
        mp3Data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00]) // MP3 sync word + header
        
        FileManager.default.createFile(atPath: fileURL.path, contents: mp3Data)
        return fileURL
    }
    
    /// Create a minimal valid PNG image (1x1 pixel, transparent)
    private func createMinimalPNGImage() -> Data {
        var pngData = Data()
        
        // PNG signature (8 bytes)
        pngData.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        
        // IHDR chunk (13 bytes data + 4 bytes length + 4 bytes type + 4 bytes CRC)
        let ihdrData = Data([
            0x00, 0x00, 0x00, 0x01, // Width: 1
            0x00, 0x00, 0x00, 0x01, // Height: 1
            0x08, // Bit depth: 8
            0x06, // Color type: RGBA
            0x00, // Compression: deflate
            0x00, // Filter: none
            0x00  // Interlace: none
        ])
        let ihdrLength: UInt32 = 13
        pngData.append(contentsOf: withUnsafeBytes(of: ihdrLength.bigEndian) { Data($0) })
        pngData.append(Data("IHDR".utf8))
        pngData.append(ihdrData)
        // Simple CRC (for testing, we'll use a placeholder)
        pngData.append(contentsOf: [0x12, 0x34, 0x56, 0x78]) // Placeholder CRC
        
        // IDAT chunk (minimal compressed data for 1x1 RGBA pixel)
        let idatData = Data([0x78, 0x9C, 0x63, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01]) // Minimal zlib data
        let idatLength: UInt32 = UInt32(idatData.count)
        pngData.append(contentsOf: withUnsafeBytes(of: idatLength.bigEndian) { Data($0) })
        pngData.append(Data("IDAT".utf8))
        pngData.append(idatData)
        pngData.append(contentsOf: [0x12, 0x34, 0x56, 0x78]) // Placeholder CRC
        
        // IEND chunk (0 bytes data)
        pngData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Length: 0
        pngData.append(Data("IEND".utf8))
        pngData.append(contentsOf: [0xAE, 0x42, 0x60, 0x82]) // IEND CRC
        
        return pngData
    }
    
    /// Create a corrupted MP3 file (invalid ID3v2 header)
    private func createCorruptedMP3File() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp3")
        
        var mp3Data = Data()
        
        // Corrupted ID3v2 header (invalid magic)
        mp3Data.append(Data("XXX".utf8)) // Invalid magic (should be "ID3")
        mp3Data.append(0x03) // Version
        mp3Data.append(0x00) // Revision
        mp3Data.append(0x00) // Flags
        mp3Data.append(contentsOf: [0x00, 0x00, 0x00, 0x10]) // Tag size
        
        // Add some random data
        mp3Data.append(contentsOf: Data(repeating: 0xFF, count: 16))
        
        FileManager.default.createFile(atPath: fileURL.path, contents: mp3Data)
        return fileURL
    }
}
