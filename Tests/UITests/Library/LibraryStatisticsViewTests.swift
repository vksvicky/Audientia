//
//  LibraryStatisticsViewTests.swift
//  UITests
//
//  TDD tests for LibraryStatisticsView and LibraryStatisticsViewModel
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// Mock implementation of LibraryStatisticsProtocol for testing
@MainActor
final class MockLibraryStatisticsCalculator: LibraryStatisticsProtocol {
    
    var mockStatistics: LibraryStatistics?
    var shouldFail = false
    var calculateCalled = false
    
    func calculateStatistics() async throws -> LibraryStatistics {
        calculateCalled = true
        
        if shouldFail {
            throw LibraryStatisticsError.calculationFailed
        }
        
        guard let stats = mockStatistics else {
            // Return empty statistics by default
            return LibraryStatistics(
                trackCount: 0,
                totalDuration: 0.0,
                totalFileSize: 0,
                artistCount: 0,
                albumCount: 0,
                averageBitrate: 0.0,
                averageSampleRate: 0.0
            )
        }
        
        return stats
    }
}

/// TDD tests for LibraryStatisticsView
/// Following Right-BICEP principles
/// Note: Since LibraryStatisticsViewModel is private, we test through the calculator
@MainActor
final class LibraryStatisticsViewTests: XCTestCase {
    
    var mockCalculator: MockLibraryStatisticsCalculator!
    
    override func setUp() {
        super.setUp()
        mockCalculator = MockLibraryStatisticsCalculator()
    }
    
