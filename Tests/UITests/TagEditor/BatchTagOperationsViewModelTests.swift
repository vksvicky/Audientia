//
//  BatchTagOperationsViewModelTests.swift
//  UITests
//
//  TDD tests for BatchTagOperationsViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

// BatchTagOperationsViewModel is compiled into UITests target, no import needed

/// TDD tests for BatchTagOperationsViewModel
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class BatchTagOperationsViewModelTests: XCTestCase {
    
    fileprivate var viewModel: BatchTagOperationsViewModel!
    fileprivate var mockBatchOperations: MockBatchTagOperations!
    
    override func setUp() async throws {
        try await super.setUp()
        mockBatchOperations = MockBatchTagOperations()
        viewModel = BatchTagOperationsViewModel(batchOperations: mockBatchOperations)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockBatchOperations = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTrack(
        id: UUID = UUID(),
        title: String = "Test Title",
        artist: String = "Test Artist"
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track\(id.uuidString).mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test updating multiple tracks
    func testUpdateMultipleTracks() async throws {
        // Given - Multiple tracks with edits
        let tracks = (0..<5).map { _ in createTrack() }
        let fileURLs = tracks.map { URL(fileURLWithPath: $0.filePath) }
        
        mockBatchOperations.result = BatchTagOperationResult(
            successCount: 5,
            failureCount: 0,
            failures: []
        )
        
        // When - Update tracks
        try await viewModel.updateTracks(tracks: tracks, fileURLs: fileURLs)
        
        // Then - All tracks should be updated
        XCTAssertEqual(viewModel.result?.successCount, 5, "Should have 5 successes")
        XCTAssertEqual(viewModel.result?.failureCount, 0, "Should have 0 failures")
        XCTAssertTrue(mockBatchOperations.updateTracksCalled, "Batch operations should be called")
    }
    
    /// Test partial success scenario
    func testPartialSuccessScenario() async throws {
        // Given - Multiple tracks, some will fail
        let tracks = (0..<5).map { _ in createTrack() }
        let fileURLs = tracks.map { URL(fileURLWithPath: $0.filePath) }
        
        mockBatchOperations.result = BatchTagOperationResult(
            successCount: 3,
            failureCount: 2,
            failures: [
                BatchTagOperationFailure(
                    track: tracks[0],
                    fileURL: fileURLs[0],
                    error: TagWriterError.fileNotFound(fileURLs[0])
                ),
                BatchTagOperationFailure(
                    track: tracks[1],
                    fileURL: fileURLs[1],
                    error: TagWriterError.readOnlyFile(fileURLs[1])
                )
            ]
        )
        
        // When - Update tracks
        try await viewModel.updateTracks(tracks: tracks, fileURLs: fileURLs)
        
        // Then - Should have partial success
        XCTAssertEqual(viewModel.result?.successCount, 3, "Should have 3 successes")
        XCTAssertEqual(viewModel.result?.failureCount, 2, "Should have 2 failures")
        XCTAssertEqual(viewModel.result?.failures.count, 2, "Should have 2 failure details")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test updating zero tracks
    func testUpdateZeroTracks() async {
        // Given - Empty arrays
        let tracks: [Track] = []
        let fileURLs: [URL] = []
        
        // When/Then - Should throw error
        do {
            try await viewModel.updateTracks(tracks: tracks, fileURLs: fileURLs)
            XCTFail("Should have thrown error for empty arrays")
        } catch {
            XCTAssertNotNil(viewModel.lastError, "Last error should be set")
        }
    }
    
    /// Test updating single track
    func testUpdateSingleTrack() async throws {
        // Given - Single track
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        mockBatchOperations.result = BatchTagOperationResult(
            successCount: 1,
            failureCount: 0,
            failures: []
        )
        
        // When - Update track
        try await viewModel.updateTracks(tracks: [track], fileURLs: [fileURL])
        
        // Then - Should succeed
        XCTAssertEqual(viewModel.result?.successCount, 1, "Should have 1 success")
        XCTAssertEqual(viewModel.result?.failureCount, 0, "Should have 0 failures")
    }
    
    /// Test updating many tracks
    func testUpdateManyTracks() async throws {
        // Given - Many tracks (100)
        let tracks = (0..<100).map { _ in createTrack() }
        let fileURLs = tracks.map { URL(fileURLWithPath: $0.filePath) }
        
        mockBatchOperations.result = BatchTagOperationResult(
            successCount: 100,
            failureCount: 0,
            failures: []
        )
        
        // When - Update tracks
        try await viewModel.updateTracks(tracks: tracks, fileURLs: fileURLs)
        
        // Then - All should succeed
        XCTAssertEqual(viewModel.result?.successCount, 100, "Should have 100 successes")
        XCTAssertEqual(viewModel.result?.failureCount, 0, "Should have 0 failures")
    }
    
    // MARK: - Error Conditions
    
    /// Test handling batch operation errors
    func testHandleBatchOperationErrors() async {
        // Given - Tracks that will cause errors
        let tracks = (0..<3).map { _ in createTrack() }
        let fileURLs = tracks.map { URL(fileURLWithPath: $0.filePath) }
        
        mockBatchOperations.shouldThrow = true
        mockBatchOperations.operationError = BatchTagOperationsError.mismatchedArrays
        
        // When/Then - Should handle error
        do {
            try await viewModel.updateTracks(tracks: tracks, fileURLs: fileURLs)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(viewModel.lastError, "Last error should be set")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test batch update performance
    func testBatchUpdatePerformance() async throws {
        // Given - Many tracks
        let tracks = (0..<50).map { _ in createTrack() }
        let fileURLs = tracks.map { URL(fileURLWithPath: $0.filePath) }
        
        mockBatchOperations.result = BatchTagOperationResult(
            successCount: 50,
            failureCount: 0,
            failures: []
        )
        
        // When - Measure performance
        let iterations = 5
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            try await viewModel.updateTracks(tracks: tracks, fileURLs: fileURLs)
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        print("Average batch update time for 50 tracks: \(String(format: "%.2f", average * 1000))ms")
        
        // Then - Should complete in reasonable time
        XCTAssertLessThan(average, 5.0, "Batch update should complete in reasonable time")
    }
}

// MARK: - Mock Classes

/// Mock BatchTagOperations for testing
private final class MockBatchTagOperations: BatchTagOperationsProtocol, @unchecked Sendable {
    var result: BatchTagOperationResult?
    var shouldThrow = false
    var operationError: Error?
    var updateTracksCalled = false
    var lastTracks: [Track]?
    var lastFileURLs: [URL]?
    
    func updateTracks(tracks: [Track], fileURLs: [URL]) async throws -> BatchTagOperationResult {
        updateTracksCalled = true
        lastTracks = tracks
        lastFileURLs = fileURLs
        
        if shouldThrow {
            throw operationError ?? BatchTagOperationsError.noTracks
        }
        
        return result ?? BatchTagOperationResult(successCount: 0, failureCount: 0, failures: [])
    }
}
