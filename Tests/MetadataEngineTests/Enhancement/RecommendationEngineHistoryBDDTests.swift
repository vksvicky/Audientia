//
//  RecommendationEngineHistoryBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for history-based recommendations (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD scenarios for history-based recommendations
final class RecommendationEngineHistoryBDDTests: XCTestCase {
    
    private var engine: RecommendationEngine!
    private var mockSimilarityEngine: MockSimilarityEngine!
    private var listeningHistory: InMemoryListeningHistory!
    private var tracks: [Track]!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSimilarityEngine = MockSimilarityEngine()
        listeningHistory = InMemoryListeningHistory()
        engine = RecommendationEngine(
            similarityEngine: mockSimilarityEngine,
            listeningHistory: listeningHistory
        )
        
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
            ),
            Track(
                title: "Track 3",
                artist: "Artist C",
                album: "Album 3",
                duration: 220.0,
                filePath: "/path/to/track3.mp3",
                fileSize: 7000000,
                bitrate: 320,
                sampleRate: 44100
            )
        ]
        
        await engine.updateTrackLibrary(tracks)
    }
    
    override func tearDown() async throws {
        engine = nil
        mockSimilarityEngine = nil
        listeningHistory = nil
        tracks = nil
        try await super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsUserIWantRecommendationsBasedOnMyListeningHistory() async throws {
        // Scenario: As a user, I want recommendations based on my listening history
        // Given: I have played some tracks recently
        await listeningHistory.recordEvent(
            ListeningEvent(
                trackId: tracks[0].id,
                timestamp: Date(),
                playDuration: 180.0,
                wasSkipped: false
            )
        )
        
        // Set up similarity mock
        await mockSimilarityEngine.setMockSimilarityResults([
            SimilarityResult(track: tracks[1], similarity: 0.85),
            SimilarityResult(track: tracks[2], similarity: 0.75)
        ])
        
        // When: I request history-based recommendations
        let recommendations = try await engine.recommendBasedOnHistory(limit: 10)
        
        // Then: I should get recommendations similar to recently played tracks
        XCTAssertGreaterThan(recommendations.count, 0, "Should have recommendations based on history")
        XCTAssertTrue(
            recommendations.contains { $0.track.id == tracks[1].id || $0.track.id == tracks[2].id },
            "Should recommend tracks similar to recently played"
        )
    }
    
    func testAsUserIWantContextAwareRecommendations() async throws {
        // Scenario: As a user, I want context-aware recommendations
        // Given: I have played tracks at specific times
        let oneDayAgo = Date().addingTimeInterval(-86400)
        await listeningHistory.recordEvent(
            ListeningEvent(
                trackId: tracks[0].id,
                timestamp: oneDayAgo,
                playDuration: 180.0,
                wasSkipped: false
            )
        )
        
        // Set up similarity mock
        await mockSimilarityEngine.setMockSimilarityResults([
            SimilarityResult(track: tracks[1], similarity: 0.80),
            SimilarityResult(track: tracks[2], similarity: 0.70)
        ])
        
        // When: I request context-aware recommendations
        let recommendations = try await engine.recommendContextAware(limit: 10)
        
        // Then: I should get recommendations based on current context
        XCTAssertGreaterThan(recommendations.count, 0, "Should have context-aware recommendations")
        // Recommendations should include context information in reason
        if let firstRec = recommendations.first {
            XCTAssertFalse(firstRec.reason.isEmpty, "Recommendation should have context reason")
        }
    }
}
