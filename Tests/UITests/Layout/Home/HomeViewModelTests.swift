//
//  HomeViewModelTests.swift
//  Audientia
//
//  TDD tests for HomeViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@preconcurrency import MetadataEngine
@testable import Shared
import XCTest

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: HomeViewModel!
    private var mockListeningHistory: MockListeningHistory!
    private var mockLibraryIndexer: HomeMockLibraryIndexer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockListeningHistory = MockListeningHistory()
        mockLibraryIndexer = HomeMockLibraryIndexer()
        viewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockListeningHistory = nil
        mockLibraryIndexer = nil
        super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    func testRecentlyPlayedTracks_WhenHistoryExists_ReturnsCorrectTracks() async {
        // Given: Listening history with events at different times
        let track1 = createTestTrack(id: UUID(), title: "Track 1")
        let track2 = createTestTrack(id: UUID(), title: "Track 2")
        let track3 = createTestTrack(id: UUID(), title: "Track 3")
        
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        let now = Date()
        let event1 = ListeningEvent(trackId: track1.id, timestamp: now.addingTimeInterval(-300), playDuration: 120, wasSkipped: false)
        let event2 = ListeningEvent(trackId: track2.id, timestamp: now.addingTimeInterval(-200), playDuration: 180, wasSkipped: false)
        let event3 = ListeningEvent(trackId: track3.id, timestamp: now.addingTimeInterval(-100), playDuration: 90, wasSkipped: false)
        
        await mockListeningHistory.recordEvent(event1)
        await mockListeningHistory.recordEvent(event2)
        await mockListeningHistory.recordEvent(event3)
        
        // When: Loading recently played tracks
        await viewModel.loadRecentlyPlayed(limit: 3)
        
        // Then: Should return tracks in reverse chronological order (most recent first)
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertEqual(recentlyPlayed.count, 3, "Should return 3 recently played tracks")
        XCTAssertEqual(recentlyPlayed[0].id, track3.id, "Most recent track should be first")
        XCTAssertEqual(recentlyPlayed[1].id, track2.id, "Second most recent track should be second")
        XCTAssertEqual(recentlyPlayed[2].id, track1.id, "Oldest track should be last")
    }
    
    func testRecentlyPlayedTracks_WhenLimitIsLessThanAvailable_ReturnsOnlyLimit() async {
        // Given: More tracks than limit
        let tracks = (0..<10).map { createTestTrack(id: UUID(), title: "Track \($0)") }
        await mockLibraryIndexer.setTracks(tracks)
        
        for track in tracks {
            let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        
        // When: Loading with limit of 5
        await viewModel.loadRecentlyPlayed(limit: 5)
        
        // Then: Should return only 5 tracks
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertEqual(recentlyPlayed.count, 5, "Should return only 5 tracks when limit is 5")
    }
    
    func testRecentlyPlayedTracks_ExcludesSkippedTracks() async {
        // Given: Mix of played and skipped tracks
        let track1 = createTestTrack(id: UUID(), title: "Played Track")
        let track2 = createTestTrack(id: UUID(), title: "Skipped Track")
        
        await mockLibraryIndexer.setTracks([track1, track2])
        
        let playedEvent = ListeningEvent(trackId: track1.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
        let skippedEvent = ListeningEvent(trackId: track2.id, timestamp: Date(), playDuration: 5, wasSkipped: true)
        
        await mockListeningHistory.recordEvent(playedEvent)
        await mockListeningHistory.recordEvent(skippedEvent)
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should exclude skipped tracks
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertEqual(recentlyPlayed.count, 1, "Should exclude skipped tracks")
        XCTAssertEqual(recentlyPlayed[0].id, track1.id, "Should only include played track")
    }
    
    // MARK: - Boundary Conditions
    
    func testRecentlyPlayedTracks_WhenNoHistory_ReturnsEmpty() async {
        // Given: No listening history
        await mockLibraryIndexer.setTracks([])
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should return empty array
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertTrue(recentlyPlayed.isEmpty, "Should return empty array when no history")
    }
    
    func testRecentlyPlayedTracks_WhenTracksNotInIndexer_ExcludesMissingTracks() async {
        // Given: History events for tracks not in indexer
        let trackId = UUID()
        let event = ListeningEvent(trackId: trackId, timestamp: Date(), playDuration: 120, wasSkipped: false)
        await mockListeningHistory.recordEvent(event)
        await mockLibraryIndexer.setTracks([]) // No tracks in indexer
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should exclude tracks not found in indexer
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertTrue(recentlyPlayed.isEmpty, "Should exclude tracks not found in indexer")
    }
    
    func testRecentlyPlayedTracks_WhenLimitIsZero_ReturnsEmpty() async {
        // Given: History exists
        let track = createTestTrack(id: UUID(), title: "Track")
        await mockLibraryIndexer.setTracks([track])
        let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
        await mockListeningHistory.recordEvent(event)
        
        // When: Loading with limit of 0
        await viewModel.loadRecentlyPlayed(limit: 0)
        
        // Then: Should return empty array
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertTrue(recentlyPlayed.isEmpty, "Should return empty array when limit is 0")
    }
    
    // MARK: - Inverse Relationships
    
    func testLoadRecentlyPlayed_WhenCalledTwice_ReturnsConsistentResults() async {
        // Given: History with events
        let track1 = createTestTrack(id: UUID(), title: "Track 1")
        let track2 = createTestTrack(id: UUID(), title: "Track 2")
        await mockLibraryIndexer.setTracks([track1, track2])
        
        let event1 = ListeningEvent(trackId: track1.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
        let event2 = ListeningEvent(trackId: track2.id, timestamp: Date(), playDuration: 180, wasSkipped: false)
        await mockListeningHistory.recordEvent(event1)
        await mockListeningHistory.recordEvent(event2)
        
        // When: Loading twice
        await viewModel.loadRecentlyPlayed(limit: 10)
        let firstResult = viewModel.recentlyPlayedTracks
        await viewModel.loadRecentlyPlayed(limit: 10)
        let secondResult = viewModel.recentlyPlayedTracks
        
        // Then: Results should be consistent
        XCTAssertEqual(firstResult.count, secondResult.count, "Results should be consistent")
        XCTAssertEqual(firstResult.map { $0.id }, secondResult.map { $0.id }, "Track IDs should match")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testRecentlyPlayedTracks_OrderMatchesHistoryOrder() async {
        // Given: Events recorded at different times
        let track1 = createTestTrack(id: UUID(), title: "Track 1")
        let track2 = createTestTrack(id: UUID(), title: "Track 2")
        let track3 = createTestTrack(id: UUID(), title: "Track 3")
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        let now = Date()
        let event1 = ListeningEvent(trackId: track1.id, timestamp: now.addingTimeInterval(-300), playDuration: 120, wasSkipped: false)
        let event2 = ListeningEvent(trackId: track2.id, timestamp: now.addingTimeInterval(-200), playDuration: 180, wasSkipped: false)
        let event3 = ListeningEvent(trackId: track3.id, timestamp: now.addingTimeInterval(-100), playDuration: 90, wasSkipped: false)
        
        await mockListeningHistory.recordEvent(event1)
        await mockListeningHistory.recordEvent(event2)
        await mockListeningHistory.recordEvent(event3)
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Order should match history (most recent first)
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        let recentEvents = await mockListeningHistory.getRecentEvents(limit: 10)
        // recentEvents are already sorted newest-first, so map directly
        let eventTrackIds = recentEvents.map { $0.trackId }
        let trackIds = recentlyPlayed.map { $0.id }
        XCTAssertEqual(trackIds, eventTrackIds, "Track order should match history order")
    }
    
    // MARK: - Error Conditions
    
    func testLoadRecentlyPlayed_WhenListeningHistoryFails_GracefullyHandlesError() async {
        // Given: Mock that fails
        await mockListeningHistory.setShouldFailGetRecentEvents(true)
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should return empty array without crashing
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertTrue(recentlyPlayed.isEmpty, "Should return empty array on error")
    }
    
    func testLoadRecentlyPlayed_WhenLibraryIndexerFails_GracefullyHandlesError() async {
        // Given: Mock that fails
        await mockLibraryIndexer.setShouldFailGetTrack(true)
        
        let track = createTestTrack(id: UUID(), title: "Track")
        let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
        await mockListeningHistory.recordEvent(event)
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should handle error gracefully
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertTrue(recentlyPlayed.isEmpty, "Should return empty array when indexer fails")
    }
    
    // MARK: - Performance Characteristics
    
    func testLoadRecentlyPlayed_PerformanceWithManyTracks() async {
        // Given: Large number of tracks and events
        let tracks = (0..<1000).map { createTestTrack(id: UUID(), title: "Track \($0)") }
        await mockLibraryIndexer.setTracks(tracks)
        
        for track in tracks {
            let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        
        // When: Loading with limit
        let startTime = CFAbsoluteTimeGetCurrent()
        await viewModel.loadRecentlyPlayed(limit: 20)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time (< 1 second)
        XCTAssertLessThan(duration, 1.0, "Should load within 1 second for 1000 tracks")
        
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertEqual(recentlyPlayed.count, 20, "Should return correct limit")
    }
    
    // MARK: - Edge Cases
    
    func testRecentlyPlayedTracks_HandlesDuplicateTrackIds() async {
        // Given: Same track played multiple times
        let track = createTestTrack(id: UUID(), title: "Track")
        await mockLibraryIndexer.setTracks([track])
        
        let event1 = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
        let event2 = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 180, wasSkipped: false)
        await mockListeningHistory.recordEvent(event1)
        await mockListeningHistory.recordEvent(event2)
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should return unique tracks (most recent play)
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertEqual(recentlyPlayed.count, 1, "Should return unique tracks")
        XCTAssertEqual(recentlyPlayed[0].id, track.id, "Should return the track")
    }
    
    func testRecentlyPlayedTracks_HandlesVeryLongPlayDurations() async {
        // Given: Track with very long play duration
        let track = createTestTrack(id: UUID(), title: "Long Track")
        await mockLibraryIndexer.setTracks([track])
        
        let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 36000, wasSkipped: false) // 10 hours
        await mockListeningHistory.recordEvent(event)
        
        // When: Loading recently played
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: Should handle long durations correctly
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertEqual(recentlyPlayed.count, 1, "Should handle long play durations")
    }
    
    // MARK: - Most Played Tests
    
    func testLoadMostPlayed_WhenTracksHavePlayCounts_ReturnsSortedByPlayCount() async {
        // Given: Tracks with different play counts
        let track1 = createTestTrack(id: UUID(), title: "Track 1")
        let track2 = createTestTrack(id: UUID(), title: "Track 2")
        let track3 = createTestTrack(id: UUID(), title: "Track 3")
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        // Track 2 played 5 times, Track 1 played 3 times, Track 3 played 1 time
        for _ in 0..<5 {
            let event = ListeningEvent(trackId: track2.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        for _ in 0..<3 {
            let event = ListeningEvent(trackId: track1.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        let event = ListeningEvent(trackId: track3.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
        await mockListeningHistory.recordEvent(event)
        
        // When: Loading most played
        await viewModel.loadMostPlayed(limit: 10)
        
        // Then: Should be sorted by play count (descending)
        let mostPlayed = viewModel.mostPlayedTracks
        XCTAssertEqual(mostPlayed.count, 3)
        XCTAssertEqual(mostPlayed[0].id, track2.id, "Track with highest play count should be first")
        XCTAssertEqual(mostPlayed[1].id, track1.id, "Track with second highest play count should be second")
        XCTAssertEqual(mostPlayed[2].id, track3.id, "Track with lowest play count should be last")
    }
    
    func testLoadMostPlayed_WhenNoTracksPlayed_ReturnsEmptyArray() async {
        // Given: Tracks but no play history
        let track = createTestTrack(id: UUID(), title: "Track")
        await mockLibraryIndexer.setTracks([track])
        
        // When: Loading most played
        await viewModel.loadMostPlayed(limit: 10)
        
        // Then: Should return empty array
        let mostPlayed = viewModel.mostPlayedTracks
        XCTAssertTrue(mostPlayed.isEmpty)
    }
    
    func testLoadMostPlayed_RespectsLimit() async {
        // Given: Many tracks with play counts
        let tracks = (0..<20).map { createTestTrack(id: UUID(), title: "Track \($0)") }
        await mockLibraryIndexer.setTracks(tracks)
        
        // Record play events for all tracks
        for track in tracks {
            let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        
        // When: Loading with limit
        await viewModel.loadMostPlayed(limit: 5)
        
        // Then: Should return only limit number of tracks
        let mostPlayed = viewModel.mostPlayedTracks
        XCTAssertEqual(mostPlayed.count, 5)
    }
    
    func testLoadMostPlayed_ExcludesSkippedTracks() async {
        // Given: Track that was only skipped
        let track = createTestTrack(id: UUID(), title: "Skipped Track")
        await mockLibraryIndexer.setTracks([track])
        
        let skippedEvent = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 5, wasSkipped: true)
        await mockListeningHistory.recordEvent(skippedEvent)
        
        // When: Loading most played
        await viewModel.loadMostPlayed(limit: 10)
        
        // Then: Should not include skipped tracks
        let mostPlayed = viewModel.mostPlayedTracks
        XCTAssertTrue(mostPlayed.isEmpty, "Should not include tracks that were only skipped")
    }
    
    func testLoadMostPlayed_HandlesTiesBySortingAlphabetically() async {
        // Given: Tracks with same play count
        let track1 = createTestTrack(id: UUID(), title: "B Track")
        let track2 = createTestTrack(id: UUID(), title: "A Track")
        let track3 = createTestTrack(id: UUID(), title: "C Track")
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        // All played once
        for track in [track1, track2, track3] {
            let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 120, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        
        // When: Loading most played
        await viewModel.loadMostPlayed(limit: 10)
        
        // Then: Should sort alphabetically for ties
        let mostPlayed = viewModel.mostPlayedTracks
        XCTAssertEqual(mostPlayed.count, 3)
        XCTAssertEqual(mostPlayed[0].title, "A Track", "Should sort alphabetically")
        XCTAssertEqual(mostPlayed[1].title, "B Track")
        XCTAssertEqual(mostPlayed[2].title, "C Track")
    }
    
    func testLoadMostPlayed_WhenListeningHistoryIsNil_ReturnsEmptyArray() async {
        // Given: ViewModel without listening history
        let viewModelWithoutHistory = HomeViewModel(
            listeningHistory: nil,
            libraryIndexer: mockLibraryIndexer
        )
        
        // When: Loading most played
        await viewModelWithoutHistory.loadMostPlayed(limit: 10)
        
        // Then: Should return empty array
        let mostPlayed = viewModelWithoutHistory.mostPlayedTracks
        XCTAssertTrue(mostPlayed.isEmpty)
    }
    
    // MARK: - Favourites Tests
    
    func testLoadFavourites_WhenTracksHaveRatings_ReturnsSortedByRating() async {
        // Given: Tracks with different ratings
        let track1 = createTestTrack(id: UUID(), title: "Track 1", rating: 5)
        let track2 = createTestTrack(id: UUID(), title: "Track 2", rating: 4)
        let track3 = createTestTrack(id: UUID(), title: "Track 3", rating: 3) // Below minimum
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        // When: Loading favourites (min rating 4)
        await viewModel.loadFavourites(limit: 10, minRating: 4)
        
        // Then: Should return only tracks with rating >= 4, sorted by rating
        let favourites = viewModel.favouriteTracks
        XCTAssertEqual(favourites.count, 2, "Should only include tracks with rating >= 4")
        XCTAssertEqual(favourites[0].id, track1.id, "5-star track should be first")
        XCTAssertEqual(favourites[1].id, track2.id, "4-star track should be second")
        XCTAssertFalse(favourites.contains { $0.id == track3.id }, "3-star track should not be included")
    }
    
    func testLoadFavourites_WhenNoRatedTracks_ReturnsEmptyArray() async {
        // Given: Tracks without ratings
        let track1 = createTestTrack(id: UUID(), title: "Track 1", rating: nil)
        let track2 = createTestTrack(id: UUID(), title: "Track 2", rating: nil)
        await mockLibraryIndexer.setTracks([track1, track2])
        
        // When: Loading favourites
        await viewModel.loadFavourites(limit: 10)
        
        // Then: Should return empty array
        let favourites = viewModel.favouriteTracks
        XCTAssertTrue(favourites.isEmpty)
    }
    
    func testLoadFavourites_RespectsLimit() async {
        // Given: Many tracks with high ratings
        let tracks = (0..<20).map { createTestTrack(id: UUID(), title: "Track \($0)", rating: 5) }
        await mockLibraryIndexer.setTracks(tracks)
        
        // When: Loading with limit
        await viewModel.loadFavourites(limit: 5)
        
        // Then: Should return only limit number of tracks
        let favourites = viewModel.favouriteTracks
        XCTAssertEqual(favourites.count, 5)
    }
    
    func testLoadFavourites_RespectsMinRating() async {
        // Given: Tracks with various ratings
        let track1 = createTestTrack(id: UUID(), title: "Track 1", rating: 5)
        let track2 = createTestTrack(id: UUID(), title: "Track 2", rating: 4)
        let track3 = createTestTrack(id: UUID(), title: "Track 3", rating: 3)
        let track4 = createTestTrack(id: UUID(), title: "Track 4", rating: 2)
        await mockLibraryIndexer.setTracks([track1, track2, track3, track4])
        
        // When: Loading with minRating 5
        await viewModel.loadFavourites(limit: 10, minRating: 5)
        
        // Then: Should only include 5-star tracks
        let favourites = viewModel.favouriteTracks
        XCTAssertEqual(favourites.count, 1)
        XCTAssertEqual(favourites[0].id, track1.id)
    }
    
}
