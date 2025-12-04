//
//  PlaylistSidebarViewModelBDDTests.swift
//  Audientia
//
//  BDD tests for PlaylistSidebarViewModel scenarios
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

/// BDD-style tests for PlaylistSidebarViewModel scenarios
@MainActor
final class PlaylistSidebarViewModelBDDTests: XCTestCase {
    
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
    
    // MARK: - Scenario: User views playlists in sidebar
    
    func testScenario_UserViewsPlaylistsInSidebar() async {
        // Given: User has created several playlists
        let playlist1 = createTestPlaylist(name: "My Favorites")
        let playlist2 = createTestPlaylist(name: "Workout Mix")
        let playlist3 = createTestPlaylist(name: "Chill Vibes")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2, playlist3])
        
        // When: User opens the Playlists tab
        await viewModel.loadPlaylists()
        
        // Then: User sees all their playlists listed in the sidebar, sorted alphabetically
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.playlists.count, 3)
        XCTAssertEqual(viewModel.playlists[0].name, "Chill Vibes")
        XCTAssertEqual(viewModel.playlists[1].name, "My Favorites")
        XCTAssertEqual(viewModel.playlists[2].name, "Workout Mix")
    }
    
    // MARK: - Scenario: User has no playlists
    
    func testScenario_UserHasNoPlaylists() async {
        // Given: User has not created any playlists yet
        await mockPlaylistManager.setPlaylists([])
        
        // When: User opens the Playlists tab
        await viewModel.loadPlaylists()
        
        // Then: User sees an empty state indicating no playlists exist
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    // MARK: - Scenario: User refreshes playlist list
    
    func testScenario_UserRefreshesPlaylistList() async {
        // Given: User has some playlists loaded
        let playlist1 = createTestPlaylist(name: "Playlist 1")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        
        // When: User creates a new playlist and refreshes the list
        let playlist2 = createTestPlaylist(name: "Playlist 2")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        
        // Then: User sees the new playlist in the updated list
        XCTAssertEqual(viewModel.playlists.count, 2)
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Playlist 2" })
    }
    
    // MARK: - Scenario: User encounters error loading playlists
    
    func testScenario_UserEncountersErrorLoadingPlaylists() async {
        // Given: PlaylistManager encounters an error
        await mockPlaylistManager.setShouldThrowError(true)
        
        // When: User opens the Playlists tab
        await viewModel.loadPlaylists()
        
        // Then: Error is captured and displayed to user
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    // MARK: - Scenario: User creates a new playlist
    
    func testScenario_UserCreatesNewPlaylist() async throws {
        // Given: User has some existing playlists
        let playlist1 = createTestPlaylist(name: "My Rock Collection")
        let playlist2 = createTestPlaylist(name: "Jazz Favorites")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.allPlaylists.count, 2)
        
        // When: User creates a new playlist with a valid name
        try await viewModel.createPlaylist(name: "Classical Masterpieces")
        
        // Then: The new playlist is created and appears in the list, sorted alphabetically
        XCTAssertEqual(viewModel.allPlaylists.count, 3)
        let playlistNames = viewModel.allPlaylists.map { $0.name }
        XCTAssertTrue(playlistNames.contains("Classical Masterpieces"))
        
        // And: The playlist list is sorted alphabetically
        XCTAssertEqual(viewModel.allPlaylists[0].name, "Classical Masterpieces")
        XCTAssertEqual(viewModel.allPlaylists[1].name, "Jazz Favorites")
        XCTAssertEqual(viewModel.allPlaylists[2].name, "My Rock Collection")
    }
    
    // MARK: - Scenario: User tries to create playlist with duplicate name
    
    func testScenario_UserTriesToCreatePlaylistWithDuplicateName() async {
        // Given: User has a playlist named "My Playlist"
        let existingPlaylist = createTestPlaylist(name: "My Playlist")
        await mockPlaylistManager.setPlaylists([existingPlaylist])
        await viewModel.loadPlaylists()
        
        // When: User tries to create another playlist with the same name
        // Then: An error is thrown indicating the name is already taken
        do {
            try await viewModel.createPlaylist(name: "My Playlist")
            XCTFail("Expected error for duplicate playlist name")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .duplicatePlaylist)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // And: The playlist list remains unchanged
        XCTAssertEqual(viewModel.allPlaylists.count, 1)
        XCTAssertEqual(viewModel.allPlaylists[0].name, "My Playlist")
    }
    
    // MARK: - Scenario: User creates a new smart playlist
    
    func testScenario_UserCreatesNewSmartPlaylist() async throws {
        // Given: User has some existing playlists and wants to create a smart playlist
        let playlist1 = createTestPlaylist(name: "My Rock Collection")
        let playlist2 = createTestPlaylist(name: "Jazz Favorites")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.allPlaylists.count, 2)
        
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When: User creates a new smart playlist with a valid name and rules
        try await viewModel.createSmartPlaylist(name: "5-Star Songs", rules: rules)
        
        // Then: The new smart playlist is created and appears in the list, sorted alphabetically
        XCTAssertEqual(viewModel.allPlaylists.count, 3)
        let playlistNames = viewModel.allPlaylists.map { $0.name }
        XCTAssertTrue(playlistNames.contains("5-Star Songs"))
        
        // And: The playlist is marked as a smart playlist
        let smartPlaylist = viewModel.allPlaylists.first { $0.name == "5-Star Songs" }
        XCTAssertNotNil(smartPlaylist)
        XCTAssertTrue(smartPlaylist?.isSmart ?? false)
        
        // And: The playlist list is sorted alphabetically
        XCTAssertEqual(viewModel.allPlaylists[0].name, "5-Star Songs")
        XCTAssertEqual(viewModel.allPlaylists[1].name, "Jazz Favorites")
        XCTAssertEqual(viewModel.allPlaylists[2].name, "My Rock Collection")
    }
    
    // MARK: - Scenario: User tries to create smart playlist with invalid rules
    
    func testScenario_UserTriesToCreateSmartPlaylistWithInvalidRules() async {
        // Given: User wants to create a smart playlist but hasn't added any rules
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [])
        
        // When: User tries to create a smart playlist with empty rules
        // Then: An error is thrown indicating the rules are invalid
        do {
            try await viewModel.createSmartPlaylist(name: "My Smart Playlist", rules: rules)
            XCTFail("Expected error for invalid rules")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .invalidRules)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // And: The playlist list remains unchanged
        XCTAssertEqual(viewModel.allPlaylists.count, 0)
    }
    
    // MARK: - Scenario: User searches for playlists
    
    func testScenario_UserSearchesForPlaylists() async {
        // Given: User has several playlists
        let playlist1 = createTestPlaylist(name: "My Rock Collection")
        let playlist2 = createTestPlaylist(name: "Jazz Favorites")
        let playlist3 = createTestPlaylist(name: "Classical Masterpieces")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2, playlist3])
        await viewModel.loadPlaylists()
        
        // When: User types "Rock" in the search field
        await viewModel.updateSearchText("Rock")
        
        // Then: User sees only playlists matching "Rock"
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists[0].name, "My Rock Collection")
    }
    
    // MARK: - Scenario: User clears search
    
    func testScenario_UserClearsSearch() async {
        // Given: User has searched for playlists
        let playlist1 = createTestPlaylist(name: "Rock Playlist")
        let playlist2 = createTestPlaylist(name: "Jazz Playlist")
        await mockPlaylistManager.setPlaylists([playlist1, playlist2])
        await viewModel.loadPlaylists()
        await viewModel.updateSearchText("Rock")
        
        // When: User clears the search field
        await viewModel.updateSearchText("")
        
        // Then: User sees all playlists again
        XCTAssertEqual(viewModel.playlists.count, 2)
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
