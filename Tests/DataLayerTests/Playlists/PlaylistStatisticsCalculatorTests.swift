//
//  PlaylistStatisticsCalculatorTests.swift
//  DataLayerTests
//
//  TDD tests for PlaylistStatisticsCalculator following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// TDD tests for PlaylistStatisticsCalculator
/// Following Right-BICEP principles:
/// - [Right]: Verify statistics calculations are correct
/// - [B]oundary: Empty playlist, single track, very large playlists
/// - [I]nverse: Add track → Verify statistics increase
/// - [C]ross-check: Compare with manual calculations
/// - [E]rror: Nil values, missing fields
/// - [P]erformance: Calculate statistics < 200ms for large playlists
final class PlaylistStatisticsCalculatorTests: XCTestCase {
    
    var calculator: PlaylistStatisticsCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = PlaylistStatisticsCalculator()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper to create a track for testing
    private func createTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3",
        fileSize: Int64 = 5_000_000,
        bitrate: Int = 320,
        sampleRate: Int = 44100,
        year: Int? = nil,
        genre: String? = nil,
        rating: Int? = nil
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate,
            year: year,
            trackNumber: nil,
            discNumber: nil,
            genre: genre,
            rating: rating
        )
    }
    
    // MARK: - [Right] Tests - Verify Correct Results
    
    /// Test calculating statistics for empty playlist
    func testCalculateStatisticsForEmptyPlaylist() {
        // Given
        let tracks: [Track] = []
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.trackCount, 0)
        XCTAssertEqual(statistics.totalDuration, 0.0)
        XCTAssertEqual(statistics.averageDuration, 0.0)
        XCTAssertEqual(statistics.totalFileSize, 0)
        XCTAssertEqual(statistics.averageFileSize, 0)
        XCTAssertEqual(statistics.uniqueArtists, 0)
        XCTAssertEqual(statistics.uniqueAlbums, 0)
        XCTAssertEqual(statistics.uniqueGenres, 0)
        XCTAssertNil(statistics.averageRating)
        XCTAssertNil(statistics.yearRange.earliest)
        XCTAssertNil(statistics.yearRange.latest)
    }
    
    /// Test calculating statistics for single track
    func testCalculateStatisticsForSingleTrack() {
        // Given
        let track = createTrack(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            fileSize: 5_000_000,
            year: 2020,
            genre: "Rock",
            rating: 5
        )
        let tracks = [track]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.trackCount, 1)
        XCTAssertEqual(statistics.totalDuration, 180.0, accuracy: 0.01)
        XCTAssertEqual(statistics.averageDuration, 180.0, accuracy: 0.01)
        XCTAssertEqual(statistics.totalFileSize, 5_000_000)
        XCTAssertEqual(statistics.averageFileSize, 5_000_000)
        XCTAssertEqual(statistics.uniqueArtists, 1)
        XCTAssertEqual(statistics.uniqueAlbums, 1)
        XCTAssertEqual(statistics.uniqueGenres, 1)
        XCTAssertEqual(statistics.averageRating ?? 0.0, 5.0, accuracy: 0.01)
        XCTAssertEqual(statistics.yearRange.earliest, 2020)
        XCTAssertEqual(statistics.yearRange.latest, 2020)
    }
    
    /// Test calculating statistics for multiple tracks
    func testCalculateStatisticsForMultipleTracks() {
        // Given
        let tracks = [
            createTrack(title: "Song 1", artist: "Artist A", album: "Album 1", duration: 180.0, fileSize: 5_000_000, year: 2020, genre: "Rock", rating: 5),
            createTrack(title: "Song 2", artist: "Artist B", album: "Album 2", duration: 200.0, fileSize: 6_000_000, year: 2021, genre: "Pop", rating: 4),
            createTrack(title: "Song 3", artist: "Artist A", album: "Album 1", duration: 160.0, fileSize: 4_000_000, year: 2019, genre: "Rock", rating: 5)
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.trackCount, 3)
        XCTAssertEqual(statistics.totalDuration, 540.0, accuracy: 0.01)
        XCTAssertEqual(statistics.averageDuration, 180.0, accuracy: 0.01)
        XCTAssertEqual(statistics.totalFileSize, 15_000_000)
        XCTAssertEqual(statistics.averageFileSize, 5_000_000)
        XCTAssertEqual(statistics.uniqueArtists, 2) // Artist A and Artist B
        XCTAssertEqual(statistics.uniqueAlbums, 2) // Album 1 and Album 2
        XCTAssertEqual(statistics.uniqueGenres, 2) // Rock and Pop
        XCTAssertEqual(statistics.averageRating ?? 0.0, 4.67, accuracy: 0.01) // (5+4+5)/3
        XCTAssertEqual(statistics.yearRange.earliest, 2019)
        XCTAssertEqual(statistics.yearRange.latest, 2021)
    }
    
    /// Test calculating average rating with some nil ratings
    func testCalculateAverageRatingWithNilRatings() {
        // Given
        let tracks = [
            createTrack(title: "Song 1", rating: 5),
            createTrack(title: "Song 2"),
            createTrack(title: "Song 3", rating: 4)
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.averageRating ?? 0.0, 4.5, accuracy: 0.01) // (5+4)/2
    }
    
    /// Test calculating statistics with no ratings
    func testCalculateStatisticsWithNoRatings() {
        // Given
        let tracks = [
            createTrack(title: "Song 1"),
            createTrack(title: "Song 2")
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertNil(statistics.averageRating)
    }
    
    // MARK: - [B]oundary Tests
    
    /// Test calculating statistics with very large playlist
    func testCalculateStatisticsForLargePlaylist() {
        // Given
        var tracks: [Track] = []
        for i in 0..<1000 {
            tracks.append(createTrack(
                title: "Song \(i)",
                artist: "Artist \(i % 10)",
                album: "Album \(i % 20)",
                duration: Double(180 + (i % 60)),
                fileSize: Int64(5_000_000 + (i * 1000)),
                year: 2020 + (i % 5),
                genre: i % 2 == 0 ? "Rock" : "Pop",
                rating: (i % 5) + 1
            ))
        }
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.trackCount, 1000)
        XCTAssertGreaterThan(statistics.totalDuration, 0.0)
        XCTAssertGreaterThan(statistics.totalFileSize, 0)
        XCTAssertEqual(statistics.uniqueArtists, 10)
        XCTAssertEqual(statistics.uniqueAlbums, 20)
        XCTAssertEqual(statistics.uniqueGenres, 2)
        XCTAssertNotNil(statistics.averageRating)
    }
    
    /// Test calculating statistics with nil years
    func testCalculateStatisticsWithNilYears() {
        // Given
        let tracks = [
            createTrack(title: "Song 1"),
            createTrack(title: "Song 2")
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertNil(statistics.yearRange.earliest)
        XCTAssertNil(statistics.yearRange.latest)
    }
    
    /// Test calculating statistics with nil genres
    func testCalculateStatisticsWithNilGenres() {
        // Given
        let tracks = [
            createTrack(title: "Song 1"),
            createTrack(title: "Song 2")
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.uniqueGenres, 0)
    }
    
    // MARK: - [I]nverse Tests
    
    /// Test inverse: Add track → Verify statistics increase
    func testInverseAddTrackIncreasesStatistics() {
        // Given - Use different artists, albums, and genres to ensure unique counts increase
        let track1 = createTrack(title: "Song 1", artist: "Artist A", album: "Album A", duration: 180.0, fileSize: 5_000_000, genre: "Rock")
        let track2 = createTrack(title: "Song 2", artist: "Artist B", album: "Album B", duration: 200.0, fileSize: 6_000_000, genre: "Pop")
        
        // When - Calculate with one track
        let statistics1 = calculator.calculateStatistics(for: [track1])
        
        // When - Calculate with two tracks
        let statistics2 = calculator.calculateStatistics(for: [track1, track2])
        
        // Then
        XCTAssertGreaterThan(statistics2.trackCount, statistics1.trackCount)
        XCTAssertGreaterThan(statistics2.totalDuration, statistics1.totalDuration)
        XCTAssertGreaterThan(statistics2.totalFileSize, statistics1.totalFileSize)
        XCTAssertGreaterThan(statistics2.uniqueArtists, statistics1.uniqueArtists)
        XCTAssertGreaterThan(statistics2.uniqueAlbums, statistics1.uniqueAlbums)
        XCTAssertGreaterThan(statistics2.uniqueGenres, statistics1.uniqueGenres)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test cross-check: Manual calculation vs calculator
    func testCrossCheckManualCalculation() {
        // Given
        let tracks = [
            createTrack(title: "Song 1", duration: 180.0, fileSize: 5_000_000, rating: 5),
            createTrack(title: "Song 2", duration: 200.0, fileSize: 6_000_000, rating: 4)
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then - Manual calculation
        let manualTrackCount = tracks.count
        let manualTotalDuration = tracks.reduce(0.0) { $0 + $1.duration }
        let manualAverageDuration = manualTotalDuration / Double(manualTrackCount)
        let manualTotalFileSize = tracks.reduce(Int64(0)) { $0 + $1.fileSize }
        let manualAverageFileSize = manualTotalFileSize / Int64(manualTrackCount)
        let manualRatings = tracks.compactMap { $0.rating.map { Double($0) } }
        let manualAverageRating = manualRatings.isEmpty ? nil : manualRatings.reduce(0.0, +) / Double(manualRatings.count)
        
        XCTAssertEqual(statistics.trackCount, manualTrackCount)
        XCTAssertEqual(statistics.totalDuration, manualTotalDuration, accuracy: 0.01)
        XCTAssertEqual(statistics.averageDuration, manualAverageDuration, accuracy: 0.01)
        XCTAssertEqual(statistics.totalFileSize, manualTotalFileSize)
        XCTAssertEqual(statistics.averageFileSize, manualAverageFileSize)
        if let statsRating = statistics.averageRating, let manualRating = manualAverageRating {
            XCTAssertEqual(statsRating, manualRating, accuracy: 0.01)
        } else {
            XCTAssertNil(statistics.averageRating)
            XCTAssertNil(manualAverageRating)
        }
    }
    
    // MARK: - [E]rror Tests
    
    /// Test calculating statistics with tracks having all nil optional fields
    func testCalculateStatisticsWithAllNilFields() {
        // Given
        let tracks = [
            createTrack(title: "Song 1"),
            createTrack(title: "Song 2")
        ]
        
        // When
        let statistics = calculator.calculateStatistics(for: tracks)
        
        // Then
        XCTAssertEqual(statistics.trackCount, 2)
        XCTAssertNil(statistics.averageRating)
        XCTAssertNil(statistics.yearRange.earliest)
        XCTAssertNil(statistics.yearRange.latest)
        XCTAssertEqual(statistics.uniqueGenres, 0)
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test performance: Calculate statistics for large playlist
    func testPerformanceCalculateStatisticsForLargePlaylist() {
        // Given
        var tracks: [Track] = []
        for i in 0..<10000 {
            tracks.append(createTrack(
                title: "Song \(i)",
                artist: "Artist \(i % 100)",
                album: "Album \(i % 200)",
                duration: Double(180 + (i % 60)),
                fileSize: Int64(5_000_000 + (i * 1000)),
                year: 2020 + (i % 10),
                genre: "Genre \(i % 20)",
                rating: (i % 5) + 1
            ))
        }
        
        // When
        let startTime = Date()
        let statistics = calculator.calculateStatistics(for: tracks)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(statistics.trackCount, 10000)
        XCTAssertLessThan(duration, 0.2, "Calculating statistics for 10000 tracks should take less than 200ms")
    }
}
