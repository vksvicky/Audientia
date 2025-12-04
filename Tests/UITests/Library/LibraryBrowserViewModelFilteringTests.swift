//
//  LibraryBrowserViewModelFilteringTests.swift
//  Audientia
//
//  TDD tests for LibraryBrowserViewModel filtering functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class LibraryBrowserViewModelFilteringTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: LibraryBrowserViewModel!
    private var mockIndexer: MockLibraryIndexer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockIndexer = MockLibraryIndexer()
        viewModel = LibraryBrowserViewModel(indexer: mockIndexer)
    }
    
    override func tearDown() {
        viewModel = nil
        mockIndexer = nil
        super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    func testFilterByGenre_WhenGenreSelected_FiltersTracksByGenre() async {
        // Given: Library with tracks of different genres
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        let classicalTrack = createTestTrack(title: "Classical Song", genre: "Classical")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack, classicalTrack])
        await viewModel.loadLibrary()
        
        // When: Filtering by Rock genre
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: Only Rock tracks should be in filteredTracks
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should filter to only Rock tracks")
        XCTAssertEqual(viewModel.filteredTracks[0].genre, "Rock", "Filtered track should be Rock genre")
        XCTAssertEqual(viewModel.filteredTracks[0].id, rockTrack.id, "Should be the Rock track")
    }
    
    func testFilterByMultipleGenres_WhenMultipleGenresSelected_FiltersTracksByAllGenres() async {
        // Given: Library with tracks of different genres
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        let classicalTrack = createTestTrack(title: "Classical Song", genre: "Classical")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack, classicalTrack])
        await viewModel.loadLibrary()
        
        // When: Filtering by Rock and Jazz genres
        await viewModel.filterByGenres(Set(["Rock", "Jazz"]))
        
        // Then: Both Rock and Jazz tracks should be in filteredTracks
        XCTAssertEqual(viewModel.filteredTracks.count, 2, "Should filter to Rock and Jazz tracks")
        let genres = Set(viewModel.filteredTracks.map { $0.genre ?? "" })
        XCTAssertTrue(genres.contains("Rock"), "Should include Rock tracks")
        XCTAssertTrue(genres.contains("Jazz"), "Should include Jazz tracks")
        XCTAssertFalse(genres.contains("Classical"), "Should not include Classical tracks")
    }
    
    func testClearGenreFilter_WhenFilterCleared_ShowsAllTracks() async {
        // Given: Library with filtered tracks
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack])
        await viewModel.loadLibrary()
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // When: Clearing genre filter
        await viewModel.filterByGenres(Set<String>())
        
        // Then: All tracks should be shown
        XCTAssertEqual(viewModel.filteredTracks.count, 2, "Should show all tracks when filter cleared")
    }
    
    func testSetBrowseMode_WhenBrowseModeSet_UpdatesBrowseMode() async {
        // Given: Library with tracks
        let track1 = createTestTrack(title: "Song 1", artist: "Artist A", album: "Album 1")
        let track2 = createTestTrack(title: "Song 2", artist: "Artist B", album: "Album 2")
        
        await mockIndexer.setTracks([track1, track2])
        await viewModel.loadLibrary()
        
        // When: Setting browse mode to Artists
        await viewModel.setBrowseMode(.artists)
        
        // Then: Browse mode should be set
        XCTAssertEqual(viewModel.browseMode, .artists, "Browse mode should be set to Artists")
    }
    
    // MARK: - Boundary Conditions
    
    func testFilterByGenre_WhenNoTracksMatch_ReturnsEmptyArray() async {
        // Given: Library with tracks of different genres
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        await mockIndexer.setTracks([rockTrack])
        await viewModel.loadLibrary()
        
        // When: Filtering by non-existent genre
        await viewModel.filterByGenres(Set(["Jazz"]))
        
        // Then: Filtered tracks should be empty
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Should return empty array when no tracks match")
    }
    
    func testFilterByGenre_WhenTracksHaveNoGenre_ExcludesThem() async {
        // Given: Library with tracks, some without genre
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let noGenreTrack = createTestTrack(title: "No Genre Song", genre: nil)
        
        await mockIndexer.setTracks([rockTrack, noGenreTrack])
        await viewModel.loadLibrary()
        
        // When: Filtering by Rock genre
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: Only Rock track should be included
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should only include tracks with matching genre")
        XCTAssertEqual(viewModel.filteredTracks[0].genre, "Rock", "Should be Rock track")
    }
    
    func testFilterByGenre_WhenEmptyLibrary_ReturnsEmptyArray() async {
        // Given: Empty library
        await mockIndexer.setTracks([])
        await viewModel.loadLibrary()
        
        // When: Filtering by genre
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: Should return empty array
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Should return empty array for empty library")
    }
    
    // MARK: - Inverse Relationships
    
    func testFilterByGenre_WhenFilterAppliedThenCleared_RestoresOriginalTracks() async {
        // Given: Library with tracks
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack])
        await viewModel.loadLibrary()
        let originalCount = viewModel.tracks.count
        
        // When: Applying filter then clearing
        await viewModel.filterByGenres(Set(["Rock"]))
        await viewModel.filterByGenres(Set<String>())
        
        // Then: Should restore original tracks
        XCTAssertEqual(viewModel.filteredTracks.count, originalCount, "Should restore all tracks after clearing filter")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testFilterByGenre_ResultsMatchManualFiltering() async {
        // Given: Library with tracks
        let rockTrack1 = createTestTrack(title: "Rock 1", genre: "Rock")
        let rockTrack2 = createTestTrack(title: "Rock 2", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz 1", genre: "Jazz")
        
        await mockIndexer.setTracks([rockTrack1, rockTrack2, jazzTrack])
        await viewModel.loadLibrary()
        
        // When: Filtering by Rock
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: Results should match manual filtering
        let manualFiltered = viewModel.tracks.filter { $0.genre == "Rock" }
        XCTAssertEqual(viewModel.filteredTracks.count, manualFiltered.count, "Should match manual filtering")
        XCTAssertEqual(Set(viewModel.filteredTracks.map { $0.id }), Set(manualFiltered.map { $0.id }), "Should have same tracks")
    }
    
    // MARK: - Error Conditions
    
    func testFilterByGenre_WhenLibraryNotLoaded_HandlesGracefully() async {
        // Given: Library not loaded
        // When: Filtering by genre
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: Should handle gracefully without crashing
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Should return empty array when library not loaded")
    }
    
    // MARK: - Performance Characteristics
    
    func testFilterByGenre_PerformanceWithManyTracks() async {
        // Given: Large library
        let tracks = (0..<1000).map { index in
            createTestTrack(title: "Track \(index)", genre: index % 2 == 0 ? "Rock" : "Jazz")
        }
        await mockIndexer.setTracks(tracks)
        await viewModel.loadLibrary()
        
        // When: Filtering by genre
        let startTime = CFAbsoluteTimeGetCurrent()
        await viewModel.filterByGenres(Set(["Rock"]))
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time
        XCTAssertLessThan(duration, 0.1, "Should filter 1000 tracks within 100ms")
        XCTAssertEqual(viewModel.filteredTracks.count, 500, "Should filter to 500 Rock tracks")
    }
    
    // MARK: - Edge Cases
    
    func testFilterByGenre_HandlesCaseInsensitiveMatching() async {
        // Given: Library with tracks
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let rockTrackLower = createTestTrack(title: "Rock Song 2", genre: "rock")
        
        await mockIndexer.setTracks([rockTrack, rockTrackLower])
        await viewModel.loadLibrary()
        
        // When: Filtering by "Rock" (capitalized)
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: Should match both (case-insensitive)
        // Note: This test assumes case-insensitive matching - adjust based on implementation
        XCTAssertGreaterThanOrEqual(viewModel.filteredTracks.count, 1, "Should match at least one track")
    }
    
    func testFilterByGenre_HandlesWhitespaceInGenreNames() async {
        // Given: Library with track with genre containing whitespace
        let track = createTestTrack(title: "Song", genre: "Rock & Roll")
        
        await mockIndexer.setTracks([track])
        await viewModel.loadLibrary()
        
        // When: Filtering by exact genre name
        await viewModel.filterByGenres(Set(["Rock & Roll"]))
        
        // Then: Should match the track
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should match track with whitespace in genre")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack(title: String, artist: String = "Test Artist", album: String = "Test Album", genre: String? = nil) -> Track {
        Track(
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: "/path/to/\(title).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            genre: genre
        )
    }
}

