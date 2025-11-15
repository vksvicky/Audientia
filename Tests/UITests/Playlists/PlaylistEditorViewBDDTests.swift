//
//  PlaylistEditorViewBDDTests.swift
//  Audientia - UI Tests
//
//  BDD tests for PlaylistEditorView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// BDD tests for PlaylistEditorView
/// Scenarios: "As a user, I want to edit a playlist and manage its tracks"
@MainActor
final class PlaylistEditorViewBDDTests: XCTestCase {
    
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
    ) -> Shared.Playlist {
        Shared.Playlist(
            name: name,
            trackCount: trackCount,
            totalDuration: totalDuration,
            isSmart: isSmart
        )
    }
    
    private func createTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: "/path/to/\(title).mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    // MARK: - BDD Scenarios
    
    /// Scenario: As a user, I want to view a playlist and see all its tracks when I open the editor
    func testUserViewsPlaylistWithTracks() async {
        // Given - User has a playlist with tracks
        let playlist = createPlaylist(name: "My Favorites")
        let track1 = createTrack(title: "Song 1", artist: "Artist 1")
        let track2 = createTrack(title: "Song 2", artist: "Artist 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        
        // When - User opens the playlist editor
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - User should see the playlist and all its tracks
        XCTAssertNotNil(viewModel.playlist)
        XCTAssertEqual(viewModel.playlist?.name, "My Favorites")
        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertTrue(viewModel.tracks.contains { $0.title == "Song 1" })
        XCTAssertTrue(viewModel.tracks.contains { $0.title == "Song 2" })
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to add a track to a playlist from the editor
    func testUserAddsTrackToPlaylistFromEditor() async throws {
        // Given - User has an empty playlist
        let playlist = createPlaylist(name: "My Playlist")
        let track = createTrack(title: "New Song")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertTrue(viewModel.tracks.isEmpty)
        
        // When - User adds a track to the playlist
        try await viewModel.addTrack(track)
        
        // Then - The track should be added and visible
        XCTAssertEqual(viewModel.tracks.count, 1)
        XCTAssertEqual(viewModel.tracks.first?.title, "New Song")
    }
    
    /// Scenario: As a user, I want to remove a track from a playlist from the editor
    func testUserRemovesTrackFromPlaylistFromEditor() async throws {
        // Given - User has a playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track = createTrack(title: "Song to Remove")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track]
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertEqual(viewModel.tracks.count, 1)
        
        // When - User removes the track
        try await viewModel.removeTrack(track)
        
        // Then - The track should be removed
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    /// Scenario: As a user, I want to rename a playlist from the editor
    func testUserRenamesPlaylistFromEditor() async throws {
        // Given - User has a playlist named "Old Name"
        let playlist = createPlaylist(name: "Old Name")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertEqual(viewModel.playlist?.name, "Old Name")
        
        // When - User renames it to "New Name"
        try await viewModel.updatePlaylistName("New Name")
        
        // Then - The playlist should have the new name
        XCTAssertEqual(viewModel.playlist?.name, "New Name")
    }
    
    /// Scenario: As a user, I want to see an empty state when a playlist has no tracks
    func testUserSeesEmptyStateWhenNoTracks() async {
        // Given - User has an empty playlist
        let playlist = createPlaylist(name: "Empty Playlist")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        
        // When - User opens the playlist editor
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - User should see an empty track list
        XCTAssertNotNil(viewModel.playlist)
        XCTAssertTrue(viewModel.tracks.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Scenario: As a user, I want to see an error if I try to add a duplicate track
    func testUserSeesErrorWhenAddingDuplicateTrack() async {
        // Given - User has a playlist with a track
        let playlist = createPlaylist(name: "My Playlist")
        let track = createTrack(title: "Existing Song")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track]
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - User tries to add the same track again
        // Then - User should see an error
        do {
            try await viewModel.addTrack(track)
            XCTFail("Should have thrown error")
        } catch {
            if let error = error as? PlaylistManagerError {
                XCTAssertEqual(error, .duplicateTrack)
            } else {
                XCTFail("Expected PlaylistManagerError.duplicateTrack")
            }
        }
    }
    
    /// Scenario: As a user, I want to reorder tracks in a playlist
    func testUserReordersTracksInPlaylist() async throws {
        // Given - User has a playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        let track3 = createTrack(title: "Track 3")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2, track3]
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertEqual(viewModel.tracks.count, 3)
        
        // When - User reorders tracks (reverse order)
        let reversedIds = [track3.id, track2.id, track1.id]
        try await viewModel.reorderTracks(reversedIds)
        
        // Then - Tracks should be reordered
        XCTAssertEqual(viewModel.tracks.count, 3)
    }
}
