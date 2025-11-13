//
//  ArtworkExtractorTestBase.swift
//  MetadataEngineTests
//
//  Base class for ArtworkExtractor tests with shared setup and helper methods
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// Base class for ArtworkExtractor tests
/// Provides shared setup, teardown, and helper methods
@MainActor
class ArtworkExtractorTestBase: XCTestCase {
    
    var extractor: ArtworkExtractor!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        extractor = ArtworkExtractor()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        extractor = nil
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createMockJPEGData() -> Data {
        // Minimal valid JPEG header
        var jpegData = Data()
        jpegData.append(contentsOf: [0xFF, 0xD8, 0xFF, 0xE0]) // JPEG SOI + APP0
        jpegData.append(contentsOf: [0x00, 0x10]) // Length
        jpegData.append(Data("JFIF\0".utf8))
        jpegData.append(contentsOf: [0xFF, 0xD9]) // JPEG EOI
        return jpegData
    }
    
    func createMockPNGData() -> Data {
        // Minimal valid PNG header
        var pngData = Data()
        pngData.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG signature
        pngData.append(contentsOf: [0x00, 0x00, 0x00, 0x0D]) // IHDR chunk length
        pngData.append(Data("IHDR".utf8))
        pngData.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // Width: 1
        pngData.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // Height: 1
        pngData.append(contentsOf: [0x08, 0x02, 0x00, 0x00, 0x00]) // Bit depth, color type, etc.
        pngData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // CRC placeholder
        return pngData
    }
    
    func createMockTinyJPEGData() -> Data {
        // Even smaller JPEG (1x1 pixel)
        createMockJPEGData() // Reuse for now
    }
    
