//
//  HomeViewModelBDDTests.swift
//  Audientia
//
//  BDD-style tests for HomeViewModel user scenarios
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@preconcurrency import MetadataEngine
@testable import Shared
import XCTest

/// BDD-style tests for HomeViewModel user scenarios
@MainActor
final class HomeViewModelBDDTests: XCTestCase {
    
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
    
    // MARK: - Scenario: User views recently played tracks
    
    func testScenario_UserViewsRecentlyPlayedTracks() async {
        // Given: User has played several tracks
        let track1 = createTestTrack(id: UUID(), title: "Song 1", artist: "Artist A")
        let track2 = createTestTrack(id: UUID(), title: "Song 2", artist: "Artist B")
        let track3 = createTestTrack(id: UUID(), title: "Song 3", artist: "Artist C")
        
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        let event1 = ListeningEvent(trackId: track1.id, timestamp: Date().addingTimeInterval(-3600), playDuration: 180, wasSkipped: false)
        let event2 = ListeningEvent(trackId: track2.id, timestamp: Date().addingTimeInterval(-1800), playDuration: 200, wasSkipped: false)
        let event3 = ListeningEvent(trackId: track3.id, timestamp: Date(), playDuration: 150, wasSkipped: false)
        
        await mockListeningHistory.recordEvent(event1)
        await mockListeningHistory.recordEvent(event2)
        await mockListeningHistory.recordEvent(event3)
        
        // When: User opens the Home tab
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: User sees their recently played tracks in reverse chronological order
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertGreaterThan(recentlyPlayed.count, 0, "User should see recently played tracks")
        XCTAssertEqual(recentlyPlayed.count, 3, "User should see all 3 recently played tracks")
        XCTAssertEqual(recentlyPlayed[0].title, "Song 3", "Most recent track should appear first")
        XCTAssertEqual(recentlyPlayed[1].title, "Song 2", "Second most recent track should appear second")
        XCTAssertEqual(recentlyPlayed[2].title, "Song 1", "Oldest track should appear last")
    }
    
    // MARK: - Scenario: User views favourite tracks
    
    func testScenario_UserViewsFavouriteTracks() async {
        // Given: User has rated several tracks
        let track1 = createTestTrack(id: UUID(), title: "Favorite Song", artist: "Artist A", rating: 5)
        let track2 = createTestTrack(id: UUID(), title: "Liked Song", artist: "Artist B", rating: 4)
        let track3 = createTestTrack(id: UUID(), title: "Okay Song", artist: "Artist C", rating: 3)
        
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        // When: User opens the Home tab
        await viewModel.loadFavourites(limit: 10)
        
        // Then: User sees their favourite tracks (4+ stars) sorted by rating
        let favourites = viewModel.favouriteTracks
        XCTAssertGreaterThan(favourites.count, 0, "User should see favourite tracks")
        XCTAssertEqual(favourites.count, 2, "User should see tracks with 4+ stars")
        XCTAssertEqual(favourites[0].title, "Favorite Song", "5-star track should appear first")
        XCTAssertEqual(favourites[1].title, "Liked Song", "4-star track should appear second")
        XCTAssertFalse(favourites.contains { $0.title == "Okay Song" }, "3-star track should not appear")
    }
    
    // MARK: - Scenario: User views recently added tracks
    
    func testScenario_UserViewsRecentlyAddedTracks() async {
        // Given: User has added tracks to their library
        let track1 = createTestTrack(id: UUID(), title: "New Song 1", artist: "Artist A")
        let track2 = createTestTrack(id: UUID(), title: "New Song 2", artist: "Artist B")
        let track3 = createTestTrack(id: UUID(), title: "New Song 3", artist: "Artist C")
        
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        // When: User opens the Home tab
        await viewModel.loadRecentlyAdded(limit: 10)
        
        // Then: User sees their recently added tracks
        let recentlyAdded = viewModel.recentlyAddedTracks
        XCTAssertGreaterThan(recentlyAdded.count, 0, "User should see recently added tracks")
        XCTAssertEqual(recentlyAdded.count, 3, "User should see all 3 recently added tracks")
    }
    
    // MARK: - Scenario: User refreshes home content
    
    func testScenario_UserRefreshesHomeContent() async {
        // Given: User has tracks in library and listening history
        let track = createTestTrack(id: UUID(), title: "Track", artist: "Artist")
        await mockLibraryIndexer.setTracks([track])
        
        let event = ListeningEvent(trackId: track.id, timestamp: Date(), playDuration: 180, wasSkipped: false)
        await mockListeningHistory.recordEvent(event)
        
        // When: User refreshes the home content
        await viewModel.refresh()
        
        // Then: Both recently played and recently added sections are updated
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        let recentlyAdded = viewModel.recentlyAddedTracks
        
        XCTAssertGreaterThan(recentlyPlayed.count, 0, "Recently played should be loaded after refresh")
        XCTAssertGreaterThan(recentlyAdded.count, 0, "Recently added should be loaded after refresh")
    }
    
    // MARK: - Scenario: User has no listening history service
    
    func testScenario_UserHasNoListeningHistoryService() async {
        // Given: Listening history service is not available
        viewModel = HomeViewModel(
            listeningHistory: nil,
            libraryIndexer: mockLibraryIndexer
        )
        
        // When: User tries to view recently played tracks
        await viewModel.loadRecentlyPlayed(limit: 10)
        
        // Then: User sees an empty section (graceful degradation)
        let recentlyPlayed = viewModel.recentlyPlayedTracks
        XCTAssertTrue(recentlyPlayed.isEmpty, "Should gracefully handle missing listening history")
    }
    
    // MARK: - Scenario: User views most played tracks
    
    func testScenario_UserViewsMostPlayedTracks() async {
        // Given: User has played several tracks with different frequencies
        let track1 = createTestTrack(id: UUID(), title: "Favorite Song", artist: "Artist A")
        let track2 = createTestTrack(id: UUID(), title: "Popular Song", artist: "Artist B")
        let track3 = createTestTrack(id: UUID(), title: "Rare Song", artist: "Artist C")
        
        await mockLibraryIndexer.setTracks([track1, track2, track3])
        
        // Track 1 played 10 times, Track 2 played 5 times, Track 3 played 1 time
        for _ in 0..<10 {
            let event = ListeningEvent(trackId: track1.id, timestamp: Date(), playDuration: 180, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        for _ in 0..<5 {
            let event = ListeningEvent(trackId: track2.id, timestamp: Date(), playDuration: 200, wasSkipped: false)
            await mockListeningHistory.recordEvent(event)
        }
        let event = ListeningEvent(trackId: track3.id, timestamp: Date(), playDuration: 150, wasSkipped: false)
        await mockListeningHistory.recordEvent(event)
        
        // When: User opens the Home tab
        await viewModel.loadMostPlayed(limit: 10)
        
        // Then: User sees their most played tracks sorted by play count
        let mostPlayed = viewModel.mostPlayedTracks
        XCTAssertGreaterThan(mostPlayed.count, 0, "User should see most played tracks")
        XCTAssertEqual(mostPlayed.count, 3, "User should see all 3 tracks")
        XCTAssertEqual(mostPlayed[0].title, "Favorite Song", "Most played track should appear first")
        XCTAssertEqual(mostPlayed[1].title, "Popular Song", "Second most played should appear second")
        XCTAssertEqual(mostPlayed[2].title, "Rare Song", "Least played should appear last")
    }
}
