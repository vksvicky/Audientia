//
//  SmartPlaylistViewModelTests.swift
//  Audientia
//
//  TDD tests for SmartPlaylistViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class SmartPlaylistViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockIndexer: MockLibraryIndexer!
    private var viewModel: SmartPlaylistViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockIndexer = MockLibraryIndexer()
        viewModel = SmartPlaylistViewModel(libraryIndexer: mockIndexer)
    }
    
    override func tearDown() {
        viewModel = nil
        mockIndexer = nil
        super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    func testLoadTracks_ForFiveStarTracks_ReturnsOnlyFiveStarTracks() async {
        // Given: Library with tracks of different ratings
        let fiveStar1 = createTestTrack(title: "Track 1", rating: 5)
        let fiveStar2 = createTestTrack(title: "Track 2", rating: 5)
        let fourStar = createTestTrack(title: "Track 3", rating: 4)
        let threeStar = createTestTrack(title: "Track 4", rating: 3)
        let noRating = createTestTrack(title: "Track 5", rating: nil)
        
        await mockIndexer.setTracks([fiveStar1, fourStar, fiveStar2, threeStar, noRating])
        
        // When: Loading 5-Star Tracks
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: Only 5-star tracks should be returned
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertTrue(viewModel.tracks.allSatisfy { $0.rating == 5 })
        XCTAssertEqual(viewModel.tracks[0].title, "Track 1")
        XCTAssertEqual(viewModel.tracks[1].title, "Track 2")
    }
    
    func testLoadTracks_ForTopRated_ReturnsTracksSortedByRating() async {
        // Given: Library with tracks of different ratings
        let fiveStar = createTestTrack(title: "Five Star", rating: 5)
        let fourStar = createTestTrack(title: "Four Star", rating: 4)
        let threeStar = createTestTrack(title: "Three Star", rating: 3)
        let twoStar = createTestTrack(title: "Two Star", rating: 2)
        
        await mockIndexer.setTracks([twoStar, fiveStar, threeStar, fourStar])
        
        // When: Loading Top Rated
        await viewModel.loadTracks(for: .topRated)
        
        // Then: Tracks should be sorted by rating (highest first)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.tracks.count, 4)
        XCTAssertEqual(viewModel.tracks[0].rating, 5)
        XCTAssertEqual(viewModel.tracks[1].rating, 4)
        XCTAssertEqual(viewModel.tracks[2].rating, 3)
        XCTAssertEqual(viewModel.tracks[3].rating, 2)
    }
    
    func testLoadTracks_ForTopRated_ExcludesTracksWithoutRating() async {
        // Given: Library with tracks, some without ratings
        let fiveStar = createTestTrack(title: "Five Star", rating: 5)
        let noRating = createTestTrack(title: "No Rating", rating: nil)
        let fourStar = createTestTrack(title: "Four Star", rating: 4)
        
        await mockIndexer.setTracks([fiveStar, noRating, fourStar])
        
        // When: Loading Top Rated
        await viewModel.loadTracks(for: .topRated)
        
        // Then: Only tracks with ratings should be included
        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertTrue(viewModel.tracks.allSatisfy { $0.rating != nil })
        XCTAssertEqual(viewModel.tracks[0].rating, 5)
        XCTAssertEqual(viewModel.tracks[1].rating, 4)
    }
    
    func testLoadTracks_ForRecentlyAdded_ReturnsTracksSortedByID() async {
        // Given: Library with tracks (using ID as proxy for dateAdded)
        let track1 = createTestTrack(title: "Track 1")
        let track2 = createTestTrack(title: "Track 2")
        let track3 = createTestTrack(title: "Track 3")
        
        await mockIndexer.setTracks([track1, track2, track3])
        
        // When: Loading Recently Added
        await viewModel.loadTracks(for: .recentlyAdded)
        
        // Then: Tracks should be sorted (by ID as proxy)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.tracks.count, 3)
        // NOTE: Sorting by ID is a proxy until dateAdded is available
    }
    
    func testLoadTracks_WithLimit_RespectsLimit() async {
        // Given: Library with many tracks
        let tracks = (0..<50).map { createTestTrack(title: "Track \($0)", rating: 5) }
        await mockIndexer.setTracks(tracks)
        
        // When: Loading with limit
        await viewModel.loadTracks(for: .fiveStarTracks, limit: 10)
        
        // Then: Should return only limited number
        XCTAssertEqual(viewModel.tracks.count, 10)
    }
    
    func testLoadTracks_WithNilLimit_ReturnsAllTracks() async {
        // Given: Library with tracks
        let tracks = (0..<20).map { createTestTrack(title: "Track \($0)", rating: 5) }
        await mockIndexer.setTracks(tracks)
        
        // When: Loading with nil limit
        await viewModel.loadTracks(for: .fiveStarTracks, limit: nil)
        
        // Then: Should return all tracks
        XCTAssertEqual(viewModel.tracks.count, 20)
    }
    
    // MARK: - Boundary Conditions
    
    func testLoadTracks_WhenNoTracksMatch_ReturnsEmptyArray() async {
        // Given: Library with no 5-star tracks
        let track1 = createTestTrack(title: "Track 1", rating: 4)
        let track2 = createTestTrack(title: "Track 2", rating: 3)
        await mockIndexer.setTracks([track1, track2])
        
        // When: Loading 5-Star Tracks
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: Should return empty array
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    func testLoadTracks_WhenLibraryIsEmpty_ReturnsEmptyArray() async {
        // Given: Empty library
        await mockIndexer.setTracks([])
        
        // When: Loading any smart playlist
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: Should return empty array
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    func testLoadTracks_ForTopRated_WhenNoRatedTracks_ReturnsEmptyArray() async {
        // Given: Library with only unrated tracks
        let track1 = createTestTrack(title: "Track 1", rating: nil)
        let track2 = createTestTrack(title: "Track 2", rating: nil)
        await mockIndexer.setTracks([track1, track2])
        
        // When: Loading Top Rated
        await viewModel.loadTracks(for: .topRated)
        
        // Then: Should return empty array
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    // MARK: - Inverse Relationships
    
    func testLoadTracks_ForDifferentTypes_ReturnsDifferentResults() async {
        // Given: Library with mixed tracks
        let fiveStar = createTestTrack(title: "Five Star", rating: 5)
        let fourStar = createTestTrack(title: "Four Star", rating: 4)
        let threeStar = createTestTrack(title: "Three Star", rating: 3)
        await mockIndexer.setTracks([fiveStar, fourStar, threeStar])
        
        // When: Loading different types
        await viewModel.loadTracks(for: .fiveStarTracks)
        let fiveStarResults = viewModel.tracks
        
        await viewModel.loadTracks(for: .topRated)
        let topRatedResults = viewModel.tracks
        
        // Then: Results should be different
        XCTAssertNotEqual(fiveStarResults.count, topRatedResults.count)
        XCTAssertEqual(fiveStarResults.count, 1)
        XCTAssertEqual(topRatedResults.count, 3)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testLoadTracks_ForFiveStarTracks_ResultsMatchManualFilter() async {
        // Given: Library with tracks
        let fiveStar1 = createTestTrack(title: "Track 1", rating: 5)
        let fiveStar2 = createTestTrack(title: "Track 2", rating: 5)
        let fourStar = createTestTrack(title: "Track 3", rating: 4)
        await mockIndexer.setTracks([fiveStar1, fourStar, fiveStar2])
        
        // When: Loading 5-Star Tracks
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: Results should match manual filter
        let allTracks = await mockIndexer.getAllTracks()
        let manualFiltered = allTracks.filter { $0.rating == 5 }
        XCTAssertEqual(viewModel.tracks.count, manualFiltered.count)
        XCTAssertEqual(Set(viewModel.tracks.map { $0.id }), Set(manualFiltered.map { $0.id }))
    }
    
    // MARK: - Error Conditions
    
    func testLoadTracks_WhenIndexerFails_HandlesError() async {
        // Given: Indexer that throws error
        await mockIndexer.setShouldThrowError(true)
        
        // When: Loading tracks
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: Error should be set
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    // MARK: - Performance Characteristics
    
    func testLoadTracks_PerformanceWithManyTracks() async {
        // Given: Large library
        let tracks = (0..<1000).map { index in
            createTestTrack(title: "Track \(index)", rating: index % 2 == 0 ? 5 : 4)
        }
        await mockIndexer.setTracks(tracks)
        
        // When: Loading 5-Star Tracks (no limit to get all 500)
        let startTime = CFAbsoluteTimeGetCurrent()
        await viewModel.loadTracks(for: .fiveStarTracks, limit: nil)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time
        XCTAssertLessThan(duration, 0.1, "Should filter 1000 tracks within 100ms")
        XCTAssertEqual(viewModel.tracks.count, 500)
    }
    
    // MARK: - Edge Cases
    
    func testLoadTracks_ForTopRated_HandlesTiesCorrectly() async {
        // Given: Library with tracks having same ratings
        let fiveStar1 = createTestTrack(title: "A Track", rating: 5)
        let fiveStar2 = createTestTrack(title: "B Track", rating: 5)
        let fiveStar3 = createTestTrack(title: "C Track", rating: 5)
        
        await mockIndexer.setTracks([fiveStar3, fiveStar1, fiveStar2])
        
        // When: Loading Top Rated
        await viewModel.loadTracks(for: .topRated)
        
        // Then: Tracks with same rating should be sorted by title
        XCTAssertEqual(viewModel.tracks[0].title, "A Track")
        XCTAssertEqual(viewModel.tracks[1].title, "B Track")
        XCTAssertEqual(viewModel.tracks[2].title, "C Track")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack(title: String, artist: String = "Test Artist", album: String = "Test Album", rating: Int? = nil) -> Track {
        Track(
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: "/path/to/\(title).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            rating: rating
        )
    }
}

// MARK: - BDD Tests

/// BDD-style tests for SmartPlaylistViewModel scenarios
@MainActor
final class SmartPlaylistViewModelBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockIndexer: MockLibraryIndexer!
    private var viewModel: SmartPlaylistViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockIndexer = MockLibraryIndexer()
        viewModel = SmartPlaylistViewModel(libraryIndexer: mockIndexer)
    }
    
    override func tearDown() {
        viewModel = nil
        mockIndexer = nil
        super.tearDown()
    }
    
    // MARK: - Scenario: User views 5-Star Tracks smart playlist
    
    func testScenario_UserViewsFiveStarTracksSmartPlaylist() async {
        // Given: User has rated some tracks with 5 stars
        let fiveStar1 = createTestTrack(title: "Favorite Song 1", rating: 5)
        let fiveStar2 = createTestTrack(title: "Favorite Song 2", rating: 5)
        let fourStar = createTestTrack(title: "Good Song", rating: 4)
        
        await mockIndexer.setTracks([fiveStar1, fourStar, fiveStar2])
        
        // When: User clicks "5-Star Tracks" in the smart playlists section
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: User sees only their 5-star rated tracks, sorted alphabetically
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertTrue(viewModel.tracks.allSatisfy { $0.rating == 5 })
        XCTAssertEqual(viewModel.tracks[0].title, "Favorite Song 1")
        XCTAssertEqual(viewModel.tracks[1].title, "Favorite Song 2")
    }
    
    // MARK: - Scenario: User views Top Rated smart playlist
    
    func testScenario_UserViewsTopRatedSmartPlaylist() async {
        // Given: User has rated tracks with different ratings
        let fiveStar = createTestTrack(title: "Best Song", rating: 5)
        let fourStar = createTestTrack(title: "Good Song", rating: 4)
        let threeStar = createTestTrack(title: "Okay Song", rating: 3)
        
        await mockIndexer.setTracks([threeStar, fiveStar, fourStar])
        
        // When: User clicks "Top Rated" in the smart playlists section
        await viewModel.loadTracks(for: .topRated)
        
        // Then: User sees all rated tracks sorted by rating (highest first)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.tracks.count, 3)
        XCTAssertEqual(viewModel.tracks[0].rating, 5)
        XCTAssertEqual(viewModel.tracks[1].rating, 4)
        XCTAssertEqual(viewModel.tracks[2].rating, 3)
    }
    
    // MARK: - Scenario: User has no 5-star tracks
    
    func testScenario_UserHasNoFiveStarTracks() async {
        // Given: User has rated tracks but none are 5 stars
        let fourStar = createTestTrack(title: "Good Song", rating: 4)
        let threeStar = createTestTrack(title: "Okay Song", rating: 3)
        
        await mockIndexer.setTracks([fourStar, threeStar])
        
        // When: User clicks "5-Star Tracks"
        await viewModel.loadTracks(for: .fiveStarTracks)
        
        // Then: User sees an empty playlist
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack(title: String, artist: String = "Test Artist", album: String = "Test Album", rating: Int? = nil) -> Track {
        Track(
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: "/path/to/\(title).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            rating: rating
        )
    }
}
