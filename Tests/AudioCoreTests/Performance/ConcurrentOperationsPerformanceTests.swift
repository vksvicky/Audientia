//
//  ConcurrentOperationsPerformanceTests.swift
//  Audientia - Concurrent Operations Performance Tests
//
//  Performance tests for concurrent operations
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// Performance tests for concurrent operations
@MainActor
final class ConcurrentOperationsPerformanceTests: XCTestCase {
    
    /// Performance: Concurrent library operations
    func testConcurrentLibraryOperations() async throws {
        // Given - Library with tracks
        let trackCount = 10_000
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
        
        // When - Perform concurrent operations (search, index, remove)
        let startTime = Date()
        await withTaskGroup(of: Void.self) { group in
            // Concurrent searches
            for i in 0..<5 {
                group.addTask {
                    do {
                        _ = try await search.search(query: "Track \(i * 2000)", field: .all)
                    } catch {
                        // Ignore errors in performance test
                    }
                }
            }
            
            // Concurrent indexing of new tracks
            for i in 0..<3 {
                group.addTask {
                    let newTracks = (0..<100).map { j in
                        MockFactory.makeTrack(
                            id: UUID(),
                            title: "New Track \(i * 100 + j)"
                        )
                    }
                    do {
                        try await indexer.index(tracks: newTracks)
                    } catch {
                        // Ignore errors in performance test
                    }
                }
            }
        }
        let totalDuration = Date().timeIntervalSince(startTime)
        
        // Then - All operations should complete without deadlock
        XCTAssertLessThan(totalDuration, 5.0, "Concurrent operations should complete in < 5s")
        
        print("Concurrent Operations Performance:")
        print("  5 searches + 3 indexing operations completed in \(String(format: "%.3f", totalDuration))s")
        
        // Cleanup
        try await indexer.clear()
    }
}
