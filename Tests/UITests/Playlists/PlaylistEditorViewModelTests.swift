//
//  PlaylistEditorViewModelTests.swift
//  Audientia - UI Tests
//
//  TDD tests for PlaylistEditorViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// TDD tests for PlaylistEditorViewModel
/// Following Right-BICEP principles:
/// - [Right]: Verify playlist editing operations produce correct results
/// - [B]oundary: Empty playlist, very large playlists, edge cases
/// - [I]nverse: Add track → Remove → Verify not in playlist
/// - [C]ross-check: Compare with direct PlaylistManager calls
/// - [E]rror: Invalid operations, missing playlists, duplicate tracks
/// - [P]erformance: Load tracks < 200ms, operations complete quickly
@MainActor
final class PlaylistEditorViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: PlaylistEditorViewModel!
    private var mockPlaylistManager: MockPlaylistManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockPlaylistManager = MockPlaylistManager()
        viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
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
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: ViewModel should load playlist tracks on initialisation
    func testLoadsPlaylistTracksOnInit() async throws {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        
        // When - Loading playlist
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel should have tracks
        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertTrue(viewModel.tracks.contains { $0.id == track1.id })
        XCTAssertTrue(viewModel.tracks.contains { $0.id == track2.id })
    }
    
    /// Test: ViewModel should add a track to playlist
    func testAddsTrackToPlaylist() async throws {
        // Given - A playlist and a track
        let playlist = createPlaylist(name: "My Playlist")
        let track = createTrack(title: "New Track")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Adding track
        try await viewModel.addTrack(track)
        
        // Then - Track should be added
        XCTAssertTrue(mockPlaylistManager.addTrackCalled)
        XCTAssertEqual(mockPlaylistManager.addTrackId, playlist.id)
        XCTAssertEqual(mockPlaylistManager.addTrackTrack?.id, track.id)
        XCTAssertEqual(viewModel.tracks.count, 1)
    }
    
    /// Test: ViewModel should remove a track from playlist
    func testRemovesTrackFromPlaylist() async throws {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track = createTrack(title: "Track 1")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track]
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Removing track
        try await viewModel.removeTrack(track)
        
        // Then - Track should be removed
        XCTAssertTrue(mockPlaylistManager.removeTrackCalled)
        XCTAssertEqual(mockPlaylistManager.removeTrackId, playlist.id)
        XCTAssertEqual(mockPlaylistManager.removeTrackTrack?.id, track.id)
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    /// Test: ViewModel should update playlist name
    func testUpdatesPlaylistName() async throws {
        // Given - A playlist
        let playlist = createPlaylist(name: "Old Name")
        mockPlaylistManager.playlists = [playlist]
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Updating name
        let newName = "New Name"
        try await viewModel.updatePlaylistName(newName)
        
        // Then - Name should be updated
        XCTAssertTrue(mockPlaylistManager.updatePlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.updatePlaylistName, newName)
        XCTAssertEqual(viewModel.playlist?.name, newName)
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: ViewModel should handle empty playlist
    func testHandlesEmptyPlaylist() async throws {
        // Given - An empty playlist
        let playlist = createPlaylist(name: "Empty Playlist", trackCount: 0)
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        
        // When - Loading playlist
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel should have empty tracks
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    /// Test: ViewModel should handle playlist with many tracks
    func testHandlesPlaylistWithManyTracks() async throws {
        // Given - A playlist with many tracks
        let playlist = createPlaylist(name: "Large Playlist")
        var tracks: [Track] = []
        for i in 0..<1000 {
            tracks.append(createTrack(title: "Track \(i)"))
        }
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = tracks
        
        // When - Loading playlist
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel should have all tracks
        XCTAssertEqual(viewModel.tracks.count, 1000)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Add track then remove should result in empty list
    func testAddThenRemoveTrack() async throws {
        // Given - An empty playlist
        let playlist = createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertTrue(viewModel.tracks.isEmpty)
        
        // When - Adding then removing track
        try await viewModel.addTrack(track)
        try await viewModel.removeTrack(track)
        
        // Then - List should be empty again
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: ViewModel tracks should match PlaylistManager tracks
    func testTracksMatchPlaylistManager() async throws {
        // Given - PlaylistManager has specific tracks
        let playlist = createPlaylist(name: "Test Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        
        // When - Loading playlist
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel tracks should match
        let managerTracks = try await mockPlaylistManager.getTracks(in: playlist.id)
        XCTAssertEqual(viewModel.tracks.count, managerTracks.count)
        for track in viewModel.tracks {
            XCTAssertTrue(managerTracks.contains { $0.id == track.id })
        }
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: ViewModel should handle add track failure
    func testHandlesAddTrackFailure() async {
        // Given - PlaylistManager will fail to add
        let playlist = createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        mockPlaylistManager.shouldFailAddTrack = true
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Adding track
        // Then - Should throw error
        do {
            try await viewModel.addTrack(track)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    /// Test: ViewModel should handle remove track failure
    func testHandlesRemoveTrackFailure() async {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track]
        mockPlaylistManager.shouldFailRemoveTrack = true
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Removing track
        // Then - Should throw error
        do {
            try await viewModel.removeTrack(track)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    /// Test: ViewModel should handle duplicate track
    func testHandlesDuplicateTrack() async {
        // Given - A playlist with a track
        let playlist = createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track]
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Adding the same track again
        // Then - Should throw duplicate error
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
    
    // MARK: - [P]erformance Tests
    
    /// Test: Loading tracks should complete quickly
    func testLoadTracksPerformance() async throws {
        // Given - Many tracks
        let playlist = createPlaylist(name: "Large Playlist")
        var tracks: [Track] = []
        for i in 0..<1000 {
            tracks.append(createTrack(title: "Track \(i)"))
        }
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = tracks
        
        // When - Loading tracks
        let startTime = Date()
        await viewModel.loadPlaylist(id: playlist.id)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 200ms
        XCTAssertLessThan(duration, 0.2, "Loading tracks should complete within 200ms")
        XCTAssertEqual(viewModel.tracks.count, 1000)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test: ViewModel should handle missing playlist
    func testHandlesMissingPlaylist() async {
        // Given - Playlist doesn't exist
        let nonExistentId = UUID()
        
        // When - Loading playlist
        await viewModel.loadPlaylist(id: nonExistentId)
        
        // Then - Playlist should be nil
        XCTAssertNil(viewModel.playlist)
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    /// Test: ViewModel should handle smart playlists
    func testHandlesSmartPlaylists() async throws {
        // Given - A smart playlist
        let smartPlaylist = createPlaylist(name: "Smart Playlist", isSmart: true)
        mockPlaylistManager.playlists = [smartPlaylist]
        mockPlaylistManager.tracks[smartPlaylist.id] = []
        
        // When - Loading playlist
        await viewModel.loadPlaylist(id: smartPlaylist.id)
        
        // Then - Should load smart playlist
        XCTAssertNotNil(viewModel.playlist)
        XCTAssertTrue(viewModel.playlist?.isSmart ?? false)
    }
}
