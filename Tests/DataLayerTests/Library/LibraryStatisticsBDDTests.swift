//
//  LibraryStatisticsBDDTests.swift
//  DataLayerTests
//
//  BDD tests for library statistics functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// BDD scenarios for LibraryStatistics
@MainActor
final class LibraryStatisticsBDDTests: XCTestCase {
    
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
    
    // MARK: - User Scenario: View Library Statistics
    
    /// BDD: As a user, when I view my library statistics, then I should see the total number of tracks
    func testUserViewsLibraryStatisticsAndSeesTrackCount() async throws {
        // Given - User has a music library with tracks
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist B", album: "Album 2", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist C", album: "Album 3", duration: 150.0, fileSize: 4_000_000, bitrate: 256, sampleRate: 48000)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see the total number of tracks
        XCTAssertEqual(stats.trackCount, 3, "User should see 3 tracks in the library")
    }
    
    /// BDD: As a user, when I view my library statistics, then I should see the total duration of all tracks
    func testUserViewsLibraryStatisticsAndSeesTotalDuration() async throws {
        // Given - User has a music library with tracks of known durations
        let tracks = [
            createTrack(title: "Short Track", artist: "Artist", album: "Album", duration: 120.0, fileSize: 3_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Medium Track", artist: "Artist", album: "Album", duration: 240.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Long Track", artist: "Artist", album: "Album", duration: 360.0, fileSize: 9_000_000, bitrate: 320, sampleRate: 44100)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see the total duration (120 + 240 + 360 = 720 seconds = 12 minutes)
        XCTAssertEqual(stats.totalDuration, 720.0, accuracy: 0.01, "User should see total duration of 720 seconds (12 minutes)")
    }
    
    /// BDD: As a user, when I view my library statistics, then I should see the total file size
    func testUserViewsLibraryStatisticsAndSeesTotalFileSize() async throws {
        // Given - User has a music library with tracks of known file sizes
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist", album: "Album", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist", album: "Album", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist", album: "Album", duration: 150.0, fileSize: 4_000_000, bitrate: 256, sampleRate: 48000)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see the total file size (5MB + 6MB + 4MB = 15MB)
        XCTAssertEqual(stats.totalFileSize, 15_000_000, "User should see total file size of 15MB")
    }
    
    /// BDD: As a user, when I view my library statistics, then I should see the number of unique artists
    func testUserViewsLibraryStatisticsAndSeesArtistCount() async throws {
        // Given - User has a music library with tracks from different artists
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist A", album: "Album 1", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist B", album: "Album 2", duration: 150.0, fileSize: 4_000_000, bitrate: 256, sampleRate: 48000),
            createTrack(title: "Track 4", artist: "Artist C", album: "Album 3", duration: 220.0, fileSize: 7_000_000, bitrate: 320, sampleRate: 44100)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see the number of unique artists (3 artists: A, B, C)
        XCTAssertEqual(stats.artistCount, 3, "User should see 3 unique artists")
    }
    
    /// BDD: As a user, when I view my library statistics, then I should see the number of unique albums
    func testUserViewsLibraryStatisticsAndSeesAlbumCount() async throws {
        // Given - User has a music library with tracks from different albums
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist A", album: "Album 1", duration: 200.0, fileSize: 6_000_000, bitrate: 320, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist B", album: "Album 2", duration: 150.0, fileSize: 4_000_000, bitrate: 256, sampleRate: 48000),
            createTrack(title: "Track 4", artist: "Artist C", album: "Album 3", duration: 220.0, fileSize: 7_000_000, bitrate: 320, sampleRate: 44100)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see the number of unique albums (3 albums)
        XCTAssertEqual(stats.albumCount, 3, "User should see 3 unique albums")
    }
    
    /// BDD: As a user, when I view my library statistics, then I should see the average bitrate
    func testUserViewsLibraryStatisticsAndSeesAverageBitrate() async throws {
        // Given - User has a music library with tracks of different bitrates
        let tracks = [
            createTrack(title: "Track 1", artist: "Artist", album: "Album", duration: 180.0, fileSize: 5_000_000, bitrate: 128, sampleRate: 44100),
            createTrack(title: "Track 2", artist: "Artist", album: "Album", duration: 200.0, fileSize: 6_000_000, bitrate: 256, sampleRate: 44100),
            createTrack(title: "Track 3", artist: "Artist", album: "Album", duration: 150.0, fileSize: 4_000_000, bitrate: 320, sampleRate: 48000)
        ]
        try await indexer.index(tracks: tracks)
        
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see the average bitrate ((128 + 256 + 320) / 3 = 234.67 kbps)
        XCTAssertEqual(stats.averageBitrate, 234.67, accuracy: 0.1, "User should see average bitrate of approximately 234.67 kbps")
    }
    
    /// BDD: As a user, when I view my empty library statistics, then I should see zero values
    func testUserViewsEmptyLibraryStatisticsAndSeesZeroValues() async throws {
        // Given - User has an empty music library
        // When - User views library statistics
        let stats = try await statistics.calculateStatistics()
        
        // Then - User should see all zero values
        XCTAssertEqual(stats.trackCount, 0, "User should see 0 tracks")
        XCTAssertEqual(stats.totalDuration, 0.0, accuracy: 0.01, "User should see 0 total duration")
        XCTAssertEqual(stats.totalFileSize, 0, "User should see 0 total file size")
        XCTAssertEqual(stats.artistCount, 0, "User should see 0 artists")
        XCTAssertEqual(stats.albumCount, 0, "User should see 0 albums")
        XCTAssertEqual(stats.averageBitrate, 0.0, accuracy: 0.01, "User should see 0 average bitrate")
        XCTAssertEqual(stats.averageSampleRate, 0.0, accuracy: 0.01, "User should see 0 average sample rate")
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
