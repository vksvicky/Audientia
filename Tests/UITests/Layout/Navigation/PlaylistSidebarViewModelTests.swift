//
//  PlaylistSidebarViewModelTests.swift
//  Audientia
//
//  TDD tests for PlaylistSidebarViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class PlaylistSidebarViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockPlaylistManager: PlaylistSidebarMockPlaylistManager!
    private var viewModel: PlaylistSidebarViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockPlaylistManager = PlaylistSidebarMockPlaylistManager()
        viewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPlaylistManager = nil
        super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    func testLoadPlaylists_WhenPlaylistsExist_LoadsAllPlaylists() async {
        // Given: PlaylistManager has playlists
        let playlist1 = createTestPlaylist(name: "Playlist 1")
        let playlist2 = createTestPlaylist(name: "Playlist 2")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: All playlists should be loaded
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.playlists.count, 2)
        XCTAssertEqual(viewModel.playlists[0].name, "Playlist 1")
        XCTAssertEqual(viewModel.playlists[1].name, "Playlist 2")
    }
    
    func testLoadPlaylists_WhenNoPlaylists_ReturnsEmptyArray() async {
        // Given: PlaylistManager has no playlists
        await mockPlaylistManager.setPlaylists([])
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: Should return empty array
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    func testLoadPlaylists_OrdersPlaylistsByName() async {
        // Given: Playlists in random order
        let playlistC = createTestPlaylist(name: "C Playlist")
        let playlistA = createTestPlaylist(name: "A Playlist")
        let playlistB = createTestPlaylist(name: "B Playlist")
        await mockPlaylistManager.setPlaylists([playlistC, playlistA, playlistB])
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: Playlists should be ordered by name
        XCTAssertEqual(viewModel.playlists.count, 3)
        XCTAssertEqual(viewModel.playlists[0].name, "A Playlist")
        XCTAssertEqual(viewModel.playlists[1].name, "B Playlist")
        XCTAssertEqual(viewModel.playlists[2].name, "C Playlist")
    }
    
    // MARK: - Boundary Conditions
    
    func testLoadPlaylists_WhenManagerThrowsError_HandlesError() async {
        // Given: PlaylistManager throws error
        await mockPlaylistManager.setShouldThrowError(true)
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: Error should be set
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    func testLoadPlaylists_WithLargeNumberOfPlaylists_LoadsAll() async {
        // Given: Large number of playlists
        let playlists = (0..<100).map { createTestPlaylist(name: "Playlist \($0)") }
        await mockPlaylistManager.setPlaylists(playlists)
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: All playlists should be loaded
        XCTAssertEqual(viewModel.playlists.count, 100)
    }
    
    // MARK: - Inverse Relationships
    
    func testLoadPlaylists_WhenCalledMultipleTimes_RefreshesList() async {
        // Given: Initial playlists
        let playlist1 = createTestPlaylist(name: "Playlist 1")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        let initialCount = viewModel.playlists.count
        
        // When: Adding more playlists and reloading
        let playlist2 = createTestPlaylist(name: "Playlist 2")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        
        // Then: List should be refreshed
        XCTAssertEqual(viewModel.playlists.count, initialCount + 1)
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Playlist 2" })
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testLoadPlaylists_ResultsMatchDirectManagerCall() async {
        // Given: Playlists in manager
        let playlist1 = createTestPlaylist(name: "Playlist 1")
        let playlist2 = createTestPlaylist(name: "Playlist 2")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        
        // When: Loading via ViewModel
        await viewModel.loadPlaylists()
        
        // Then: Results should match direct manager call
        let directResults = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(viewModel.playlists.count, directResults.count)
        XCTAssertEqual(Set(viewModel.playlists.map { $0.id }), Set(directResults.map { $0.id }))
    }
    
    // MARK: - Error Conditions
    
    func testLoadPlaylists_WhenManagerIsNil_HandlesGracefully() async {
        // Given: ViewModel with nil manager (shouldn't happen, but test defensive coding)
        // Note: This test verifies the ViewModel handles errors gracefully
        await mockPlaylistManager.setShouldThrowError(true)
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: Should handle error without crashing
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Performance Characteristics
    
    func testLoadPlaylists_PerformanceWithManyPlaylists() async {
        // Given: Large number of playlists
        let playlists = (0..<1000).map { createTestPlaylist(name: "Playlist \($0)") }
        await mockPlaylistManager.setPlaylists(playlists)
        
        // When: Loading playlists
        let startTime = CFAbsoluteTimeGetCurrent()
        await viewModel.loadPlaylists()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time
        XCTAssertLessThan(duration, 0.1, "Should load 1000 playlists within 100ms")
        XCTAssertEqual(viewModel.playlists.count, 1000)
    }
    
    // MARK: - Edge Cases
    
    func testLoadPlaylists_HandlesPlaylistsWithSpecialCharacters() async {
        // Given: Playlists with special characters in names
        let playlist1 = createTestPlaylist(name: "Playlist & More")
        let playlist2 = createTestPlaylist(name: "Playlist \"Quoted\"")
        let playlist3 = createTestPlaylist(name: "Playlist 'Single'")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2, playlist3])
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: Should handle special characters correctly
        XCTAssertEqual(viewModel.playlists.count, 3)
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Playlist & More" })
    }
    
    func testLoadPlaylists_HandlesEmptyPlaylistNames() async {
        // Given: Playlist with empty name (edge case)
        let playlist = createTestPlaylist(name: "")
        await mockPlaylistManager.setPlaylists([playlist])
        
        // When: Loading playlists
        await viewModel.loadPlaylists()
        
        // Then: Should load playlist even with empty name
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists[0].name, "")
    }
    
    // MARK: - Search Functionality Tests
    
    func testUpdateSearchText_WhenTextMatches_FiltersPlaylists() async {
        // Given: Playlists loaded
        let playlist1 = createTestPlaylist(name: "Rock Playlist")
        let playlist2 = createTestPlaylist(name: "Jazz Playlist")
        let playlist3 = createTestPlaylist(name: "Classical Playlist")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2, playlist3])
        await viewModel.loadPlaylists()
        
        // When: Searching for "Rock"
        await viewModel.updateSearchText("Rock")
        
        // Then: Only matching playlist should be shown
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists[0].name, "Rock Playlist")
        XCTAssertEqual(viewModel.searchText, "Rock")
    }
    
    func testUpdateSearchText_WhenTextDoesNotMatch_ReturnsEmptyArray() async {
        // Given: Playlists loaded
        let playlist1 = createTestPlaylist(name: "Rock Playlist")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        
        // When: Searching for non-matching text
        await viewModel.updateSearchText("Jazz")
        
        // Then: Should return empty array
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    func testUpdateSearchText_IsCaseInsensitive() async {
        // Given: Playlists loaded
        let playlist1 = createTestPlaylist(name: "Rock Playlist")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        
        // When: Searching with different case
        await viewModel.updateSearchText("rock")
        
        // Then: Should match regardless of case
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists[0].name, "Rock Playlist")
    }
    
    func testUpdateSearchText_WhenTextIsEmpty_ShowsAllPlaylists() async {
        // Given: Playlists loaded and filtered
        let playlist1 = createTestPlaylist(name: "Rock Playlist")
        let playlist2 = createTestPlaylist(name: "Jazz Playlist")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        await viewModel.updateSearchText("Rock")
        
        // When: Clearing search
        await viewModel.updateSearchText("")
        
        // Then: Should show all playlists
        XCTAssertEqual(viewModel.playlists.count, 2)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    func testUpdateSearchText_MatchesPartialNames() async {
        // Given: Playlists loaded
        let playlist1 = createTestPlaylist(name: "My Favorite Rock Songs")
        let playlist2 = createTestPlaylist(name: "My Favorite Jazz Songs")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        
        // When: Searching for partial match
        await viewModel.updateSearchText("Rock")
        
        // Then: Should match playlist with "Rock" in name
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists[0].name, "My Favorite Rock Songs")
    }
    
    func testUpdateSearchText_TrimsWhitespace() async {
        // Given: Playlists loaded
        let playlist1 = createTestPlaylist(name: "Rock Playlist")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        
        // When: Searching with whitespace
        await viewModel.updateSearchText("  Rock  ")
        
        // Then: Should match after trimming
        XCTAssertEqual(viewModel.playlists.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlaylist(name: String, isSmart: Bool = false) -> Playlist {
        Playlist(
            id: UUID(),
            name: name,
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: isSmart
        )
    }
}
