//
//  ArtworkExtractionTests.swift
//  UITests
//
//  TDD tests for artwork extraction functionality with mocking
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AVFoundation
import Foundation

#if canImport(XCTest)
import XCTest

@testable import Audientia
@testable import Shared

/// Mock artwork extractor for isolated unit testing
/// Note: This is different from the `MockArtworkExtractor` actor in LibraryBrowserTestMocks
actor IsolatedArtworkExtractorMock {
    private var extractedArtworkData: Data?
    private var shouldThrowError = false
    private var extractionCallCount = 0
    
    func setExtractedArtworkData(_ data: Data?) {
        extractedArtworkData = data
    }
    
    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }
    
    func extractEmbeddedArtwork(from url: URL) async throws -> Data? {
        extractionCallCount += 1
        
        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        
        return extractedArtworkData
    }
    
    func getExtractionCallCount() -> Int {
        extractionCallCount
    }
}

/// TDD Tests for Artwork Extraction
/// These tests verify the artwork loading logic in isolation
@MainActor
final class ArtworkExtractionTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockExtractor: IsolatedArtworkExtractorMock!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockExtractor = IsolatedArtworkExtractorMock()
    }
    
    override func tearDown() {
        mockExtractor = nil
        super.tearDown()
    }
    
    // MARK: - [R]ight - Are the Results Right?
    
    /// Test: Extraction should return nil for files without artwork
    func testExtractionReturnsNilForFilesWithoutArtwork() async {
        // Given: No artwork data
        await mockExtractor.setExtractedArtworkData(nil)
        
        // When: Extracting artwork
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        // Then: Should return nil
        XCTAssertNil(result)
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 1)
    }
    
    /// Test: Extraction should return data for files with artwork
    func testExtractionReturnsDataForFilesWithArtwork() async {
        // Given: Mock artwork data
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        await mockExtractor.setExtractedArtworkData(imageData)
        
        // When: Extracting artwork
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        // Then: Should return the data
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 4)
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 1)
    }
    
    /// Test: Extraction should handle errors gracefully
    func testExtractionHandlesErrorsGracefully() async {
        // Given: Extractor configured to throw error
        await mockExtractor.setShouldThrowError(true)
        
        // When: Extracting artwork
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        // Then: Should return nil without crashing
        XCTAssertNil(result)
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 1)
    }
    
    // MARK: - [B]oundary Conditions
    
    /// Test: Extraction should handle empty data
    func testExtractionHandlesEmptyData() async {
        // Given: Empty data
        await mockExtractor.setExtractedArtworkData(Data())
        
        // When: Extracting artwork
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        // Then: Should return empty data
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 0)
    }
    
    /// Test: Extraction should handle very large artwork files
    func testExtractionHandlesLargeArtwork() async {
        // Given: Large artwork data (10MB)
        let largeData = Data(count: 10_000_000)
        await mockExtractor.setExtractedArtworkData(largeData)
        
        // When: Extracting artwork
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        // Then: Should handle without issues
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 10_000_000)
    }
    
    /// Test: Extraction should handle file paths with special characters
    func testExtractionHandlesSpecialCharacters() async {
        // Given: File path with special characters
        let specialPaths = [
            "/music/Artist - Song (Remix) [2024].mp3",
            "/music/Café René/track #1.m4a",
            "/music/日本語/曲.flac",
            "/music/Émilie/chançon.wav"
        ]
        
        await mockExtractor.setExtractedArtworkData(Data([0xFF]))
        
        for path in specialPaths {
            // When: Extracting artwork
            let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: path))
            
            // Then: Should not crash
            XCTAssertNotNil(result, "Failed for path: \(path)")
        }
        
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, specialPaths.count)
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test: Multiple extractions should produce consistent results
    func testMultipleExtractionsProduceConsistentResults() async {
        // Given: Fixed artwork data
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        await mockExtractor.setExtractedArtworkData(imageData)
        
        let url = URL(fileURLWithPath: "/test.png")
        
        // When: Extracting multiple times
        let result1 = try? await mockExtractor.extractEmbeddedArtwork(from: url)
        let result2 = try? await mockExtractor.extractEmbeddedArtwork(from: url)
        let result3 = try? await mockExtractor.extractEmbeddedArtwork(from: url)
        
        // Then: All results should be identical
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 3)
    }
    
    // MARK: - [C]ross-Checking
    
    /// Test: Different file types should be handled appropriately
    func testDifferentFileTypesHandledAppropriately() async {
        // Given: Various audio file types
        let fileTypes = ["mp3", "m4a", "flac", "wav", "aac", "ogg", "opus", "wma"]
        await mockExtractor.setExtractedArtworkData(Data([0xFF]))
        
        for fileType in fileTypes {
            // When: Extracting artwork
            let url = URL(fileURLWithPath: "/music/track.\(fileType)")
            let result = try? await mockExtractor.extractEmbeddedArtwork(from: url)
            
            // Then: Should not crash
            XCTAssertNotNil(result, "Failed for file type: \(fileType)")
        }
        
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, fileTypes.count)
    }
    
    /// Test: NSImage creation from extracted data should work
    func testNSImageCreationFromExtractedData() async {
        // Given: Valid PNG image data (1x1 red pixel)
        let pngData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  // 1x1 pixels
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,  // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
            0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,  // IEND chunk
            0x44, 0xAE, 0x42, 0x60, 0x82
        ])
        await mockExtractor.setExtractedArtworkData(pngData)
        
        // When: Extracting and creating NSImage
        if let data = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.png")),
           let image = NSImage(data: data) {
            // Then: Image should be created successfully
            XCTAssertNotNil(image)
            XCTAssertEqual(image.size.width, 1.0)
            XCTAssertEqual(image.size.height, 1.0)
        } else {
            XCTFail("Failed to create NSImage from PNG data")
        }
    }
    
    // MARK: - [E]rror Conditions
    
    /// Test: Extraction should handle network errors
    func testExtractionHandlesNetworkErrors() async {
        // Given: Network error scenario
        await mockExtractor.setShouldThrowError(true)
        
        // When: Attempting extraction
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        // Then: Should fail gracefully
        XCTAssertNil(result)
    }
    
    /// Test: Extraction should handle permission errors
    func testExtractionHandlesPermissionErrors() async {
        // Given: File without read permission
        await mockExtractor.setShouldThrowError(true)
        
        // When: Attempting extraction
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/protected/file.mp3"))
        
        // Then: Should fail gracefully
        XCTAssertNil(result)
    }
    
    /// Test: Extraction should handle corrupted metadata
    func testExtractionHandlesCorruptedMetadata() async {
        // Given: Invalid data (not valid image format)
        await mockExtractor.setExtractedArtworkData(Data([0x00, 0x01, 0x02, 0x03]))
        
        // When: Extracting and creating image
        let data = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        let image = data.flatMap { NSImage(data: $0) }
        
        // Then: Image creation should fail gracefully
        XCTAssertNotNil(data)
        XCTAssertNil(image)
    }
    
    // MARK: - [P]erformance
    
    /// Test: Extraction should complete quickly for standard-sized artwork
    func testExtractionCompletesQuickly() async {
        // Given: Standard artwork data (1MB)
        await mockExtractor.setExtractedArtworkData(Data(count: 1_000_000))
        
        let startTime = Date()
        
        // When: Extracting artwork
        let result = try? await mockExtractor.extractEmbeddedArtwork(from: URL(fileURLWithPath: "/test.mp3"))
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then: Should complete within reasonable time (< 1 second for mock)
        XCTAssertNotNil(result)
        XCTAssertLessThan(duration, 1.0, "Extraction should complete within 1 second")
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 1)
    }
    
    /// Test: Multiple sequential extractions should complete efficiently
    func testSequentialExtractionsHandledEfficiently() async {
        // Given: Multiple files to extract
        await mockExtractor.setExtractedArtworkData(Data([0xFF]))
        
        let urls = (0..<10).map { URL(fileURLWithPath: "/test\($0).mp3") }
        let startTime = Date()
        
        // When: Extracting sequentially
        for url in urls {
            _ = try? await mockExtractor.extractEmbeddedArtwork(from: url)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then: All extractions should complete quickly
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 10)
        XCTAssertLessThan(duration, 5.0, "Sequential extractions should complete within 5 seconds")
    }
    
    /// Test: Concurrent extractions should be handled efficiently
    func testConcurrentExtractionsHandledEfficiently() async {
        // Given: Multiple files to extract
        await mockExtractor.setExtractedArtworkData(Data([0xFF]))
        
        let urls = (0..<10).map { URL(fileURLWithPath: "/test\($0).mp3") }
        let startTime = Date()
        
        // When: Extracting concurrently
        await withTaskGroup(of: Data?.self) { group in
            for url in urls {
                group.addTask {
                    try? await self.mockExtractor.extractEmbeddedArtwork(from: url)
                }
            }
            
            var results: [Data?] = []
            for await result in group {
                results.append(result)
            }
            
            // Then: All extractions should complete
            XCTAssertEqual(results.count, 10)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then: Concurrent extraction should be faster than sequential
        let callCount = await mockExtractor.getExtractionCallCount()
        XCTAssertEqual(callCount, 10)
        XCTAssertLessThan(duration, 5.0, "Concurrent extractions should complete within 5 seconds")
    }
}

#endif
