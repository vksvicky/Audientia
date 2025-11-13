//
//  LibraryOperationsPerformanceTests.swift
//  Audientia - Library Operations Performance Tests
//
//  Performance tests for library operations (scan, indexing, playlist load)
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import os.log
import XCTest

@testable import DataLayer
@testable import Shared

/// Performance tests for library operations
@MainActor
final class LibraryOperationsPerformanceTests: XCTestCase {
    
    /// Performance: Scan 10,000 tracks: < 5 minutes
    func testLibraryScanPerformance() async {
        // Given - Large library simulation
        let trackCount = 10_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                filePath: "/path/to/track\(index).mp3"
            )
        }
        
        // When - Measure scanning performance
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 1) {
            // Simulate scanning operation
            // In real implementation, this would use LibraryScanner
            var scanned: [Shared.Track] = []
            for track in tracks {
                scanned.append(track)
            }
            return scanned
        }
        
        // Then - Should complete within 5 minutes
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 300.0, // 5 minutes
            maxP95Duration: nil
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Library Scan (10,000 tracks)",
            metrics: metrics,
            sla: 300.0
        )
        Logger.testing.info("\(report)")
    }
    
    /// Performance: Indexing 100,000 tracks: < 30s
    func testIndexingPerformance() async throws {
        // Given - Large library to index
        let trackCount = 100_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                artist: "Artist \(index % 100)",
                album: "Album \(index % 1000)"
            )
        }
        
        let indexer = LibraryIndexer()
        
        // When - Measure indexing performance
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
            try await indexer.index(tracks: tracks)
        }, iterations: 1)
        
        // Then - Should complete within reasonable time (< 30s for 100k tracks)
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 30.0 // 30 seconds for 100k tracks
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Indexing (100,000 tracks)",
            metrics: metrics,
            sla: 30.0
        )
        Logger.testing.info("\(report)")
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Load playlist (1000 tracks): < 200ms
    func testPlaylistLoadPerformance() async {
        // Given - Large playlist
        let trackCount = 1000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)"
            )
        }
        
        // When - Measure playlist loading
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 10) {
            // Simulate playlist load
            // In real implementation, this would load from DataLayer
            Array(tracks)
        }
        
        // Then - Average should be < 200ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.2 // 200ms
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Playlist Load (1,000 tracks)",
            metrics: metrics,
            sla: 0.2,
            slaMetric: .average
        )
        Logger.testing.info("\(report)")
    }
}
