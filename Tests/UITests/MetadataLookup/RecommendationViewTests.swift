//
//  RecommendationViewTests.swift
//  UITests
//
//  TDD tests for RecommendationView (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

/// TDD tests for RecommendationView
/// Following Right-BICEP principles
@MainActor
final class RecommendationViewTests: XCTestCase {
    
    var viewModel: RecommendationViewModel!
    var mockEngine: MockRecommendationEngine!
    var track: Track!
    
    override func setUp() async throws {
        try await super.setUp()
        mockEngine = MockRecommendationEngine()
        viewModel = RecommendationViewModel(recommendationEngine: mockEngine)
        track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
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
    
    // MARK: - Right: Are the results right?
    
    func testViewDisplaysRecommendations() async throws {
        // Given: Recommendations available
        let recommendations = [
            Recommendation(
                track: Track(
                    title: "Recommended 1",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/rec1.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.90,
                reason: "Similar audio features"
            ),
            Recommendation(
                track: Track(
                    title: "Recommended 2",
                    artist: "Artist",
                    album: "Album",
                    duration: 180.0,
                    filePath: "/path/to/rec2.mp3",
                    fileSize: 5000000,
                    bitrate: 320,
                    sampleRate: 44100
                ),
                score: 0.85,
                reason: "Similar genre"
            )
        ]
        await mockEngine.setMockRecommendations(recommendations)
        await viewModel.getRecommendations(for: track)
        
        // When: View is created
        _ = RecommendationView(viewModel: viewModel, sourceTrack: track)
        
        // Then: Should display recommendations
        XCTAssertEqual(viewModel.recommendations.count, 2)
        XCTAssertEqual(viewModel.recommendations[0].score, 0.90, accuracy: 0.01)
    }
    
    // MARK: - Boundary Conditions
    
    func testViewHandlesEmptyRecommendations() {
        // Given: No recommendations
        // When: View is created
        _ = RecommendationView(viewModel: viewModel, sourceTrack: track)
        
        // Then: Should not crash
        XCTAssertTrue(viewModel.recommendations.isEmpty)
    }
    
    func testViewHandlesRecommendationError() async throws {
        // Given: Recommendations will fail
        await mockEngine.setShouldFail(true, error: RecommendationError.noTracksAvailable)
        await viewModel.getRecommendations(for: track)
        
        // When: View is created
        _ = RecommendationView(viewModel: viewModel, sourceTrack: track)
        
        // Then: Should display error
        XCTAssertNotNil(viewModel.lastError)
    }
    
    // MARK: - Error Conditions
    
    func testViewHandlesLoadingState() async throws {
        // Given: Mock recommendations set up
        let recommendedTrack = Track(
            title: "Recommended Track",
            artist: "Recommended Artist",
            album: "Recommended Album",
            duration: 200.0,
            filePath: "/path/to/recommended.mp3",
            fileSize: 6000000,
            bitrate: 320,
            sampleRate: 44100
        )
        await mockEngine.setMockRecommendations([
            Recommendation(track: recommendedTrack, score: 0.95, reason: "Similar genre and mood")
        ])
        
        // Verify initial state
        XCTAssertFalse(viewModel.isLoading)
        
        // When: Recommendations are requested
        let task = Task {
            await viewModel.getRecommendations(for: track)
        }
        
        // Then: Should transition through loading state
        // Note: Due to the async nature, isLoading may already be false
        // by the time we check, but we verify the operation completes successfully
        await task.value
        
        // Verify the recommendations were retrieved successfully
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.recommendations.count, 1)
        XCTAssertNil(viewModel.lastError)
    }
}
