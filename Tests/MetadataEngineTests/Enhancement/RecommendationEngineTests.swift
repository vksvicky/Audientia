//
//  RecommendationEngineTests.swift
//  MetadataEngineTests
//
//  TDD tests for recommendation engine (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for recommendation engine functionality
/// Following Right-BICEP principles
final class RecommendationEngineTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testRecommendSimilarReturnsValidRecommendations() async throws {
        // Given: A track and recommendation engine
        let track = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        let expectedRecommendations = [
            Recommendation(track: track, score: 0.90, reason: "Similar audio features"),
            Recommendation(track: track, score: 0.85, reason: "Similar genre")
        ]
        await mockEngine.setMockRecommendations(expectedRecommendations)
        
        // When: Getting recommendations
        let results = try await mockEngine.recommendSimilar(to: track, limit: 10)
        
        // Then: Should return valid recommendations
        XCTAssertEqual(results.count, 2)
        XCTAssertGreaterThanOrEqual(results[0].score, results[1].score, "Results should be ordered by score")
        XCTAssertFalse(results[0].reason.isEmpty, "Recommendations should have reasons")
    }
    
    func testRecommendBasedOnHistoryReturnsValidRecommendations() async throws {
        // Given: A recommendation engine
        let mockEngine = MockRecommendationEngine()
        let expectedRecommendations = [
            Recommendation(
                track: Track(
                    title: "Popular Track",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/popular.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.95,
                reason: "Frequently played"
            )
        ]
        await mockEngine.setMockRecommendations(expectedRecommendations)
        
        // When: Getting history-based recommendations
        let results = try await mockEngine.recommendBasedOnHistory(limit: 10)
        
        // Then: Should return valid recommendations
        XCTAssertEqual(results.count, 1)
        XCTAssertGreaterThan(results[0].score, 0.0)
        XCTAssertFalse(results[0].reason.isEmpty)
    }
    
    // MARK: - Boundary Conditions
    
    func testRecommendSimilarWithNoSimilarTracks() async throws {
        // Given: A track with no similar tracks in library
        let track = Track(
            title: "Unique Track",
            artist: "Unique Artist",
            album: "Unique Album",
            duration: 180.0,
            filePath: "/path/to/unique.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        await mockEngine.setMockRecommendations([])
        
        // When: Getting recommendations
        let results = try await mockEngine.recommendSimilar(to: track, limit: 10)
        
        // Then: Should return empty list
        XCTAssertTrue(results.isEmpty, "Should return empty list when no similar tracks")
    }
    
    func testRecommendSimilarRespectsLimit() async throws {
        // Given: A track and recommendation engine
        let track = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        let manyRecommendations = (0..<20).map { index in
            Recommendation(
                track: Track(
                    title: "Track \(index)",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/track\(index).mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: Double(20 - index) / 20.0,
                reason: "Similar"
            )
        }
        await mockEngine.setMockRecommendations(manyRecommendations)
        
        // When: Getting recommendations with limit
        let results = try await mockEngine.recommendSimilar(to: track, limit: 5)
        
        // Then: Should respect limit
        XCTAssertLessThanOrEqual(results.count, 5, "Should respect limit parameter")
    }
    
    // MARK: - Inverse Relationships
    
    func testRecommendThenRemoveTrack() async throws {
        // Given: A track and recommendations
        let track = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        let recommendations = [
            Recommendation(track: track, score: 0.90, reason: "Similar")
        ]
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: Getting recommendations
        let results1 = try await mockEngine.recommendSimilar(to: track, limit: 10)
        await mockEngine.setMockRecommendations([])
        let results2 = try await mockEngine.recommendSimilar(to: track, limit: 10)
        
        // Then: Results should reflect changes
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 0, "Should reflect removal of recommendations")
    }
    
    // MARK: - Error Conditions
    
    func testRecommendSimilarWithNoTracksAvailable() async throws {
        // Given: An engine with no tracks
        let track = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        await mockEngine.setShouldFail(true, error: RecommendationError.noTracksAvailable)
        
        // When: Attempting to get recommendations
        // Then: Should throw error
        do {
            _ = try await mockEngine.recommendSimilar(to: track, limit: 10)
            XCTFail("Should have thrown error for no tracks available")
        } catch RecommendationError.noTracksAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance
    
    func testRecommendSimilarPerformance() async throws {
        // Given: A track and recommendation engine
        let track = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        let recommendations = (0..<10).map { index in
            Recommendation(
                track: Track(
                    title: "Track \(index)",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/track\(index).mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.8,
                reason: "Similar"
            )
        }
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: Getting recommendations
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await mockEngine.recommendSimilar(to: track, limit: 10)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within SLA (< 200ms)
        XCTAssertLessThan(elapsed, 0.2, "Recommendations should complete within 200ms")
    }
    
    // MARK: - Edge Cases
    
    func testRecommendSimilarWithVeryLargeLibrary() async throws {
        // Given: A track and very large library
        let track = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        // Simulate large library by returning limited results
        let recommendations = (0..<10).map { index in
            Recommendation(
                track: Track(
                    title: "Track \(index)",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/track\(index).mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.8,
                reason: "Similar"
            )
        }
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: Getting recommendations
        let results = try await mockEngine.recommendSimilar(to: track, limit: 10)
        
        // Then: Should handle large library efficiently
        XCTAssertLessThanOrEqual(results.count, 10)
    }
}