    func createMockMP3FileWithArtwork(
        artworkData: Data,
        description: String = "Cover",
        mimeType: String = "image/jpeg"
    ) throws -> URL {
        // Create minimal MP3 file with ID3v2 tag containing APIC frame
        // Use unique filename based on MIME type to avoid conflicts
        let mimeTypeSuffix = mimeType.replacingOccurrences(of: "/", with: "_")
        let fileURL = tempDirectory.appendingPathComponent("test_artwork_\(mimeTypeSuffix).mp3")
        
        var mp3Data = Data()
        
        // ID3v2 header
        mp3Data.append(Data("ID3".utf8)) // ID3 identifier
        mp3Data.append(contentsOf: [0x03, 0x00]) // Version 3.0
        mp3Data.append(contentsOf: [0x00]) // Flags
        
        // Calculate tag size (synchsafe integer)
        let apicFrameSize = 10 + calculateAPICFrameSize(
            artworkData: artworkData,
            description: description,
            mimeType: mimeType
        )
        let tagSize = 10 + apicFrameSize // Header + APIC frame
        let synchsafeSize = toSynchsafeInteger(tagSize)
        mp3Data.append(contentsOf: synchsafeSize)
        
        // APIC frame header
        mp3Data.append(Data("APIC".utf8)) // Frame ID
        let frameSizeSynchsafe = toSynchsafeInteger(apicFrameSize - 10)
        mp3Data.append(contentsOf: frameSizeSynchsafe)
        mp3Data.append(contentsOf: [0x00, 0x00]) // Flags
        
        // APIC frame content
        mp3Data.append(contentsOf: [0x00]) // Text encoding (ISO-8859-1)
        mp3Data.append(Data("\(mimeType)\0".utf8)) // MIME type (supports JPEG, PNG, GIF, etc.)
        mp3Data.append(contentsOf: [0x03]) // Picture type (Cover)
        mp3Data.append(Data("\(description)\0".utf8)) // Description
        mp3Data.append(artworkData) // Image data
        
        // Add some MP3 frame data (minimal)
        mp3Data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00]) // MP3 sync word
        
        try mp3Data.write(to: fileURL)
        return fileURL
    }
    
    func createMockMP3FileWithoutArtwork() throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("test_no_artwork.mp3")
        var mp3Data = Data()
        
        // ID3v2 header (empty tag)
        mp3Data.append(Data("ID3".utf8))
        mp3Data.append(contentsOf: [0x03, 0x00, 0x00])
        mp3Data.append(contentsOf: toSynchsafeInteger(0))
        
        // MP3 frame
        mp3Data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00])
        
        try mp3Data.write(to: fileURL)
        return fileURL
    }
    
    func createMockMP3FileWithInvalidArtwork(artworkData: Data) throws -> URL {
        // Similar to createMockMP3FileWithArtwork but with invalid image data
        try createMockMP3FileWithArtwork(artworkData: artworkData)
    }
    
    func createMockMP3FileWithMultipleArtwork(artwork1: Data, artwork2: Data) throws -> URL {
        // Create MP3 with two APIC frames (different formats)
        let fileURL = tempDirectory.appendingPathComponent("test_multiple_artwork.mp3")
        var mp3Data = Data()
        
        // ID3v2 header
        mp3Data.append(Data("ID3".utf8))
        mp3Data.append(contentsOf: [0x03, 0x00, 0x00])
        
        let frame1Size = 10 + calculateAPICFrameSize(
            artworkData: artwork1,
            description: "Cover 1",
            mimeType: "image/jpeg"
        )
        let frame2Size = 10 + calculateAPICFrameSize(
            artworkData: artwork2,
            description: "Cover 2",
            mimeType: "image/png"
        )
        let tagSize = 10 + frame1Size + frame2Size
        mp3Data.append(contentsOf: toSynchsafeInteger(tagSize))
        
        // First APIC frame (JPEG)
        mp3Data.append(Data("APIC".utf8))
        mp3Data.append(contentsOf: toSynchsafeInteger(frame1Size - 10))
        mp3Data.append(contentsOf: [0x00, 0x00])
        mp3Data.append(contentsOf: [0x00])
        mp3Data.append(Data("image/jpeg\0".utf8))
        mp3Data.append(contentsOf: [0x03])
        mp3Data.append(Data("Cover 1\0".utf8))
        mp3Data.append(artwork1)
        
        // Second APIC frame (PNG)
        mp3Data.append(Data("APIC".utf8))
        mp3Data.append(contentsOf: toSynchsafeInteger(frame2Size - 10))
        mp3Data.append(contentsOf: [0x00, 0x00])
        mp3Data.append(contentsOf: [0x00])
        mp3Data.append(Data("image/png\0".utf8))
        mp3Data.append(contentsOf: [0x03])
        mp3Data.append(Data("Cover 2\0".utf8))
        mp3Data.append(artwork2)
        
        // MP3 frame
        mp3Data.append(contentsOf: [0xFF, 0xFB, 0x90, 0x00])
        
        try mp3Data.write(to: fileURL)
        return fileURL
    }
    
    func createMockMP4FileWithArtwork(artworkData: Data) throws -> URL {
        // MP4/M4A file structure is complex, simplified version
        let fileURL = tempDirectory.appendingPathComponent("test_artwork.m4a")
        // For now, create a placeholder - full implementation would require proper MP4 atom structure
        try artworkData.write(to: fileURL)
        return fileURL
    }
    
    func createMockFLACFileWithArtwork(artworkData: Data) throws -> URL {
        // FLAC file structure with Vorbis Comments and METADATA_BLOCK_PICTURE
        let fileURL = tempDirectory.appendingPathComponent("test_artwork.flac")
        // For now, create a placeholder - full implementation would require proper FLAC structure
        try artworkData.write(to: fileURL)
        return fileURL
    }
    
    func calculateAPICFrameSize(
        artworkData: Data,
        description: String,
        mimeType: String = "image/jpeg"
    ) -> Int {
        1 + // Text encoding
        "\(mimeType)\0".utf8.count + // MIME type (supports JPEG, PNG, GIF, BMP, etc.)
        1 + // Picture type
        description.utf8.count + 1 + // Description (null-terminated)
        artworkData.count // Image data
    }
    
    func toSynchsafeInteger(_ value: Int) -> [UInt8] {
        // Convert to synchsafe integer (7 bits per byte)
        var result: [UInt8] = []
        var remaining = value
        for _ in 0..<4 {
            result.insert(UInt8(remaining & 0x7F), at: 0)
            remaining >>= 7
        }
        return result
    }
}
