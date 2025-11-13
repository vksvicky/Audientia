//
//  MetadataNormalizerBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for metadata normalization
//  Following user-centric scenarios
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for MetadataNormalizer
/// Following user-centric "As a user, I want to..." format
@MainActor
final class MetadataNormalizerBDDTests: XCTestCase {
    
    var normalizer: MetadataNormalizer!
    
    override func setUp() async throws {
        try await super.setUp()
        normalizer = MetadataNormalizer()
    }
    
    override func tearDown() async throws {
        normalizer = nil
        try await super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    /// Scenario: As a user, I want my library metadata to be consistently formatted
    func testNormalizeLibraryMetadata() {
        // Given - Track with inconsistent metadata formatting
        let track = Track(
            title: "  Here Comes the Sun  ",
            artist: "  The Beatles  ",
            album: "  Abbey Road  ",
            duration: 185.0,
            filePath: "/music/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            genre: "  Rock  "
        )
        
        // When - Normalize track metadata
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - Metadata should be consistently formatted
        XCTAssertEqual(normalized.title, "Here Comes the Sun", "Title should be trimmed")
        XCTAssertEqual(normalized.artist, "The Beatles", "Artist should be trimmed")
        XCTAssertEqual(normalized.album, "Abbey Road", "Album should be trimmed")
        XCTAssertEqual(normalized.genre, "Rock", "Genre should be trimmed")
    }
    
    /// Scenario: As a user, I want multiple spaces in metadata to be collapsed
    func testCollapseMultipleSpacesInMetadata() {
        // Given - Track with multiple spaces
        let track = Track(
            title: "Here  Comes  the  Sun",
            artist: "The  Beatles",
            album: "Abbey  Road",
            duration: 185.0,
            filePath: "/music/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        // When - Normalize track metadata
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - Multiple spaces should be collapsed
        XCTAssertEqual(normalized.title, "Here Comes the Sun", "Multiple spaces should be collapsed in title")
        XCTAssertEqual(normalized.artist, "The Beatles", "Multiple spaces should be collapsed in artist")
        XCTAssertEqual(normalized.album, "Abbey Road", "Multiple spaces should be collapsed in album")
    }
    
    /// Scenario: As a user, I want empty metadata fields to be handled gracefully
    func testHandleEmptyMetadataFields() {
        // Given - Track with empty optional fields
        let track = Track(
            title: "Title",
            artist: "Artist",
            album: "Album",
            duration: 185.0,
            filePath: "/music/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            genre: nil
        )
        
        // When - Normalize track metadata
        let normalized = normalizer.normalizeTrack(track)
        
        // Then - Empty fields should remain nil
        XCTAssertNil(normalized.genre, "Nil genre should remain nil")
    }
}
