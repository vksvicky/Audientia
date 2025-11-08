//
//  LibraryIndexerBDDTests.swift
//  DataLayerTests
//
//  BDD-style tests for library indexing functionality
//  Implements: "As a user, I want my scanned tracks to be indexed for fast searching"
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// BDD-style test suite for library indexing
/// Implements: "As a user, I want my scanned tracks to be indexed for fast searching"
@MainActor
final class LibraryIndexerBDDTests: XCTestCase {
    
    // MARK: - User Scenario: Index Scanned Tracks
    
    /// BDD: As a user, when I scan my music folder, then all tracks should be indexed
    func testUserScansMusicFolderAndTracksAreIndexed() async throws {
        // Given - User has scanned a music folder and found tracks
        let scanner = LibraryScanner()
        let testDirectory = createTestDirectory()
        _ = createTestAudioFile(directory: testDirectory, name: "track1.mp3")
        _ = createTestAudioFile(directory: testDirectory, name: "track2.flac")
        _ = createTestAudioFile(directory: testDirectory, name: "track3.m4a")
        
        let scannedTracks = try await scanner.scan(directory: testDirectory)
        let indexer = LibraryIndexer()
        
        // When - User indexes the scanned tracks
        try await indexer.index(tracks: scannedTracks)
        
        // Then - All tracks should be indexed
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 3, "Should index all 3 scanned tracks")
        
        // And - All tracks should be retrievable by ID
        for track in scannedTracks {
            let retrieved = await indexer.getTrack(by: track.id)
            XCTAssertNotNil(retrieved, "Should retrieve track \(track.title) by ID")
            XCTAssertEqual(retrieved?.id, track.id, "Retrieved track should match original")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    /// BDD: As a user, when I remove a track from my library, then it should be removed from the index
    func testUserRemovesTrackAndItIsRemovedFromIndex() async throws {
        // Given - User has indexed tracks
        let track1 = createTrack(title: "Keep This", artist: "Artist A")
        let track2 = createTrack(title: "Remove This", artist: "Artist B")
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: [track1, track2])
        
        // When - User removes a track
        try await indexer.remove(track: track2)
        
        // Then - Removed track should not be in index
        let removedTrack = await indexer.getTrack(by: track2.id)
        XCTAssertNil(removedTrack, "Removed track should not be in index")
        
        // And - Other tracks should still be in index
        let remainingTrack = await indexer.getTrack(by: track1.id)
        XCTAssertNotNil(remainingTrack, "Other tracks should remain in index")
        
        // And - Index count should be updated
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 1, "Should have one track remaining")
    }
    
    /// BDD: As a user, when I clear my library, then all tracks should be removed from the index
    func testUserClearsLibraryAndAllTracksAreRemovedFromIndex() async throws {
        // Given - User has indexed multiple tracks
        let tracks = (1...10).map { createTrack(title: "Song \($0)", artist: "Artist") }
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        
        // When - User clears the library
        try await indexer.clear()
        
        // Then - Index should be empty
        let indexedCount = await indexer.getIndexedTrackCount()
        XCTAssertEqual(indexedCount, 0, "Index should be empty after clearing")
        
        // And - No tracks should be retrievable
        for track in tracks {
            let retrieved = await indexer.getTrack(by: track.id)
            XCTAssertNil(retrieved, "No tracks should be retrievable after clearing")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("LibraryIndexerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        return testDir
    }
    
    private func createTestAudioFile(directory: URL, name: String) -> URL {
        let fileURL = directory.appendingPathComponent(name)
        let data = Data([0xFF, 0xFB, 0x90, 0x00]) // Minimal MP3 header
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        return fileURL
    }
    
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
