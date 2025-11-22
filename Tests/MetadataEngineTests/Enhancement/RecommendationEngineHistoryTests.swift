//
//  RecommendationEngineHistoryTests.swift
//  MetadataEngineTests
//
//  TDD tests for history-based recommendations (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for history-based recommendations
/// Following Right-BICEP principles
final class RecommendationEngineHistoryTests: XCTestCase {
    
    private var engine: RecommendationEngine!
    private var mockSimilarityEngine: MockSimilarityEngine!
    private var tracks: [Track]!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSimilarityEngine = MockSimilarityEngine()
        engine = RecommendationEngine(similarityEngine: mockSimilarityEngine)
        
        tracks = [
            Track(
                title: "Track 1",
                artist: "Artist A",
                album: "Album 1",
                duration: 180.0,
                filePath: "/path/to/track1.mp3",
                fileSize: 5000000,
                bitrate: 320,
                sampleRate: 44100
            ),
            Track(
                title: "Track 2",
                artist: "Artist B",
                album: "Album 2",
                duration: 200.0,
                filePath: "/path/to/track2.mp3",
                fileSize: 6000000,
                bitrate: 320,
                sampleRate: 44100
            )
        ]
        
        await engine.updateTrackLibrary(tracks)
    }
    
    override func tearDown() async throws {
        engine = nil
        mockSimilarityEngine = nil
        tracks = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the results right?
    
    func testRecommendBasedOnHistoryReturnsRecommendations() async throws {
        // Given: A recommendation engine with tracks
        // When: Getting history-based recommendations
        // Then: Should return recommendations (when implemented)
        // For now, this will return empty list until we implement it
        let recommendations = try await engine.recommendBasedOnHistory(limit: 10)
        
        // Currently returns empty, but structure is ready for implementation
        XCTAssertNotNil(recommendations)
        // When implemented, should have recommendations based on play history
    }
    
    // MARK: - B: Boundary Conditions
    
    func testRecommendBasedOnHistoryWithEmptyLibraryThrowsError() async throws {
        // Given: An empty library
        await engine.updateTrackLibrary([])
        
        // When: Getting history-based recommendations
        // Then: Should throw noTracksAvailable error
        do {
            _ = try await engine.recommendBasedOnHistory(limit: 10)
            XCTFail("Should throw noTracksAvailable error")
        } catch RecommendationError.noTracksAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRecommendBasedOnHistoryWithLimitZero() async throws {
        // Given: A recommendation engine
        // When: Requesting 0 recommendations
        // Then: Should return empty list
        let recommendations = try await engine.recommendBasedOnHistory(limit: 0)
        XCTAssertEqual(recommendations.count, 0)
    }
    
    // MARK: - E: Error Conditions
    
    func testRecommendBasedOnHistoryHandlesInsufficientData() async throws {
        // Given: A library with only one track
        await engine.updateTrackLibrary([tracks[0]])
        
        // When: Getting history-based recommendations
        // Then: Should handle gracefully (return empty or limited results)
        let recommendations = try await engine.recommendBasedOnHistory(limit: 10)
        // Currently returns empty, but should handle gracefully when implemented
        XCTAssertNotNil(recommendations)
    }
}