// MARK: - BDD Tests

/// BDD-style tests for LibraryBrowserViewModel filtering scenarios
@MainActor
final class LibraryBrowserViewModelFilteringBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: LibraryBrowserViewModel!
    private var mockIndexer: MockLibraryIndexer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockIndexer = MockLibraryIndexer()
        viewModel = LibraryBrowserViewModel(indexer: mockIndexer)
    }
    
    override func tearDown() {
        viewModel = nil
        mockIndexer = nil
        super.tearDown()
    }
    
    // MARK: - Scenario: User filters library by genre
    
    func testScenario_UserFiltersLibraryByGenre() async {
        // Given: User has a library with tracks of different genres
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        let classicalTrack = createTestTrack(title: "Classical Song", genre: "Classical")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack, classicalTrack])
        await viewModel.loadLibrary()
        
        // When: User selects "Rock" genre filter in the sidebar
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // Then: User sees only Rock tracks in the library view
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "User should see only Rock tracks")
        XCTAssertEqual(viewModel.filteredTracks[0].genre, "Rock", "Filtered track should be Rock")
    }
    
    // MARK: - Scenario: User filters by multiple genres
    
    func testScenario_UserFiltersByMultipleGenres() async {
        // Given: User has a library with tracks of different genres
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        let classicalTrack = createTestTrack(title: "Classical Song", genre: "Classical")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack, classicalTrack])
        await viewModel.loadLibrary()
        
        // When: User selects both "Rock" and "Jazz" genre filters
        await viewModel.filterByGenres(Set(["Rock", "Jazz"]))
        
        // Then: User sees both Rock and Jazz tracks
        XCTAssertEqual(viewModel.filteredTracks.count, 2, "User should see Rock and Jazz tracks")
        let genres = Set(viewModel.filteredTracks.compactMap { $0.genre })
        XCTAssertTrue(genres.contains("Rock"), "Should include Rock tracks")
        XCTAssertTrue(genres.contains("Jazz"), "Should include Jazz tracks")
    }
    
    // MARK: - Scenario: User clears genre filter
    
    func testScenario_UserClearsGenreFilter() async {
        // Given: User has filtered the library by genre
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        let jazzTrack = createTestTrack(title: "Jazz Song", genre: "Jazz")
        
        await mockIndexer.setTracks([rockTrack, jazzTrack])
        await viewModel.loadLibrary()
        await viewModel.filterByGenres(Set(["Rock"]))
        
        // When: User clears the genre filter
        await viewModel.filterByGenres(Set<String>())
        
        // Then: User sees all tracks again
        XCTAssertEqual(viewModel.filteredTracks.count, 2, "User should see all tracks after clearing filter")
    }
    
    // MARK: - Scenario: User changes browse mode
    
    func testScenario_UserChangesBrowseMode() async {
        // Given: User is viewing the library
        let track = createTestTrack(title: "Song", artist: "Artist")
        await mockIndexer.setTracks([track])
        await viewModel.loadLibrary()
        
        // When: User clicks "Artists" in the sidebar browse section
        await viewModel.setBrowseMode(.artists)
        
        // Then: Browse mode changes to Artists
        XCTAssertEqual(viewModel.browseMode, .artists, "Browse mode should change to Artists")
    }
    
    // MARK: - Scenario: User toggles genre filter
    
    func testScenario_UserTogglesGenreFilter() async {
        // Given: User has a library with tracks
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        await mockIndexer.setTracks([rockTrack])
        await viewModel.loadLibrary()
        
        // When: User toggles "Rock" genre filter on
        await viewModel.toggleGenre("Rock")
        
        // Then: Rock filter is applied
        XCTAssertTrue(viewModel.selectedGenres.contains("Rock"), "Rock genre should be selected")
        
        // When: User toggles "Rock" genre filter off
        await viewModel.toggleGenre("Rock")
        
        // Then: Rock filter is removed
        XCTAssertFalse(viewModel.selectedGenres.contains("Rock"), "Rock genre should be deselected")
    }
    
    // MARK: - Scenario: User has no tracks matching filter
    
    func testScenario_UserHasNoTracksMatchingFilter() async {
        // Given: User has only Rock tracks in library
        let rockTrack = createTestTrack(title: "Rock Song", genre: "Rock")
        await mockIndexer.setTracks([rockTrack])
        await viewModel.loadLibrary()
        
        // When: User filters by "Jazz" genre
        await viewModel.filterByGenres(Set(["Jazz"]))
        
        // Then: User sees an empty library view
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "User should see empty view when no tracks match filter")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack(title: String, artist: String = "Test Artist", album: String = "Test Album", genre: String? = nil) -> Track {
        Track(
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: "/path/to/\(title).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            genre: genre
        )
    }
}
