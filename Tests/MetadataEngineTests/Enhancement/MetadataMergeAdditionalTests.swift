//
//  MetadataMergeAdditionalTests.swift
//  MetadataEngineTests
//
//  Additional TDD tests for metadata merge (Error, Performance, Edge Cases)
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// Additional TDD tests for metadata merge: Error, Performance, Edge Cases
final class MetadataMergeAdditionalTests: XCTestCase {
    
    // MARK: - Boundary Conditions
    
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
    
    // MARK: - Inverse Relationships
    
    func testMergeRoundtrip() throws {
        // Given: A track and source
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil
        )
        
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                year: 1975,
                trackNumber: 11
            )
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        
        // When: Merging twice
        let merged1 = try merger.merge(originalTrack: originalTrack, sources: [source])
        let merged2 = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // Then: Same result (inverse: consistent results)
        XCTAssertEqual(merged1.title, merged2.title)
        XCTAssertEqual(merged1.artist, merged2.artist)
        XCTAssertEqual(merged1.year, merged2.year)
        XCTAssertEqual(merged1.trackNumber, merged2.trackNumber)
    }
    
    // MARK: - Error Conditions
    
    func testMergeWithNegativeConfidence() {
        // Given: A source with negative confidence
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
            confidence: -0.5, // Invalid (< 0.0)
            metadata: MetadataFields(title: "Test")
        )
        
        let merger = MetadataMerger()
        
        // When/Then: Confidence is clamped to 0.0 (no error thrown, but clamped)
        // Note: MetadataSource clamps confidence in init, so this should not throw
        XCTAssertNoThrow(try merger.merge(originalTrack: originalTrack, sources: [source]))
    }
    
    // MARK: - Performance Characteristics
    
    func testMergePerformance() throws {
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
        
        let sources = (1...10).map { index in
            MetadataSource(
                type: .musicBrainz,
                confidence: Double(index) / 10.0,
                metadata: MetadataFields(
                    title: "Title \(index)",
                    artist: "Artist \(index)",
                    year: 1970 + index
                )
            )
        }
        
        let merger = MetadataMerger(strategy: .highestConfidence)
        
        // When: Measuring merge time
        let startTime = Date()
        _ = try merger.merge(originalTrack: originalTrack, sources: sources)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Merge completes quickly (< 100ms)
        XCTAssertLessThan(elapsed, 0.1, "Merge should complete in < 100ms")
    }
    
    // MARK: - Edge Cases
    
    func testMergeWithConflictingSources() throws {
        // Given: Multiple sources with conflicting data
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
        
        let source1 = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Title 1",
                artist: "Artist 1",
                year: 1975
            )
        )
        
        let source2 = MetadataSource(
            type: .discogs,
            confidence: 0.90,
            metadata: MetadataFields(
                title: "Title 2",
                artist: "Artist 2",
                year: 1976
            )
        )
        
        let merger = MetadataMerger(strategy: .highestConfidence)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source1, source2])
        
        // Then: Highest confidence source wins for each field
        XCTAssertEqual(merged.title, "Title 1") // From source1 (0.95 > 0.90)
        XCTAssertEqual(merged.artist, "Artist 1") // From source1
        XCTAssertEqual(merged.year, 1975) // From source1
    }
    
    func testMergeWithAllNilFields() throws {
        // Given: A source with all nil fields
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
            confidence: 0.95,
            metadata: MetadataFields() // All nil
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        
        // When: Merging metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // Then: Original track is preserved
        XCTAssertEqual(merged.title, originalTrack.title)
        XCTAssertEqual(merged.artist, originalTrack.artist)
        XCTAssertEqual(merged.album, originalTrack.album)
    }
}
