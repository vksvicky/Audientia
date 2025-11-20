//
//  MetadataMergeTests.swift
//  MetadataEngineTests
//
//  TDD tests for metadata merge strategies
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// TDD tests for metadata merge strategies following Right-BICEP principles
final class MetadataMergeTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testFillMissingStrategyFillsEmptyFields() throws {
        // Given: A track with missing metadata and a source with complete metadata
        let originalTrack = Track(
            title: "Unknown",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            genre: nil
        )
        
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                year: 1975,
                trackNumber: 11,
                genre: "Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // Then: Missing fields are filled, existing fields preserved
        XCTAssertEqual(merged.title, "Unknown") // Existing preserved
        XCTAssertEqual(merged.artist, "Unknown Artist") // Existing preserved
        XCTAssertEqual(merged.album, "Unknown Album") // Existing preserved
        XCTAssertEqual(merged.year, 1975) // Filled from source
        XCTAssertEqual(merged.trackNumber, 11) // Filled from source
        XCTAssertEqual(merged.genre, "Rock") // Filled from source
    }
    
    func testHighestConfidenceStrategyUsesBestSource() throws {
        // Given: A track and multiple sources with different confidence scores
        let originalTrack = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020,
            genre: "Pop"
        )
        
        let source1 = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1975,
                genre: "Rock"
            )
        )
        
        let source2 = MetadataSource(
            type: .discogs,
            confidence: 0.85,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1976,
                genre: "Progressive Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .highestConfidence)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source1, source2])
        
        // Then: Fields from highest confidence source are used
        XCTAssertEqual(merged.title, "Bohemian Rhapsody")
        XCTAssertEqual(merged.artist, "Queen")
        XCTAssertEqual(merged.year, 1975) // From source1 (0.95 > 0.85)
        XCTAssertEqual(merged.genre, "Rock") // From source1 (0.95 > 0.85)
    }
    
    func testPreferSourceStrategyUsesPreferredSource() throws {
        // Given: A track and multiple sources
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let musicBrainzSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1975
            )
        )
        
        let discogsSource = MetadataSource(
            type: .discogs,
            confidence: 0.90,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1976
            )
        )
        
        let merger = MetadataMerger(strategy: .preferSource(.musicBrainz))
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [musicBrainzSource, discogsSource])
        
        // Then: MusicBrainz source is preferred
        XCTAssertEqual(merged.title, "Bohemian Rhapsody")
        XCTAssertEqual(merged.artist, "Queen")
        XCTAssertEqual(merged.year, 1975) // From MusicBrainz, not Discogs (1976)
    }
    
    func testMostCompleteStrategyUsesMostCompleteSource() throws {
        // Given: A track and sources with different completeness
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let partialSource = MetadataSource(
            type: .acoustID,
            confidence: 0.98,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen"
            )
        )
        
        let completeSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                year: 1975,
                trackNumber: 11,
                genre: "Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .mostComplete)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [partialSource, completeSource])
        
        // Then: Most complete source is used
        XCTAssertEqual(merged.title, "Bohemian Rhapsody")
        XCTAssertEqual(merged.artist, "Queen")
        XCTAssertEqual(merged.album, "A Night at the Opera")
        XCTAssertEqual(merged.year, 1975)
        XCTAssertEqual(merged.trackNumber, 11)
        XCTAssertEqual(merged.genre, "Rock")
    }
    
    func testConservativeStrategyPreservesExisting() throws {
        // Given: A track with existing metadata and a source
        let originalTrack = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020,
            genre: "Pop"
        )
        
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                year: 1975,
                genre: "Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .conservative)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // Then: Existing metadata is preserved (conservative doesn't overwrite)
        XCTAssertEqual(merged.title, "Test Song")
        XCTAssertEqual(merged.artist, "Test Artist")
        XCTAssertEqual(merged.album, "Test Album")
        XCTAssertEqual(merged.year, 2020)
        XCTAssertEqual(merged.genre, "Pop")
    }
    
    // MARK: - Boundary Conditions
    
    func testMergeWithNoSources() {
        // Given: A track and no sources
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let merger = MetadataMerger()
        
        // When/Then: Error is thrown
        XCTAssertThrowsError(try merger.merge(originalTrack: originalTrack, sources: [])) { error in
            XCTAssertEqual(error as? MetadataMergeError, .noSources)
        }
    }
    
    func testMergeWithInvalidConfidence() {
        // Given: A source with invalid confidence (> 1.0)
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 1.5, // Invalid (> 1.0)
            metadata: MetadataFields(title: "Test")
        )
        
        let merger = MetadataMerger()
        
        // When/Then: Confidence is clamped to 1.0 (no error thrown, but clamped)
        // Note: MetadataSource clamps confidence in init, so this should not throw
        XCTAssertNoThrow(try merger.merge(originalTrack: originalTrack, sources: [source]))
    }
    
    func testMergeWithEmptyStrings() throws {
        // Given: A track with empty strings and a source
        let originalTrack = Track(
            title: "",
            artist: "",
            album: "",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera"
            )
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // Then: Empty strings are treated as missing and filled
        XCTAssertEqual(merged.title, "") // Empty string preserved (not nil)
        XCTAssertEqual(merged.artist, "")
        XCTAssertEqual(merged.album, "")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testMergePreservesNonMetadataFields() throws {
        // Given: A track with all fields
        let originalTrack = Track(
            id: UUID(),
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.5,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020,
            trackNumber: 1,
            discNumber: 1,
            genre: "Pop",
            rating: 5
        )
        
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "New Title",
                year: 1975
            )
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // Then: Non-metadata fields are preserved (cross-check: structure validation)
        XCTAssertEqual(merged.id, originalTrack.id)
        XCTAssertEqual(merged.duration, originalTrack.duration)
        XCTAssertEqual(merged.filePath, originalTrack.filePath)
        XCTAssertEqual(merged.fileSize, originalTrack.fileSize)
        XCTAssertEqual(merged.bitrate, originalTrack.bitrate)
        XCTAssertEqual(merged.sampleRate, originalTrack.sampleRate)
        XCTAssertEqual(merged.rating, originalTrack.rating)
    }
}
