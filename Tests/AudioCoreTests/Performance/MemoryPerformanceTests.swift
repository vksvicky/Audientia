//
//  MemoryPerformanceTests.swift
//  Audientia - Memory Performance Tests
//
//  Performance tests for memory usage
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Shared
import XCTest

/// Performance tests for memory usage
@MainActor
final class MemoryPerformanceTests: XCTestCase {
    
    /// Test memory usage during large operations
    func testMemoryUsageDuringLargeScan() async {
        // Given - Large library
        let trackCount = 10_000
        
        // When - Measure memory usage
        let memoryResult = await PerformanceTestHelpers.measureMemoryUsage {
            // Simulate large scan operation
            var tracks: [Shared.Track] = []
            for i in 0..<trackCount {
                tracks.append(MockFactory.makeTrack(
                    id: UUID(),
                    title: "Track \(i)"
                ))
            }
            return tracks
        }
        
        // Then - Memory delta should be reasonable (< 100MB for 10k tracks)
        let deltaMB = Double(memoryResult.delta) / 1_000_000.0
        XCTAssertLessThan(deltaMB, 100.0, "Memory usage should be reasonable")
        
        print("Memory Usage Test:")
        print("  Before: \(String(format: "%.2f", Double(memoryResult.before) / 1_000_000.0)) MB")
        print("  After: \(String(format: "%.2f", Double(memoryResult.after) / 1_000_000.0)) MB")
        print("  Delta: \(String(format: "%.2f", deltaMB)) MB")
    }
}
