//
//  LibraryStatisticsTests.swift
//  DataLayerTests
//
//  TDD tests for library statistics functionality
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// TDD tests for LibraryStatistics
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class LibraryStatisticsTests: XCTestCase {
    
    var indexer: LibraryIndexer!
    var statistics: LibraryStatisticsCalculator!
    
    override func setUp() async throws {
        try await super.setUp()
        indexer = LibraryIndexer()
        statistics = LibraryStatisticsCalculator(indexer: indexer)
    }
    
    override func tearDown() async throws {
        try await indexer.clear()
        indexer = nil
        statistics = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test calculating statistics for a single track
    func testCalculateStatisticsForSingleTrack() async throws {
        // Given - A library with one track
        let track = createTrack(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
        try await indexer.index(tracks: [track])
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Statistics should be correct
        XCTAssertEqual(stats.trackCount, 1, "Should have 1 track")
        XCTAssertEqual(stats.totalDuration, 180.0, accuracy: 0.01, "Total duration should be 180 seconds")
        XCTAssertEqual(stats.totalFileSize, 5_000_000, "Total file size should be 5MB")
        XCTAssertEqual(stats.artistCount, 1, "Should have 1 artist")
        XCTAssertEqual(stats.albumCount, 1, "Should have 1 album")
        XCTAssertEqual(stats.averageBitrate, 320.0, accuracy: 0.01, "Average bitrate should be 320 kbps")
        XCTAssertEqual(stats.averageSampleRate, 44100.0, accuracy: 0.01, "Average sample rate should be 44100 Hz")
    }
    
    /// Test calculating statistics for multiple tracks
    func testCalculateStatisticsForMultipleTracks() async throws {
        // Given - A library with multiple tracks
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist A", album: "Album 1", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist B", album: "Album 2", duration: 150.0, fileSize: 4_000_000, bitrate: 256, sampleRate: 48000)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Statistics should be correct
        XCTAssertEqual(stats.trackCount, 3, "Should have 3 tracks")
        XCTAssertEqual(stats.totalDuration, 530.0, accuracy: 0.01, "Total duration should be 530 seconds")
        XCTAssertEqual(stats.totalFileSize, 15_000_000, "Total file size should be 15MB")
        XCTAssertEqual(stats.artistCount, 2, "Should have 2 unique artists")
        XCTAssertEqual(stats.albumCount, 2, "Should have 2 unique albums")
        XCTAssertEqual(stats.averageBitrate, 298.67, accuracy: 0.1, "Average bitrate should be approximately 298.67 kbps")
        XCTAssertEqual(stats.averageSampleRate, 45400.0, accuracy: 0.01, "Average sample rate should be approximately 45400 Hz")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test calculating statistics for empty library
    func testCalculateStatisticsForEmptyLibrary() async throws {
        // Given - An empty library
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - All statistics should be zero
        XCTAssertEqual(stats.trackCount, 0, "Should have 0 tracks")
        XCTAssertEqual(stats.totalDuration, 0.0, accuracy: 0.01, "Total duration should be 0")
        XCTAssertEqual(stats.totalFileSize, 0, "Total file size should be 0")
        XCTAssertEqual(stats.artistCount, 0, "Should have 0 artists")
        XCTAssertEqual(stats.albumCount, 0, "Should have 0 albums")
        XCTAssertEqual(stats.averageBitrate, 0.0, accuracy: 0.01, "Average bitrate should be 0")
        XCTAssertEqual(stats.averageSampleRate, 0.0, accuracy: 0.01, "Average sample rate should be 0")
    }
    
    /// Test calculating statistics with tracks having zero duration
    func testCalculateStatisticsWithZeroDurationTracks() async throws {
        // Given - Tracks with zero duration
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 0.0, fileSize: 1_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Should handle zero duration correctly
        XCTAssertEqual(stats.trackCount, 2, "Should have 2 tracks")
        XCTAssertEqual(stats.totalDuration, 180.0, accuracy: 0.01, "Total duration should be 180 seconds")
        XCTAssertEqual(stats.averageBitrate, 320.0, accuracy: 0.01, "Average bitrate should be 320 kbps")
    }
    
    /// Test calculating statistics with very large values
    func testCalculateStatisticsWithVeryLargeValues() async throws {
        // Given - Tracks with very large values
        let tracks = [
            createTrack(title: "Long Track", artist: "Artist", album: "Album", duration: 3600.0, fileSize: 100_000_000_000, bitrate: 320, sampleRate: 192000)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Should handle large values correctly
        XCTAssertEqual(stats.trackCount, 1, "Should have 1 track")
        XCTAssertEqual(stats.totalDuration, 3600.0, accuracy: 0.01, "Total duration should be 3600 seconds")
        XCTAssertEqual(stats.totalFileSize, 100_000_000_000, "Total file size should be 100GB")
        XCTAssertEqual(stats.averageSampleRate, 192000.0, accuracy: 0.01, "Average sample rate should be 192000 Hz")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that adding then removing a track restores original statistics
    func testAddRemoveTrackRestoresStatistics() async throws {
        // Given - Initial library with one track
        let track1 = createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100)
        try await indexer.index(tracks: [track1])
        let initialStats = try await statistics.calculateStatistics()
        
        // When - Add another track then remove it
        let track2 = createTrack(title: "Track 2", artist: "Artist B", album: "Album 2", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100)
        try await indexer.index(tracks: [track2])
        try await indexer.remove(track: track2)
        
        // Then - Statistics should match initial state
        let finalStats = try await statistics.calculateStatistics()
        XCTAssertEqual(finalStats.trackCount, initialStats.trackCount, "Track count should match initial state")
        XCTAssertEqual(finalStats.totalDuration, initialStats.totalDuration, accuracy: 0.01, "Total duration should match initial state")
        XCTAssertEqual(finalStats.artistCount, initialStats.artistCount, "Artist count should match initial state")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test that statistics match manual calculation
    func testStatisticsMatchManualCalculation() async throws {
        // Given - Known tracks
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 100.0, fileSize: 2_000_000, bitrate: 160, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist A", album: "Album 1", duration: 200.0, fileSize: 4_000_000, bitrate: 160, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist B", album: "Album 2", duration: 300.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 48000)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Verify manual calculations
        // Total duration: 100 + 200 + 300 = 600 seconds
        XCTAssertEqual(stats.totalDuration, 600.0, accuracy: 0.01, "Total duration should be 600 seconds")
        // Total file size: 2MB + 4MB + 6MB = 12MB
        XCTAssertEqual(stats.totalFileSize, 12_000_000, "Total file size should be 12MB")
        // Average bitrate: (160 + 160 + 320) / 3 = 213.33 kbps
        XCTAssertEqual(stats.averageBitrate, 213.33, accuracy: 0.1, "Average bitrate should be approximately 213.33 kbps")
        // Average sample rate: (44100 + 44100 + 48000) / 3 = 45400 Hz
        XCTAssertEqual(stats.averageSampleRate, 45400.0, accuracy: 0.01, "Average sample rate should be approximately 45400 Hz")
    }
    
    // MARK: - Error Conditions
    
    /// Test that statistics calculation handles missing indexer gracefully
    func testStatisticsCalculationWithNilIndexer() async {
        // Given - Statistics calculator with nil indexer
        let nilStatistics = LibraryStatisticsCalculator(indexer: nil)
        
        // When/Then - Should throw error
        do {
            _ = try await nilStatistics.calculateStatistics()
            XCTFail("Should throw error when indexer is nil")
        } catch {
            XCTAssertTrue(error is LibraryStatisticsError, "Should throw LibraryStatisticsError")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that statistics calculation is performant for large libraries
    func testStatisticsCalculationPerformance() async throws {
        // Given - A large library (1000 tracks)
        var tracks: [Track] = []
        for i in 1...1000 {
            tracks.append(createTrack(
                title: "Track \(i)",
                artist: "Artist \(i % 100)",
                album: "Album \(i % 50)",
                duration: Double.random(in: 120...300),
                fileSize: Int64.random(in: 3_000_000...10_000_000),
                bitrate: [128, 192, 256, 320].randomElement() ?? 320,
                sampleRate: [44100, 48000, 96000].randomElement() ?? 44100
            ))
        }
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let startTime = Date()
        _ = try await statistics.calculateStatistics()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (< 1 second for 1000 tracks)
        XCTAssertLessThan(duration, 1.0, "Statistics calculation should complete within 1 second for 1000 tracks")
    }
    
    // MARK: - Edge Cases
    
    /// Test statistics with tracks having same artist/album names
    func testStatisticsWithDuplicateArtistAlbumNames() async throws {
        // Given - Tracks with same artist and album names
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist", album: "Album", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist", album: "Album", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist", album: "Album", duration: 150.0, fileSize: 4_000_000, bitrate: 320, sampleRate: 44100)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Should count unique artists/albums correctly
        XCTAssertEqual(stats.trackCount, 3, "Should have 3 tracks")
        XCTAssertEqual(stats.artistCount, 1, "Should have 1 unique artist")
        XCTAssertEqual(stats.albumCount, 1, "Should have 1 unique album")
    }
    
    /// Test statistics with tracks having empty artist/album names
    func testStatisticsWithEmptyArtistAlbumNames() async throws {
        // Given - Tracks with empty artist/album names
        let tracks = [
            createTrack(title: "Track 1", artist: "", album: "", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "", album: "", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - Calculate statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - Should handle empty strings correctly (counted as unique)
        XCTAssertEqual(stats.trackCount, 2, "Should have 2 tracks")
        XCTAssertEqual(stats.artistCount, 1, "Should count empty artist as 1 unique")
        XCTAssertEqual(stats.albumCount, 1, "Should count empty album as 1 unique")
    }
    
    // MARK: - Helper Methods
    
    private struct TrackParams {
        let title: String
        let artist: String
        let album: String
        let duration: TimeInterval
        let fileSize: Int64
        let bitrate: Int
        let sampleRate: Int
    }
    
    private func createTrack(params: TrackParams) -> Track {
        Track(
            title: params.title,
            artist: params.artist,
            album: params.album,
            duration: params.duration,
            filePath: "/path/to/\(params.title).mp3",
            fileSize: params.fileSize,
            bitrate: params.bitrate,
            sampleRate: params.sampleRate
        )
    }
    
    private func createTrack(
        title: String = "Test Song",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 60.0,
        fileSize: Int64 = 5_000_000,
        bitrate: Int = 256,
        sampleRate: Int = 44100
    ) -> Track {
        createTrack(params: TrackParams(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate
        ))
    }
}
