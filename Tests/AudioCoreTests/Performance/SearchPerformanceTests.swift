//
//  SearchPerformanceTests.swift
//  Audientia - Search Performance Tests
//
//  Performance tests for library search operations
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// Performance tests for search operations
@MainActor
final class SearchPerformanceTests: XCTestCase {
    
    /// Performance: Search 100,000 tracks: < 100ms (P95)
    func testLibrarySearchPerformance() async throws {
        // Given - Large library for searching
        let trackCount = 100_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                artist: "Artist \(index % 100)",
                album: "Album \(index % 1000)"
            )
        }
        
        // Set up indexer and search with optimized search index
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Measure search performance using actual LibrarySearch
        let searchQuery = "Track 50000"
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
            try await search.search(query: searchQuery, field: .all)
        }, iterations: 100)
        
        // Then - P95 should be < 100ms
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 10.0, // Total for 100 iterations
            maxP95Duration: 0.1 // 100ms per search
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Library Search (100,000 tracks)",
            metrics: metrics,
            sla: 0.1
        ))
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Search with different query types
    func testSearchWithDifferentQueryTypes() async throws {
        // Given - Large library with varied data
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
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Test different query types
        let queries = [
            "Track 50000",      // Exact match
            "Artist 50",        // Artist search
            "Album 500",        // Album search
            "50",               // Number search
            "Track"             // Common word
        ]
        
        var allMetrics: [PerformanceMetrics] = []
        
        for query in queries {
            let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
                try await search.search(query: query, field: .all)
            }, iterations: 50)
            allMetrics.append(metrics)
        }
        
        // Then - All searches should meet P95 < 100ms
        for (index, metrics) in allMetrics.enumerated() {
            PerformanceTestHelpers.assertPerformanceSLA(
                metrics: metrics,
                maxDuration: 5.0, // Total for 50 iterations
                maxP95Duration: 0.1 // 100ms per search
            )
            
            print(PerformanceTestHelpers.generateReport(
                testName: "Search Query Type '\(queries[index])'",
                metrics: metrics,
                sla: 0.1
            ))
        }
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Concurrent search operations
    func testConcurrentSearchPerformance() async throws {
        // Given - Large library
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
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Perform concurrent searches
        let startTime = Date()
        await withTaskGroup(of: [Shared.Track].self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        return try await search.search(query: "Track \(i * 10000)", field: .all)
                    } catch {
                        return []
                    }
                }
            }
        }
        let totalDuration = Date().timeIntervalSince(startTime)
        
        // Then - All concurrent searches should complete quickly
        XCTAssertLessThan(totalDuration, 1.0, "10 concurrent searches should complete in < 1s")
        
        print("Concurrent Search Performance:")
        print("  10 concurrent searches completed in \(String(format: "%.3f", totalDuration))s")
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Search 1,000,000 tracks: < 200ms (P95)
    func testVeryLargeLibrarySearchPerformance() async throws {
        // Given - Very large library (1M tracks)
        let trackCount = 1_000_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                artist: "Artist \(index % 1000)",
                album: "Album \(index % 10000)"
            )
        }
        
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Measure search performance
        let searchQuery = "Track 500000"
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
            try await search.search(query: searchQuery, field: .all)
        }, iterations: 50)
        
        // Then - P95 should be < 200ms (relaxed for very large library)
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 10.0, // Total for 50 iterations
            maxP95Duration: 0.2 // 200ms per search for 1M tracks
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Library Search (1,000,000 tracks)",
            metrics: metrics,
            sla: 0.2
        ))
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Search with very long query strings
    func testSearchWithLongQueryPerformance() async throws {
        // Given - Library and very long query
        let trackCount = 100_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index) with a very long title that contains many words",
                artist: "Artist \(index % 100)",
                album: "Album \(index % 1000)"
            )
        }
        
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Search with very long query
        let longQuery = String(repeating: "Track ", count: 50) + "50000"
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
            try await search.search(query: longQuery, field: .all)
        }, iterations: 50)
        
        // Then - Should still meet performance SLA
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 5.0,
            maxP95Duration: 0.1 // 100ms even with long query
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Search with Long Query (100,000 tracks)",
            metrics: metrics,
            sla: 0.1
        ))
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Search with special characters and Unicode
    func testSearchWithUnicodePerformance() async throws {
        // Given - Library with Unicode content
        let trackCount = 100_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index) 🎵 émojis & symbols",
                artist: "Artist \(index % 100) with ünicode",
                album: "Album \(index % 1000) (2024)"
            )
        }
        
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Search with Unicode query
        let unicodeQueries = ["🎵", "émojis", "ünicode", "symbols"]
        
        for query in unicodeQueries {
            let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
                try await search.search(query: query, field: .all)
            }, iterations: 50)
            
            // Then - Should meet performance SLA
            PerformanceTestHelpers.assertPerformanceSLA(
                metrics: metrics,
                maxDuration: 5.0,
                maxP95Duration: 0.1
            )
            
            print(PerformanceTestHelpers.generateReport(
                testName: "Search with Unicode '\(query)'",
                metrics: metrics,
                sla: 0.1
            ))
        }
        
        // Cleanup
        try await indexer.clear()
    }
}