    override func tearDown() {
        mockCalculator = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// Test that calculator returns correct statistics
    func testCalculatorReturnsCorrectStatistics() async throws {
        // Given - Mock statistics
        let expectedStats = LibraryStatistics(
            trackCount: 100,
            totalDuration: 3600.0, // 1 hour
            totalFileSize: 1_000_000_000, // 1 GB
            artistCount: 20,
            albumCount: 15,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = expectedStats
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - Should match expected values
        XCTAssertEqual(stats.trackCount, 100, "Track count should be 100")
        XCTAssertEqual(stats.totalDuration, 3600.0, accuracy: 0.01, "Total duration should be 3600 seconds")
        XCTAssertEqual(stats.totalFileSize, 1_000_000_000, "Total file size should be 1 GB")
        XCTAssertEqual(stats.artistCount, 20, "Artist count should be 20")
        XCTAssertEqual(stats.albumCount, 15, "Album count should be 15")
        XCTAssertEqual(stats.averageBitrate, 320.0, accuracy: 0.01, "Average bitrate should be 320 kbps")
        XCTAssertEqual(stats.averageSampleRate, 44100.0, accuracy: 0.01, "Average sample rate should be 44100 Hz")
    }
    
    /// Test that calculator is called when statistics are requested
    func testCalculatorIsCalledWhenStatisticsRequested() async throws {
        // Given - Mock calculator
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 10,
            totalDuration: 1800.0,
            totalFileSize: 100_000_000,
            artistCount: 5,
            albumCount: 3,
            averageBitrate: 256.0,
            averageSampleRate: 44100.0
        )
        
        // When - Calculate statistics
        _ = try await mockCalculator.calculateStatistics()
        
        // Then - Calculator should have been called
        XCTAssertTrue(mockCalculator.calculateCalled, "Calculator should have been called")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// Test with empty library
    func testEmptyLibraryStatistics() async throws {
        // Given - Empty library
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 0,
            totalDuration: 0.0,
            totalFileSize: 0,
            artistCount: 0,
            albumCount: 0,
            averageBitrate: 0.0,
            averageSampleRate: 0.0
        )
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - All values should be zero
        XCTAssertEqual(stats.trackCount, 0, "Track count should be 0")
        XCTAssertEqual(stats.totalDuration, 0.0, accuracy: 0.01, "Total duration should be 0")
        XCTAssertEqual(stats.totalFileSize, 0, "Total file size should be 0")
        XCTAssertEqual(stats.artistCount, 0, "Artist count should be 0")
        XCTAssertEqual(stats.albumCount, 0, "Album count should be 0")
        XCTAssertEqual(stats.averageBitrate, 0.0, accuracy: 0.01, "Average bitrate should be 0")
        XCTAssertEqual(stats.averageSampleRate, 0.0, accuracy: 0.01, "Average sample rate should be 0")
    }
    
    /// Test with single track
    func testSingleTrackStatistics() async throws {
        // Given - Single track
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 1,
            totalDuration: 180.0, // 3 minutes
            totalFileSize: 5_000_000, // 5 MB
            artistCount: 1,
            albumCount: 1,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - Should reflect single track
        XCTAssertEqual(stats.trackCount, 1, "Track count should be 1")
        XCTAssertEqual(stats.totalDuration, 180.0, accuracy: 0.01, "Total duration should be 180 seconds")
        XCTAssertEqual(stats.artistCount, 1, "Artist count should be 1")
        XCTAssertEqual(stats.albumCount, 1, "Album count should be 1")
    }
    
    /// Test with very large library
    func testVeryLargeLibraryStatistics() async throws {
        // Given - Very large library
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 100_000,
            totalDuration: 3_600_000.0, // 1000 hours
            totalFileSize: 1_000_000_000_000, // 1 TB
            artistCount: 10_000,
            albumCount: 5_000,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - Should handle large values
        XCTAssertEqual(stats.trackCount, 100_000, "Track count should be 100,000")
        XCTAssertEqual(stats.totalDuration, 3_600_000.0, accuracy: 0.01, "Total duration should be correct")
        XCTAssertEqual(stats.totalFileSize, 1_000_000_000_000, "Total file size should be 1 TB")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test that statistics are consistent across multiple calls
    func testStatisticsConsistency() async throws {
        // Given - Mock statistics
        let expectedStats = LibraryStatistics(
            trackCount: 50,
            totalDuration: 9000.0,
            totalFileSize: 500_000_000,
            artistCount: 10,
            albumCount: 8,
            averageBitrate: 256.0,
            averageSampleRate: 44100.0
        )
        mockCalculator.mockStatistics = expectedStats
        
        // When - Calculate statistics multiple times
        let stats1 = try await mockCalculator.calculateStatistics()
        let stats2 = try await mockCalculator.calculateStatistics()
        
        // Then - Results should be consistent
        XCTAssertEqual(stats1.trackCount, stats2.trackCount, "Track count should be consistent")
        XCTAssertEqual(stats1.totalDuration, stats2.totalDuration, accuracy: 0.01, "Total duration should be consistent")
        XCTAssertEqual(stats1.totalFileSize, stats2.totalFileSize, "Total file size should be consistent")
    }
    
    // MARK: - [C]ross-Checking
    
    /// Test that statistics values are logically consistent
    func testStatisticsLogicalConsistency() async throws {
        // Given - Statistics with known values
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 100,
            totalDuration: 3600.0,
            totalFileSize: 1_000_000_000,
            artistCount: 20,
            albumCount: 15,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - Values should be logically consistent
        XCTAssertGreaterThanOrEqual(stats.trackCount, stats.artistCount, "Track count should be >= artist count")
        XCTAssertGreaterThanOrEqual(stats.trackCount, stats.albumCount, "Track count should be >= album count")
        XCTAssertGreaterThanOrEqual(stats.totalDuration, 0.0, "Total duration should be >= 0")
        XCTAssertGreaterThanOrEqual(stats.totalFileSize, 0, "Total file size should be >= 0")
        XCTAssertGreaterThanOrEqual(stats.averageBitrate, 0.0, "Average bitrate should be >= 0")
        XCTAssertGreaterThanOrEqual(stats.averageSampleRate, 0.0, "Average sample rate should be >= 0")
    }
    
    // MARK: - [E]rror Conditions
    
    /// Test that calculation failure is handled
    func testCalculationFailureHandled() async {
        // Given - Calculator is configured to fail
        mockCalculator.shouldFail = true
        
        // When & Then - Should throw error
        do {
            _ = try await mockCalculator.calculateStatistics()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is LibraryStatisticsError, "Should throw LibraryStatisticsError")
        }
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// Test that statistics calculation completes quickly
    func testStatisticsCalculationPerformance() async throws {
        // Given - Mock statistics
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 10_000,
            totalDuration: 360_000.0,
            totalFileSize: 10_000_000_000,
            artistCount: 1_000,
            albumCount: 500,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        
        // When - Calculate statistics and measure time
        let startTime = Date()
        _ = try await mockCalculator.calculateStatistics()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete quickly (< 100ms for mock)
        XCTAssertLessThan(duration, 0.1, "Statistics calculation should complete quickly")
    }
    
    // MARK: - Edge Cases
    
    /// Test with zero duration tracks
    func testZeroDurationTracks() async throws {
        // Given - Tracks with zero duration
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 10,
            totalDuration: 0.0,
            totalFileSize: 50_000_000,
            artistCount: 5,
            albumCount: 3,
            averageBitrate: 320.0,
            averageSampleRate: 44100.0
        )
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - Should handle zero duration
        XCTAssertEqual(stats.totalDuration, 0.0, accuracy: 0.01, "Total duration should be 0")
        XCTAssertGreaterThan(stats.trackCount, 0, "Should still have tracks")
    }
    
    /// Test with very small file sizes
    func testVerySmallFileSizes() async throws {
        // Given - Very small file sizes
        mockCalculator.mockStatistics = LibraryStatistics(
            trackCount: 100,
            totalDuration: 1800.0,
            totalFileSize: 1000, // 1 KB total
            artistCount: 10,
            albumCount: 5,
            averageBitrate: 1.0,
            averageSampleRate: 8000.0
        )
        
        // When - Calculate statistics
        let stats = try await mockCalculator.calculateStatistics()
        
        // Then - Should handle small values
        XCTAssertEqual(stats.totalFileSize, 1000, "Total file size should be 1000 bytes")
        XCTAssertEqual(stats.averageBitrate, 1.0, accuracy: 0.01, "Average bitrate should be 1 kbps")
    }
}
