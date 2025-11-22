//
//  RecommendationViewBDDTests.swift
//  UITests
//
//  BDD tests for RecommendationView (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

/// BDD tests for RecommendationView
/// Following user-centric scenarios
@MainActor
final class RecommendationViewBDDTests: XCTestCase {
    
    var viewModel: RecommendationViewModel!
    var mockEngine: MockRecommendationEngine!
    var track: Track!
    
    override func setUp() async throws {
        try await super.setUp()
        mockEngine = MockRecommendationEngine()
        viewModel = RecommendationViewModel(recommendationEngine: mockEngine)
        track = Track(
            title: "Current Song",
            artist: "Favorite Artist",
            album: "Favorite Album",
            duration: 180.0,
            filePath: "/path/to/current.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockEngine = nil
        track = nil
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Viewing Recommendations
    
    /// BDD: As a user, I want to see similar tracks based on current song
    func testUserWantsToSeeSimilarTracksBasedOnCurrentSong() async throws {
        // Given: A currently playing track and recommendations available
        let recommendations = [
            Recommendation(
                track: Track(
                    title: "Similar Song",
                    artist: "Favorite Artist",
                    album: "Another Album",
                    duration: 180.0,
                    filePath: "/path/to/similar.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.90,
                reason: "Similar audio features and same artist"
            )
        ]
        await mockEngine.setMockRecommendations(recommendations)
        
        // When: User requests recommendations for current track
        await viewModel.getRecommendations(for: track)
        
        // Then: User should see similar tracks with reasons
        XCTAssertEqual(viewModel.recommendations.count, 1)
        XCTAssertGreaterThan(viewModel.recommendations[0].score, 0.0)
        XCTAssertFalse(viewModel.recommendations[0].reason.isEmpty)
    }
    
    /// BDD: As a user, I want to see why tracks are recommended
    func testUserWantsToSeeRecommendationReasons() async throws {
        // Given: Recommendations with reasons
        let recommendations = [
            Recommendation(
                track: Track(
                    title: "Recommended Track",
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
        await viewModel.getRecommendations(for: track)
        
        // When: User views recommendations
        // Then: Each recommendation should have a clear reason
        for recommendation in viewModel.recommendations {
            XCTAssertFalse(recommendation.reason.isEmpty, "Each recommendation should have a reason")
            XCTAssertGreaterThan(recommendation.reason.count, 10, "Reason should be descriptive")
        }
    }
    
    /// BDD: As a user, I want to discover new music based on my listening history
    func testUserWantsToDiscoverMusicBasedOnHistory() async throws {
        // Given: User has listening history
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
        
        // When: User requests history-based recommendations
        await viewModel.getHistoryBasedRecommendations()
        
        // Then: User should see recommendations based on listening patterns
        XCTAssertEqual(viewModel.recommendations.count, 1)
        XCTAssertGreaterThan(viewModel.recommendations[0].score, 0.0)
        XCTAssertFalse(viewModel.recommendations[0].reason.isEmpty)
    }
}
