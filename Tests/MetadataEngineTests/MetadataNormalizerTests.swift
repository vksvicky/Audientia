//
//  MetadataNormalizerTests.swift
//  MetadataEngineTests
//
//  TDD tests for metadata normalization
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for MetadataNormalizer
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class MetadataNormalizerTests: XCTestCase {
    
    var normalizer: MetadataNormalizer!
    
    override func setUp() async throws {
        try await super.setUp()
        normalizer = MetadataNormalizer()
    }
    
    override func tearDown() async throws {
        normalizer = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that artist names are normalized correctly
    func testNormalizeArtistName() {
        // Given - Artist name with extra whitespace
        let artist = "  The Beatles  "
        
        // When - Normalize
        let normalized = normalizer.normalizeArtist(artist)
        
        // Then - Should trim whitespace
        XCTAssertEqual(normalized, "The Beatles", "Should trim whitespace from artist name")
    }
    
    /// Test that album names are normalized correctly
    func testNormalizeAlbumName() {
        // Given - Album name with extra whitespace
        let album = "  Abbey Road  "
        
        // When - Normalize
        let normalized = normalizer.normalizeAlbum(album)
        
        // Then - Should trim whitespace
        XCTAssertEqual(normalized, "Abbey Road", "Should trim whitespace from album name")
    }
    
    /// Test that track titles are normalized correctly
    func testNormalizeTrackTitle() {
        // Given - Track title with extra whitespace
        let title = "  Here Comes the Sun  "
        
        // When - Normalize
        let normalized = normalizer.normalizeTitle(title)
        
        // Then - Should trim whitespace
        XCTAssertEqual(normalized, "Here Comes the Sun", "Should trim whitespace from track title")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test normalizing empty strings
    func testNormalizeEmptyString() {
        // Given - Empty string
        let empty = ""
        
        // When - Normalize
        let normalized = normalizer.normalizeArtist(empty)
        
        // Then - Should return empty string
        XCTAssertEqual(normalized, "", "Should return empty string for empty input")
    }
    
    /// Test normalizing strings with only whitespace
    func testNormalizeWhitespaceOnly() {
        // Given - String with only whitespace
        let whitespace = "   \n\t  "
        
        // When - Normalize
        let normalized = normalizer.normalizeArtist(whitespace)
        
        // Then - Should return empty string
        XCTAssertEqual(normalized, "", "Should return empty string for whitespace-only input")
    }
    
    /// Test normalizing strings with multiple spaces
    func testNormalizeMultipleSpaces() {
        // Given - String with multiple spaces
        let multiSpace = "The  Beatles"
        
        // When - Normalize
        let normalized = normalizer.normalizeArtist(multiSpace)
        
        // Then - Should collapse multiple spaces
        XCTAssertEqual(normalized, "The Beatles", "Should collapse multiple spaces")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that normalization is idempotent
    func testNormalizationIsIdempotent() {
        // Given - Already normalized string
        let normalized = "The Beatles"
        
        // When - Normalize twice
        let once = normalizer.normalizeArtist(normalized)
        let twice = normalizer.normalizeArtist(once)
        
        // Then - Should remain the same
        XCTAssertEqual(once, twice, "Normalization should be idempotent")
        XCTAssertEqual(once, normalized, "Normalized string should remain unchanged")
    }
    
    // MARK: - Error Conditions
    
    /// Test normalizing nil values
    func testNormalizeNilValue() {
        // Given - Nil string
        let nilString: String? = nil
        
        // When - Normalize
        let normalized = normalizer.normalizeArtist(nilString)
        
        // Then - Should return nil
        XCTAssertNil(normalized, "Should return nil for nil input")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that normalization is fast
    func testNormalizationPerformance() {
        // Given - Long string
        let longString = String(repeating: "  The Beatles  ", count: 1000)
        
        // When - Measure normalization time
        measure {
            _ = normalizer.normalizeArtist(longString)
        }
    }
}
