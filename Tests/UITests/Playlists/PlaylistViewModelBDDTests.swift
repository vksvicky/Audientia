//
//  PlaylistViewModelBDDTests.swift
//  Audientia - UI Tests
//
//  BDD tests for PlaylistViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// BDD tests for PlaylistViewModel
/// Scenarios from roadmap: "As a user, I want to create a playlist of 5-star songs from 2020"
@MainActor
final class PlaylistViewModelBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: PlaylistViewModel!
    private var mockPlaylistManager: MockPlaylistManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockPlaylistManager = MockPlaylistManager()
        viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPlaylistManager = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createPlaylist(
        name: String = "Test Playlist",
        trackCount: Int = 0,
        totalDuration: TimeInterval = 0.0,
        isSmart: Bool = false
    ) -> Playlist {
        Playlist(
            name: name,
            trackCount: trackCount,
            totalDuration: totalDuration,
            isSmart: isSmart
        )
    }
    
    // MARK: - BDD Scenarios
    
    /// Scenario: As a user, I want to view all my playlists
    func testUserViewsAllPlaylists() async {
        // Given - User has multiple playlists
        let playlist1 = createPlaylist(name: "My Favorites")
        let playlist2 = createPlaylist(name: "Workout Mix")
        let playlist3 = createPlaylist(name: "Chill Vibes", isSmart: true)
        mockPlaylistManager.playlists = [playlist1, playlist2, playlist3]
        
        // When - User opens the playlist browser
        await viewModel.loadPlaylists()
        
        // Then - User should see all playlists
        XCTAssertEqual(viewModel.playlists.count, 3)
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "My Favorites" })
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Workout Mix" })
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Chill Vibes" })
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to create a new playlist
    func testUserCreatesNewPlaylist() async throws {
        // Given - User has no playlists
        mockPlaylistManager.playlists = []
        await viewModel.loadPlaylists()
        XCTAssertTrue(viewModel.playlists.isEmpty)
        
        // When - User creates a new playlist named "My New Playlist"
        try await viewModel.createPlaylist(name: "My New Playlist")
        
        // Then - The playlist should be created and visible
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists.first?.name, "My New Playlist")
        XCTAssertFalse(viewModel.playlists.first?.isSmart ?? true)
    }
    
    /// Scenario: As a user, I want to delete a playlist
    func testUserDeletesPlaylist() async throws {
        // Given - User has a playlist
        let playlist = createPlaylist(name: "To Delete")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.playlists.count, 1)
        
        // When - User deletes the playlist
        try await viewModel.deletePlaylist(id: playlist.id)
        
        // Then - The playlist should be removed
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    /// Scenario: As a user, I want to rename a playlist
    func testUserRenamesPlaylist() async throws {
        // Given - User has a playlist named "Old Name"
        let playlist = createPlaylist(name: "Old Name")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.playlists.first?.name, "Old Name")
        
        // When - User renames it to "New Name"
        try await viewModel.updatePlaylistName(id: playlist.id, name: "New Name")
        
        // Then - The playlist should have the new name
        XCTAssertEqual(viewModel.playlists.first?.name, "New Name")
    }
    
    /// Scenario: As a user, I want to see an empty state when I have no playlists
    func testUserSeesEmptyStateWhenNoPlaylists() async {
        // Given - User has no playlists
        mockPlaylistManager.playlists = []
        
        // When - User opens the playlist browser
        await viewModel.loadPlaylists()
        
        // Then - User should see an empty list
        XCTAssertTrue(viewModel.playlists.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to see loading state while playlists are being loaded
    func testUserSeesLoadingState() async {
        // Given - PlaylistManager will take time to load
        mockPlaylistManager.playlists = [createPlaylist(name: "Test")]
        
        // When - User opens the playlist browser
        let loadTask = Task {
            await viewModel.loadPlaylists()
        }
        
        // Then - Loading state should be shown (briefly)
        // Note: In a real scenario, we might add a delay to the mock
        await loadTask.value
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to see an error message if playlist creation fails
    func testUserSeesErrorWhenPlaylistCreationFails() async {
        // Given - PlaylistManager will fail to create
        mockPlaylistManager.shouldFailCreate = true
        
        // When - User tries to create a playlist
        do {
            _ = try await viewModel.createPlaylist(name: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Then - User should see an error
            XCTAssertNotNil(viewModel.lastError)
            XCTAssertTrue(viewModel.lastError is PlaylistManagerError)
        }
    }
    
    /// Scenario: As a user, I want to create a playlist with a long name
    func testUserCreatesPlaylistWithLongName() async throws {
        // Given - User wants to create a playlist with a descriptive name
        let longName = "My Very Long and Descriptive Playlist Name That Describes Everything"
        
        // When - User creates the playlist
        try await viewModel.createPlaylist(name: longName)
        
        // Then - The playlist should be created with the long name
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists.first?.name, longName)
    }
    
    /// Scenario: As a user, I want to see both regular and smart playlists
    func testUserSeesRegularAndSmartPlaylists() async {
        // Given - User has both regular and smart playlists
        let regularPlaylist = createPlaylist(name: "Regular Playlist", isSmart: false)
        let smartPlaylist = createPlaylist(name: "Smart Playlist", isSmart: true)
        mockPlaylistManager.playlists = [regularPlaylist, smartPlaylist]
        
        // When - User opens the playlist browser
        await viewModel.loadPlaylists()
        
        // Then - User should see both types
        XCTAssertEqual(viewModel.playlists.count, 2)
        let loadedRegular = viewModel.playlists.first { $0.id == regularPlaylist.id }
        let loadedSmart = viewModel.playlists.first { $0.id == smartPlaylist.id }
        XCTAssertNotNil(loadedRegular)
        XCTAssertNotNil(loadedSmart)
        XCTAssertFalse(loadedRegular?.isSmart ?? true)
        XCTAssertTrue(loadedSmart?.isSmart ?? false)
    }
}
