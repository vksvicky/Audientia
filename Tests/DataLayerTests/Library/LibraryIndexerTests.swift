//
//  LibraryIndexerTests.swift
//  DataLayerTests
//
//  TDD tests for library indexing functionality
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// TDD tests for LibraryIndexer
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class LibraryIndexerTests: XCTestCase {
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that tracks are indexed correctly
    func testTracksAreIndexedCorrectly() async throws {
        // Given - A set of tracks to index
        let tracks = [
            createTrack(title: "Song 1", artist: "Artist A", album: "Album 1"),
            createTrack(title: "Song 2", artist: "Artist B", album: "Album 2"),
            createTrack(title: "Song 3", artist: "Artist A", album: "Album 1")
        ]
        
        let indexer = LibraryIndexer()
        
        // When - Index the tracks
        try await indexer.index(tracks: tracks)
        
        // Then - All tracks should be indexed
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 3, "Should index all 3 tracks")
    }
    
    /// Test that duplicate tracks are handled correctly
    func testDuplicateTracksAreHandledCorrectly() async throws {
        // Given - Tracks with duplicate file paths
        let track1 = createTrack(title: "Song 1", artist: "Artist A", filePath: "/path/to/song1.mp3")
        let track2 = createTrack(title: "Song 2", artist: "Artist B", filePath: "/path/to/song1.mp3") // Same path
        
        let indexer = LibraryIndexer()
        
        // When - Index both tracks
        try await indexer.index(tracks: [track1, track2])
        
        // Then - Should handle duplicates (either replace or skip)
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1, "Should only index one track with duplicate path")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test indexing empty track list
    func testIndexingEmptyTrackList() async throws {
        // Given - Empty track list
        let tracks: [Track] = []
        let indexer = LibraryIndexer()
        
        // When - Index empty list
        try await indexer.index(tracks: tracks)
        
        // Then - Index should be empty
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 0, "Should have zero indexed tracks")
    }
    
    /// Test indexing single track
    func testIndexingSingleTrack() async throws {
        // Given - Single track
        let track = createTrack(title: "Single Song", artist: "Artist", album: "Album")
        let indexer = LibraryIndexer()
        
        // When - Index single track
        try await indexer.index(tracks: [track])
        
        // Then - Should be indexed
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1, "Should index the single track")
    }
    
    /// Test indexing large number of tracks
    func testIndexingLargeNumberOfTracks() async throws {
        // Given - Large number of tracks (1000)
        let tracks = (1...1000).map { index in
            createTrack(title: "Song \(index)", artist: "Artist \(index % 100)", album: "Album \(index % 50)")
        }
        let indexer = LibraryIndexer()
        
        // When - Index all tracks
        let startTime = Date()
        try await indexer.index(tracks: tracks)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - All should be indexed within reasonable time
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1000, "Should index all 1000 tracks")
        XCTAssertLessThan(duration, 5.0, "Should index 1000 tracks in less than 5 seconds")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that removing tracks from index works correctly
    func testRemovingTracksFromIndex() async throws {
        // Given - Indexed tracks
        let track1 = createTrack(title: "Song 1", artist: "Artist A")
        let track2 = createTrack(title: "Song 2", artist: "Artist B")
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: [track1, track2])
        
        // When - Remove a track
        try await indexer.remove(track: track1)
        
        // Then - Only remaining track should be in index
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1, "Should have one track remaining")
        
        let remainingTrack = await indexer.getTrack(by: track2.id)
        XCTAssertNotNil(remainingTrack, "Remaining track should still be in index")
        
        let removedTrack = await indexer.getTrack(by: track1.id)
        XCTAssertNil(removedTrack, "Removed track should not be in index")
    }
    
    /// Test that clearing index removes all tracks
    func testClearingIndexRemovesAllTracks() async throws {
        // Given - Indexed tracks
        let tracks = (1...10).map { createTrack(title: "Song \($0)", artist: "Artist") }
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        
        // When - Clear index
        try await indexer.clear()
        
        // Then - Index should be empty
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 0, "Index should be empty after clearing")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that indexed tracks can be retrieved by ID
    func testIndexedTracksCanBeRetrievedById() async throws {
        // Given - Indexed tracks
        let track1 = createTrack(title: "Song 1", artist: "Artist A")
        let track2 = createTrack(title: "Song 2", artist: "Artist B")
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: [track1, track2])
        
        // When - Retrieve by ID
        let retrieved1 = await indexer.getTrack(by: track1.id)
        let retrieved2 = await indexer.getTrack(by: track2.id)
        
        // Then - Should retrieve correct tracks
        XCTAssertNotNil(retrieved1, "Should retrieve track 1")
        XCTAssertEqual(retrieved1?.title, "Song 1", "Retrieved track should have correct title")
        XCTAssertNotNil(retrieved2, "Should retrieve track 2")
        XCTAssertEqual(retrieved2?.title, "Song 2", "Retrieved track should have correct title")
    }
    
    // MARK: - Error Conditions
    
    /// Test that indexing invalid tracks is handled gracefully
    func testIndexingInvalidTracksIsHandledGracefully() async throws {
        // Given - Track with invalid data (empty file path)
        let invalidTrack = Track(
            id: UUID(),
            title: "Invalid",
            artist: "Artist",
            album: "Album",
            duration: 0.0,
            filePath: "", // Invalid: empty path
            fileSize: 0,
            bitrate: 0,
            sampleRate: 0,
            year: nil,
            trackNumber: nil,
            discNumber: nil
        )
        let indexer = LibraryIndexer()
        
        // When - Index invalid track
        // Then - Should handle gracefully (either skip or index with validation)
        do {
            try await indexer.index(tracks: [invalidTrack])
            // If indexing succeeds, verify it was handled
            let count = await indexer.getIndexedTrackCount()
            XCTAssertLessThanOrEqual(count, 1, "Should handle invalid track gracefully")
        } catch {
            // If indexing fails, that's also acceptable
            XCTAssertTrue(error is LibraryIndexerError, "Should throw LibraryIndexerError for invalid track")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that indexing is performant
    func testIndexingIsPerformant() async throws {
        // Given - Moderate number of tracks (100)
        let tracks = (1...100).map { createTrack(title: "Song \($0)", artist: "Artist") }
        let indexer = LibraryIndexer()
        
        // When - Index tracks
        let startTime = Date()
        try await indexer.index(tracks: tracks)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete quickly
        XCTAssertLessThan(duration, 1.0, "Should index 100 tracks in less than 1 second")
    }
    
    // MARK: - Edge Cases
    
    /// Test indexing tracks with special characters in metadata
    func testIndexingTracksWithSpecialCharacters() async throws {
        // Given - Track with special characters
        let track = createTrack(
            title: "Song with émojis 🎵 & symbols!",
            artist: "Artist with ünicode",
            album: "Album (2024)"
        )
        let indexer = LibraryIndexer()
        
        // When - Index track
        try await indexer.index(tracks: [track])
        
        // Then - Should be indexed correctly
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1, "Should index track with special characters")
        
        let retrieved = await indexer.getTrack(by: track.id)
        XCTAssertEqual(retrieved?.title, "Song with émojis 🎵 & symbols!", "Special characters should be preserved")
    }
    
    /// Test indexing tracks with very long metadata
    func testIndexingTracksWithVeryLongMetadata() async throws {
        // Given - Track with very long title
        let longTitle = String(repeating: "A", count: 1000)
        let track = createTrack(title: longTitle, artist: "Artist", album: "Album")
        let indexer = LibraryIndexer()
        
        // When - Index track
        try await indexer.index(tracks: [track])
        
        // Then - Should be indexed correctly
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1, "Should index track with very long metadata")
        
        let retrieved = await indexer.getTrack(by: track.id)
        XCTAssertEqual(retrieved?.title, longTitle, "Long metadata should be preserved")
    }
    
    // MARK: - Helper Methods
    
    private func createTrack(
        title: String,
        artist: String,
        album: String = "Unknown Album",
        filePath: String? = nil
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: filePath ?? "/path/to/\(title.replacingOccurrences(of: " ", with: "_")).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1
        )
    }
}
