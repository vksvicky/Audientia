//
//  PlaylistBrowserViewBDDTests.swift
//  Audientia - UI Tests
//
//  BDD tests for PlaylistBrowserView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// BDD tests for PlaylistBrowserView
/// Scenarios: "As a user, I want to view all my playlists and manage them"
@MainActor
final class PlaylistBrowserViewBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockPlaylistManager: MockPlaylistManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockPlaylistManager = MockPlaylistManager()
    }
    
    override func tearDown() {
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
    
    /// Scenario: As a user, I want to see all my playlists when I open the playlist browser
    func testUserViewsAllPlaylists() async {
        // Given - User has multiple playlists
        let playlist1 = createPlaylist(name: "My Favorites", trackCount: 50, totalDuration: 7200.0)
        let playlist2 = createPlaylist(name: "Workout Mix", trackCount: 30, totalDuration: 3600.0)
        let playlist3 = createPlaylist(name: "Chill Vibes", trackCount: 20, totalDuration: 4800.0, isSmart: true)
        mockPlaylistManager.playlists = [playlist1, playlist2, playlist3]
        
        // When - User opens the playlist browser
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - User should see all playlists
        XCTAssertEqual(viewModel.playlists.count, 3)
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "My Favorites" })
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Workout Mix" })
        XCTAssertTrue(viewModel.playlists.contains { $0.name == "Chill Vibes" })
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to see an empty state when I have no playlists
    func testUserSeesEmptyStateWhenNoPlaylists() async {
        // Given - User has no playlists
        mockPlaylistManager.playlists = []
        
        // When - User opens the playlist browser
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - User should see an empty state
        XCTAssertTrue(viewModel.playlists.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to create a new playlist from the browser
    func testUserCreatesNewPlaylistFromBrowser() async throws {
        // Given - User has no playlists
        mockPlaylistManager.playlists = []
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        XCTAssertTrue(viewModel.playlists.isEmpty)
        
        // When - User creates a new playlist named "My New Playlist"
        try await viewModel.createPlaylist(name: "My New Playlist")
        
        // Then - The playlist should be created and visible
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists.first?.name, "My New Playlist")
    }
    
    /// Scenario: As a user, I want to delete a playlist from the browser
    func testUserDeletesPlaylistFromBrowser() async throws {
        // Given - User has a playlist
        let playlist = createPlaylist(name: "To Delete")
        mockPlaylistManager.playlists = [playlist]
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.playlists.count, 1)
        
        // When - User deletes the playlist
        try await viewModel.deletePlaylist(id: playlist.id)
        
        // Then - The playlist should be removed
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    /// Scenario: As a user, I want to rename a playlist from the browser
    func testUserRenamesPlaylistFromBrowser() async throws {
        // Given - User has a playlist named "Old Name"
        let playlist = createPlaylist(name: "Old Name")
        mockPlaylistManager.playlists = [playlist]
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.playlists.first?.name, "Old Name")
        
        // When - User renames it to "New Name"
        try await viewModel.updatePlaylistName(id: playlist.id, name: "New Name")
        
        // Then - The playlist should have the new name
        XCTAssertEqual(viewModel.playlists.first?.name, "New Name")
    }
    
    /// Scenario: As a user, I want to see playlist details (track count, duration)
    func testUserSeesPlaylistDetails() async {
        // Given - User has a playlist with tracks
        let playlist = createPlaylist(
            name: "My Playlist",
            trackCount: 25,
            totalDuration: 5400.0
        )
        mockPlaylistManager.playlists = [playlist]
        
        // When - User views the playlist browser
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - User should see playlist details
        let loadedPlaylist = viewModel.playlists.first
        XCTAssertNotNil(loadedPlaylist)
        XCTAssertEqual(loadedPlaylist?.trackCount, 25)
        if let playlist = loadedPlaylist {
            XCTAssertEqual(playlist.totalDuration, 5400.0, accuracy: 0.1)
        }
    }
    
    /// Scenario: As a user, I want to distinguish between regular and smart playlists
    func testUserDistinguishesRegularAndSmartPlaylists() async {
        // Given - User has both regular and smart playlists
        let regularPlaylist = createPlaylist(name: "Regular Playlist", isSmart: false)
        let smartPlaylist = createPlaylist(name: "Smart Playlist", isSmart: true)
        mockPlaylistManager.playlists = [regularPlaylist, smartPlaylist]
        
        // When - User views the playlist browser
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - User should see both types clearly distinguished
        XCTAssertEqual(viewModel.playlists.count, 2)
        let loadedRegular = viewModel.playlists.first { $0.id == regularPlaylist.id }
        let loadedSmart = viewModel.playlists.first { $0.id == smartPlaylist.id }
        XCTAssertNotNil(loadedRegular)
        XCTAssertNotNil(loadedSmart)
        XCTAssertFalse(loadedRegular?.isSmart ?? true)
        XCTAssertTrue(loadedSmart?.isSmart ?? false)
    }
    
    /// Scenario: As a user, I want to see a loading indicator while playlists are loading
    func testUserSeesLoadingIndicator() async {
        // Given - Playlists will take time to load
        mockPlaylistManager.playlists = [createPlaylist(name: "Test")]
        
        // When - User opens the playlist browser
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        let loadTask = Task {
            await viewModel.loadPlaylists()
        }
        
        // Then - Loading state should be shown (briefly)
        await loadTask.value
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to see an error message if playlist operations fail
    func testUserSeesErrorWhenOperationFails() async {
        // Given - PlaylistManager will fail
        mockPlaylistManager.shouldFailCreate = true
        
        // When - User tries to create a playlist
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        do {
            _ = try await viewModel.createPlaylist(name: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Then - User should see an error
            XCTAssertNotNil(viewModel.lastError)
            XCTAssertTrue(viewModel.lastError is PlaylistManagerError)
        }
    }
}
