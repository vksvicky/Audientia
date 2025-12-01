//
//  PlaylistViewModelTests.swift
//  Audientia - UI Tests
//
//  TDD tests for PlaylistViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

// Import PlaylistViewModel from UI module
// Since it's in the app target, we include the source file in UITests target

/// TDD tests for PlaylistViewModel
/// Following Right-BICEP principles:
/// - [Right]: Verify playlist operations produce correct results
/// - [B]oundary: Empty playlists, very large playlists, edge cases
/// - [I]nverse: Add playlist → Delete → Verify not in list
/// - [C]ross-check: Compare with direct PlaylistManager calls
/// - [E]rror: Invalid operations, missing playlists, network errors
/// - [P]erformance: Load playlists < 200ms, operations complete quickly
@MainActor
final class PlaylistViewModelTests: XCTestCase {
    
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
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: ViewModel should load all playlists on initialisation
    func testLoadsAllPlaylistsOnInit() async throws {
        // Given - PlaylistManager has playlists
        let playlist1 = createPlaylist(name: "Playlist 1")
        let playlist2 = createPlaylist(name: "Playlist 2")
        mockPlaylistManager.playlists = [playlist1, playlist2]
        
        // When - ViewModel loads playlists
        await viewModel.loadPlaylists()
        
        // Then - ViewModel should have all playlists
        XCTAssertEqual(viewModel.playlists.count, 2)
        XCTAssertTrue(viewModel.playlists.contains { $0.id == playlist1.id })
        XCTAssertTrue(viewModel.playlists.contains { $0.id == playlist2.id })
    }
    
