//
//  UIPerformanceTests.swift
//  Audientia - UI Performance Tests
//
//  Performance tests for UI-related operations
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Shared
import XCTest

/// Performance tests for UI operations
@MainActor
final class UIPerformanceTests: XCTestCase {
    
    /// Performance: UI update operations should be fast
    /// Note: Actual UI rendering requires UI tests, but we can test the underlying data operations
    func testUIDataUpdatePerformance() async {
        // Given - Track data for UI updates
        let trackCount = 1000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                artist: "Artist \(index % 100)",
                album: "Album \(index % 50)"
            )
        }
        
        // When - Measure data preparation for UI (filtering, sorting)
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 100) {
            // Simulate UI data operations: filter and sort
            let filtered = tracks.filter { $0.artist.contains("Artist 50") }
            let sorted = filtered.sorted { $0.title < $1.title }
            return sorted
        }
        
        // Then - Should be fast enough for 60fps (< 16ms)
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.016 // 16ms for 60fps
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "UI Data Update (1,000 tracks, filter & sort)",
            metrics: metrics,
            sla: 0.016
        ))
    }
}
