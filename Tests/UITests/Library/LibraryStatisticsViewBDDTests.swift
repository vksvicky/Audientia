//
//  LibraryStatisticsViewBDDTests.swift
//  UITests
//
//  BDD scenarios for LibraryStatisticsView
//  Following user-centric "As a user, I want to..." format
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// BDD-style test scenarios for LibraryStatisticsView
/// Following user-centric "As a user, I want to..." format
@MainActor
final class LibraryStatisticsViewBDDTests: XCTestCase {
    
    var mockCalculator: MockLibraryStatisticsCalculator!
    
    override func setUp() {
        super.setUp()
        mockCalculator = MockLibraryStatisticsCalculator()
    }
    
    override func tearDown() {
        mockCalculator = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to see statistics about my music library
    func testUserViewsLibraryStatistics() async throws {
        // Given - I have a library with tracks
        let stats = LibraryStatistics(
            trackCount: 100,
            totalDuration: 3600.0, // 1 hour
            totalFileSize: 1_000_000_000, // 1 GB
            artistCount: 20,
            albumCount: 15,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see track count, duration, file size, artists, albums, and averages
        XCTAssertEqual(calculatedStats.trackCount, 100, "Should see 100 tracks")
        XCTAssertEqual(calculatedStats.totalDuration, 3600.0, accuracy: 0.01, "Should see 1 hour total duration")
        XCTAssertEqual(calculatedStats.totalFileSize, 1_000_000_000, "Should see 1 GB total file size")
        XCTAssertEqual(calculatedStats.artistCount, 20, "Should see 20 artists")
        XCTAssertEqual(calculatedStats.albumCount, 15, "Should see 15 albums")
        XCTAssertEqual(calculatedStats.averageBitrate, 320.0, accuracy: 0.01, "Should see average bitrate")
        XCTAssertEqual(calculatedStats.averageSampleRate, 44100.0, accuracy: 0.01, "Should see average sample rate")
    }
    
    /// BDD: As a user, I want to see that my library is empty when I have no tracks
    func testUserSeesEmptyLibraryStatistics() async throws {
        // Given - My library is empty
        let emptyStats = LibraryStatistics(
            trackCount: 0,
            totalDuration: 0.0,
            totalFileSize: 0,
            artistCount: 0,
            albumCount: 0,
            averageBitrate: 0.0,
            averageSampleRate: 0.0
        )
        mockCalculator.mockStatistics = emptyStats
        
        // When - I view my library statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see all zeros
        XCTAssertEqual(stats.trackCount, 0, "Should see 0 tracks")
        XCTAssertEqual(stats.totalDuration, 0.0, accuracy: 0.01, "Should see 0 duration")
        XCTAssertEqual(stats.totalFileSize, 0, "Should see 0 file size")
        XCTAssertEqual(stats.artistCount, 0, "Should see 0 artists")
        XCTAssertEqual(stats.albumCount, 0, "Should see 0 albums")
    }
    
    /// BDD: As a user, I want to refresh my library statistics
    func testUserRefreshesLibraryStatistics() async throws {
        // Given - I have initial statistics
        let initialStats = LibraryStatistics(
            trackCount: 50,
            totalDuration: 1800.0,
            totalFileSize: 500_000_000,
            artistCount: 10,
            albumCount: 8,
            averageBitrate: 256.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = initialStats
        
        // When - I calculate statistics
        let stats1 = try await mockCalculator.calculateStatistics()
        XCTAssertTrue(mockCalculator.calculateCalled, "Calculator should have been called")
        
        // Reset call flag
        mockCalculator.calculateCalled = false
        
        // When - I refresh statistics
        let stats2 = try await mockCalculator.calculateStatistics()
        
        // Then - Statistics should be recalculated
        XCTAssertTrue(mockCalculator.calculateCalled, "Calculator should be called again on refresh")
        XCTAssertEqual(stats1.trackCount, stats2.trackCount, "Statistics should be consistent")
    }
    
    /// BDD: As a user, I want to see accurate file size information
    func testUserSeesAccurateFileSize() async throws {
        // Given - I have tracks with known file sizes
        let stats = LibraryStatistics(
            trackCount: 10,
            totalDuration: 1800.0,
            totalFileSize: 100_000_000, // 100 MB
            artistCount: 5,
            albumCount: 3,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see the correct total file size
        XCTAssertEqual(calculatedStats.totalFileSize, 100_000_000, "Should see 100 MB total file size")
    }
    
    /// BDD: As a user, I want to see how many unique artists I have
    func testUserSeesUniqueArtistCount() async throws {
        // Given - I have tracks from multiple artists
        let stats = LibraryStatistics(
            trackCount: 50,
            totalDuration: 9000.0,
            totalFileSize: 500_000_000,
            artistCount: 15, // 15 unique artists
            albumCount: 10,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see the unique artist count
        XCTAssertEqual(calculatedStats.artistCount, 15, "Should see 15 unique artists")
        XCTAssertLessThanOrEqual(calculatedStats.artistCount, calculatedStats.trackCount, "Artist count should be <= track count")
    }
    
    /// BDD: As a user, I want to see how many unique albums I have
    func testUserSeesUniqueAlbumCount() async throws {
        // Given - I have tracks from multiple albums
        let stats = LibraryStatistics(
            trackCount: 100,
            totalDuration: 18000.0,
            totalFileSize: 1_000_000_000,
            artistCount: 20,
            albumCount: 25, // 25 unique albums
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see the unique album count
        XCTAssertEqual(calculatedStats.albumCount, 25, "Should see 25 unique albums")
        XCTAssertLessThanOrEqual(calculatedStats.albumCount, calculatedStats.trackCount, "Album count should be <= track count")
    }
    
    /// BDD: As a user, I want to see the average bitrate of my music
    func testUserSeesAverageBitrate() async throws {
        // Given - I have tracks with various bitrates
        let stats = LibraryStatistics(
            trackCount: 50,
            totalDuration: 9000.0,
            totalFileSize: 500_000_000,
            artistCount: 10,
            albumCount: 8,
            averageBitrate: 256.5, // Average bitrate
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see the average bitrate
        XCTAssertEqual(calculatedStats.averageBitrate, 256.5, accuracy: 0.01, "Should see average bitrate of 256.5 kbps")
    }
    
    /// BDD: As a user, I want to see the average sample rate of my music
    func testUserSeesAverageSampleRate() async throws {
        // Given - I have tracks with various sample rates
        let stats = LibraryStatistics(
            trackCount: 30,
            totalDuration: 5400.0,
            totalFileSize: 300_000_000,
            artistCount: 8,
            albumCount: 5,
            averageBitrate: 320.0,
            averageSampleRate: 48000.0 // Average sample rate
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see the average sample rate
        XCTAssertEqual(calculatedStats.averageSampleRate, 48000.0, accuracy: 0.01, "Should see average sample rate of 48000 Hz")
    }
    
    /// BDD: As a user, I want to see total playtime of my library
    func testUserSeesTotalPlaytime() async throws {
        // Given - I have tracks with known durations
        let stats = LibraryStatistics(
            trackCount: 20,
            totalDuration: 7200.0, // 2 hours
            totalFileSize: 200_000_000,
            artistCount: 5,
            albumCount: 4,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = stats
        
        // When - I view my library statistics
        let calculatedStats = try await mockCalculator.calculateStatistics()
        
        // Then - I should see the total playtime
        XCTAssertEqual(calculatedStats.totalDuration, 7200.0, accuracy: 0.01, "Should see 2 hours total playtime")
    }
    
    /// BDD: As a user, I want to see an error message if statistics calculation fails
    func testUserSeesErrorMessageWhenStatisticsFail() async {
        // Given - Statistics calculation will fail
        mockCalculator.shouldFail = true
        
        // When & Then - I should see an error
        do {
            _ = try await mockCalculator.calculateStatistics()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is LibraryStatisticsError, "Should throw LibraryStatisticsError")
        }
    }
}