    /// Test: ViewModel should create a new playlist
    func testCreatesNewPlaylist() async throws {
        // Given - A playlist name
        let playlistName = "My New Playlist"
        
        // When - Creating a new playlist
        try await viewModel.createPlaylist(name: playlistName)
        
        // Then - Playlist should be created and added to list
        XCTAssertTrue(mockPlaylistManager.createPlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.createPlaylistName, playlistName)
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists.first?.name, playlistName)
    }
    
    /// Test: ViewModel should delete a playlist
    func testDeletesPlaylist() async throws {
        // Given - A playlist exists
        let playlist = createPlaylist(name: "To Delete")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        
        // When - Deleting the playlist
        try await viewModel.deletePlaylist(id: playlist.id)
        
        // Then - Playlist should be deleted
        XCTAssertTrue(mockPlaylistManager.deletePlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.deletePlaylistId, playlist.id)
        XCTAssertFalse(viewModel.playlists.contains { $0.id == playlist.id })
    }
    
    /// Test: ViewModel should update playlist name
    func testUpdatesPlaylistName() async throws {
        // Given - A playlist exists
        let playlist = createPlaylist(name: "Old Name")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        
        // When - Updating the playlist name
        let newName = "New Name"
        try await viewModel.updatePlaylistName(id: playlist.id, name: newName)
        
        // Then - Playlist name should be updated
        XCTAssertTrue(mockPlaylistManager.updatePlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.updatePlaylistId, playlist.id)
        XCTAssertEqual(mockPlaylistManager.updatePlaylistName, newName)
        if let updatedPlaylist = viewModel.playlists.first(where: { $0.id == playlist.id }) {
            XCTAssertEqual(updatedPlaylist.name, newName)
        } else {
            XCTFail("Playlist should still exist after update")
        }
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: ViewModel should handle empty playlist list
    func testHandlesEmptyPlaylistList() async {
        // Given - No playlists exist
        mockPlaylistManager.playlists = []
        
        // When - Loading playlists
        await viewModel.loadPlaylists()
        
        // Then - ViewModel should have empty list
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    /// Test: ViewModel should handle very long playlist names
    func testHandlesVeryLongPlaylistName() async throws {
        // Given - A very long playlist name
        let longName = String(repeating: "A", count: 1000)
        
        // When - Creating playlist with long name
        try await viewModel.createPlaylist(name: longName)
        
        // Then - Playlist should be created
        XCTAssertTrue(mockPlaylistManager.createPlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.createPlaylistName, longName)
    }
    
    /// Test: ViewModel should handle playlist with many tracks
    func testHandlesPlaylistWithManyTracks() async {
        // Given - A playlist with many tracks
        let playlist = createPlaylist(name: "Large Playlist", trackCount: 10000, totalDuration: 360000.0)
        mockPlaylistManager.playlists = [playlist]
        
        // When - Loading playlists
        await viewModel.loadPlaylists()
        
        // Then - ViewModel should load the playlist
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertEqual(viewModel.playlists.first?.trackCount, 10000)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Create playlist then delete should result in empty list
    func testCreateThenDeletePlaylist() async throws {
        // Given - No playlists
        mockPlaylistManager.playlists = []
        await viewModel.loadPlaylists()
        XCTAssertTrue(viewModel.playlists.isEmpty)
        
        // When - Creating then deleting a playlist
        let playlist = try await viewModel.createPlaylist(name: "Temp Playlist")
        try await viewModel.deletePlaylist(id: playlist.id)
        
        // Then - List should be empty again
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    /// Test: Update playlist name then update back should restore original
    func testUpdatePlaylistNameRoundtrip() async throws {
        // Given - A playlist with original name
        let originalName = "Original Name"
        let playlist = createPlaylist(name: originalName)
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        
        // When - Updating name then updating back
        try await viewModel.updatePlaylistName(id: playlist.id, name: "New Name")
        try await viewModel.updatePlaylistName(id: playlist.id, name: originalName)
        
        // Then - Name should be restored
        if let restoredPlaylist = viewModel.playlists.first(where: { $0.id == playlist.id }) {
            XCTAssertEqual(restoredPlaylist.name, originalName)
        } else {
            XCTFail("Playlist should exist")
        }
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: ViewModel playlists should match PlaylistManager playlists
    func testPlaylistsMatchPlaylistManager() async {
        // Given - PlaylistManager has specific playlists
        let playlist1 = createPlaylist(name: "Playlist 1")
        let playlist2 = createPlaylist(name: "Playlist 2", isSmart: true)
        mockPlaylistManager.playlists = [playlist1, playlist2]
        
        // When - Loading playlists
        await viewModel.loadPlaylists()
        
        // Then - ViewModel playlists should match
        let managerPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(viewModel.playlists.count, managerPlaylists.count)
        for playlist in viewModel.playlists {
            XCTAssertTrue(managerPlaylists.contains { $0.id == playlist.id })
        }
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: ViewModel should handle creation failure
    func testHandlesCreationFailure() async {
        // Given - PlaylistManager will fail to create
        mockPlaylistManager.shouldFailCreate = true
        
        // When - Creating a playlist
        // Then - Should throw error
        do {
            _ = try await viewModel.createPlaylist(name: "Test")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    /// Test: ViewModel should handle deletion failure
    func testHandlesDeletionFailure() async {
        // Given - A playlist exists
        let playlist = createPlaylist(name: "Test")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        mockPlaylistManager.shouldFailDelete = true
        
        // When - Deleting the playlist
        // Then - Should throw error
        do {
            try await viewModel.deletePlaylist(id: playlist.id)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    /// Test: ViewModel should handle update failure
    func testHandlesUpdateFailure() async {
        // Given - A playlist exists
        let playlist = createPlaylist(name: "Test")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylists()
        mockPlaylistManager.shouldFailUpdate = true
        
        // When - Updating the playlist
        // Then - Should throw error
        do {
            try await viewModel.updatePlaylistName(id: playlist.id, name: "New Name")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    /// Test: ViewModel should handle invalid playlist name
    func testHandlesInvalidPlaylistName() async {
        // Given - Empty playlist name
        // When - Creating playlist with empty name
        // Then - Should throw error
        do {
            _ = try await viewModel.createPlaylist(name: "")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: Loading playlists should complete quickly
    func testLoadPlaylistsPerformance() async {
        // Given - Many playlists
        var playlists: [Playlist] = []
        for i in 0..<1000 {
            playlists.append(createPlaylist(name: "Playlist \(i)"))
        }
        mockPlaylistManager.playlists = playlists
        
        // When - Loading playlists
        let startTime = Date()
        await viewModel.loadPlaylists()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 200ms
        XCTAssertLessThan(duration, 0.2, "Loading playlists should complete within 200ms")
        XCTAssertEqual(viewModel.playlists.count, 1000)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test: ViewModel should handle Unicode playlist names
    func testHandlesUnicodePlaylistNames() async throws {
        // Given - Unicode playlist name
        let unicodeName = "プレイリスト 🎵 播放列表"
        
        // When - Creating playlist with Unicode name
        try await viewModel.createPlaylist(name: unicodeName)
        
        // Then - Playlist should be created
        XCTAssertTrue(mockPlaylistManager.createPlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.createPlaylistName, unicodeName)
    }
    
    /// Test: ViewModel should handle special characters in playlist names
    func testHandlesSpecialCharactersInPlaylistNames() async throws {
        // Given - Playlist name with special characters
        let specialName = "Playlist & More! @#$%"
        
        // When - Creating playlist with special characters
        try await viewModel.createPlaylist(name: specialName)
        
        // Then - Playlist should be created
        XCTAssertTrue(mockPlaylistManager.createPlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.createPlaylistName, specialName)
    }
    
    /// Test: ViewModel should handle smart playlists
    func testHandlesSmartPlaylists() async {
        // Given - Smart playlists exist
        let smartPlaylist = createPlaylist(name: "Smart Playlist", isSmart: true)
        mockPlaylistManager.playlists = [smartPlaylist]
        
        // When - Loading playlists
        await viewModel.loadPlaylists()
        
        // Then - Smart playlist should be loaded
        XCTAssertEqual(viewModel.playlists.count, 1)
        XCTAssertTrue(viewModel.playlists.first?.isSmart ?? false)
    }
}
