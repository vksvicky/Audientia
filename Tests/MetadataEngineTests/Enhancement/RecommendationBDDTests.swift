//
//  RecommendationBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for recommendation engine (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for recommendation engine functionality
/// Following user-centric scenarios
final class RecommendationBDDTests: XCTestCase {
    
    // MARK: - User Scenario: Similar Tracks
    
    /// BDD: As a user, I want to see similar tracks based on current song
    func testUserWantsToSeeSimilarTracksBasedOnCurrentSong() async throws {
        // Given: A currently playing track
        let currentTrack = Track(
            title: "Current Song",
            artist: "Favorite Artist",
            album: "Favorite Album",
            duration: 180.0,
            filePath: "/path/to/current.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockRecommendationEngine()
        let similarTracks = [
            Recommendation(
                track: Track(
                    title: "Similar Song 1",
                    artist: "Favorite Artist",
                    album: "Another Album",
                    duration: 180.0,
                    filePath: "/path/to/similar1.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.90,
                reason: "Similar audio features and same artist"
            ),
            Recommendation(
                track: Track(
                    title: "Similar Song 2",
                    artist: "Other Artist",
                    album: "Other Album",
                    duration: 180.0,
                    filePath: "/path/to/similar2.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.85,
                reason: "Similar genre and mood"
            )
        ]
        await mockEngine.setMockRecommendations(similarTracks)
        
        // When: Getting recommendations for current track
        let recommendations = try await mockEngine.recommendSimilar(to: currentTrack, limit: 10)
        
        // Then: Should see similar tracks with reasons
        XCTAssertGreaterThanOrEqual(recommendations.count, 1, "Should have at least one recommendation")
        XCTAssertGreaterThan(recommendations[0].score, 0.0, "Recommendations should have scores")
        XCTAssertFalse(recommendations[0].reason.isEmpty, "Recommendations should have reasons")
    }
    
    /// BDD: As a user, I want to discover new music based on my listening history
    func testUserWantsToDiscoverMusicBasedOnHistory() async throws {
        // Given: User has listening history
        let mockEngine = MockRecommendationEngine()
        let recommendations = [
            Recommendation(
                track: Track(
                    title: "Recommended Track",
                    artist: "New Artist",
                    album: "New Album",
                    duration: 180.0,
                    filePath: "/path/to/recommended.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.95,
                reason: "Based on your frequent plays of similar artists"
            )
        ]
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: Getting history-based recommendations
        let results = try await mockEngine.recommendBasedOnHistory(limit: 10)
        
        // Then: Should see recommendations based on listening patterns
        XCTAssertEqual(results.count, 1)
        XCTAssertGreaterThan(results[0].score, 0.0)
        XCTAssertFalse(results[0].reason.isEmpty)
    }
    
    /// BDD: As a user, I want context-aware recommendations (time of day, activity)
    func testUserWantsContextAwareRecommendations() async throws {
        // Given: User wants recommendations for current context
        let mockEngine = MockRecommendationEngine()
        let recommendations = [
            Recommendation(
                track: Track(
                    title: "Morning Track",
                    artist: "Calm Artist",
                    album: "Calm Album",
                    duration: 180.0,
                    filePath: "/path/to/morning.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.88,
                reason: "Recommended for morning listening based on your patterns"
            )
        ]
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: Getting context-aware recommendations
        let results = try await mockEngine.recommendContextAware(limit: 10)
        
        // Then: Should see contextually relevant recommendations
        XCTAssertEqual(results.count, 1)
        XCTAssertGreaterThan(results[0].score, 0.0)
        XCTAssertTrue(results[0].reason.contains("morning") || results[0].reason.contains("context"), "Should include context in reason")
    }
    
    /// BDD: As a user, I want to see why tracks are recommended
    func testUserWantsToSeeRecommendationReasons() async throws {
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
            Recommendation(
                track: Track(
                    title: "Recommended",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/recommended.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.90,
                reason: "Similar audio features, same artist, similar mood"
            )
        ]
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: Getting recommendations
        let results = try await mockEngine.recommendSimilar(to: track, limit: 10)
        
        // Then: Each recommendation should have a clear reason
        for recommendation in results {
            XCTAssertFalse(recommendation.reason.isEmpty, "Each recommendation should have a reason")
            XCTAssertGreaterThan(recommendation.reason.count, 10, "Reason should be descriptive")
        }
    }
}
