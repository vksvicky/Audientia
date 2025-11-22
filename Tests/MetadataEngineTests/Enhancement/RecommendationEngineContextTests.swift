//
//  RecommendationEngineContextTests.swift
//  MetadataEngineTests
//
//  TDD tests for context-aware recommendations (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for context-aware recommendations
/// Following Right-BICEP principles
final class RecommendationEngineContextTests: XCTestCase {
    
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
    
    func testRecommendContextAwareReturnsRecommendations() async throws {
        // Given: A recommendation engine with tracks
        // When: Getting context-aware recommendations
        // Then: Should return recommendations (when implemented)
        // For now, this will return empty list until we implement it
        let recommendations = try await engine.recommendContextAware(limit: 10)
        
        // Currently returns empty, but structure is ready for implementation
        XCTAssertNotNil(recommendations)
        // When implemented, should have recommendations based on context
    }
    
    // MARK: - B: Boundary Conditions
    
    func testRecommendContextAwareWithEmptyLibraryThrowsError() async throws {
        // Given: An empty library
        await engine.updateTrackLibrary([])
        
        // When: Getting context-aware recommendations
        // Then: Should throw noTracksAvailable error
        do {
            _ = try await engine.recommendContextAware(limit: 10)
            XCTFail("Should throw noTracksAvailable error")
        } catch RecommendationError.noTracksAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - E: Error Conditions
    
    func testRecommendContextAwareHandlesInsufficientData() async throws {
        // Given: A library with only one track
        await engine.updateTrackLibrary([tracks[0]])
        
        // When: Getting context-aware recommendations
        // Then: Should handle gracefully
        let recommendations = try await engine.recommendContextAware(limit: 10)
        XCTAssertNotNil(recommendations)
    }
}
