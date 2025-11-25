//
//  PlaylistPanelViewModelTests.swift
//  Audientia - UI Tests
//
//  TDD tests for PlaylistPanelViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
import Shared
import XCTest

@testable import Audientia

@MainActor
final class PlaylistPanelViewModelTests: XCTestCase {
    var viewModel: PlaylistPanelViewModel!
    var mockPlaylistManager: MockPlaylistManager!
    var mockIndexer: MockLibraryIndexer!

    override func setUp() {
        super.setUp()
        mockIndexer = MockLibraryIndexer()
        mockPlaylistManager = MockPlaylistManager()
        viewModel = PlaylistPanelViewModel(
            playlistManager: mockPlaylistManager,
            indexer: mockIndexer
        )
    }

    override func tearDown() {
        viewModel = nil
        mockPlaylistManager = nil
        mockIndexer = nil
        super.tearDown()
    }

    // MARK: - Test Data

    private func createMockPlaylists() async throws {
        _ = try await mockPlaylistManager.createPlaylist(name: "My Favorites")
        _ = try await mockPlaylistManager.createPlaylist(name: "Workout Mix")
    }

    private func createMockTracks() async {
        let tracks = [
            Track(title: "Song A", artist: "Artist X", album: "Album 1", duration: 200, filePath: "/a.mp3", fileSize: 100, bitrate: 320, sampleRate: 44100, year: 2020, trackNumber: 1, discNumber: 1, genre: "Pop", rating: 5),
            Track(title: "Song B", artist: "Artist Y", album: "Album 2", duration: 250, filePath: "/b.mp3", fileSize: 120, bitrate: 320, sampleRate: 44100, year: 2019, trackNumber: 2, discNumber: 1, genre: "Rock", rating: 4)
        ]
        await mockIndexer.setTracks(tracks)
    }

    // MARK: - Right Results

    func testLoadPlaylists() async throws {
        // Given: Mock playlists exist
        try await createMockPlaylists()

        // When: Loading playlists
        await viewModel.loadPlaylists()

        // Then: Should have 2 playlists
        XCTAssertEqual(viewModel.playlists.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.lastError)
    }

    func testSelectPlaylist() async throws {
        // Given: Playlists are loaded
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        // When: Selecting a playlist and adding a track
        await viewModel.selectPlaylist(playlist)
        try await viewModel.addTrack(track)

        // Then: Selected playlist should be set and tracks should be loaded
        XCTAssertEqual(viewModel.selectedPlaylist?.id, playlist.id)
        XCTAssertEqual(viewModel.tracks.count, 1)
    }

    func testAddTrackToPlaylist() async throws {
        // Given: Playlist is selected
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        await viewModel.selectPlaylist(playlist)

        // When: Adding a track
        try await viewModel.addTrack(track)

        // Then: Track should be added
        XCTAssertTrue(mockPlaylistManager.addTrackCalled)
        XCTAssertEqual(mockPlaylistManager.addTrackId, playlist.id)
        XCTAssertEqual(mockPlaylistManager.addTrackTrack?.id, track.id)
        XCTAssertEqual(viewModel.tracks.count, 1)
    }

    func testRemoveTrackFromPlaylist() async throws {
        // Given: Playlist with tracks
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        await viewModel.selectPlaylist(playlist)
        try await viewModel.addTrack(track)

        // When: Removing a track
        try await viewModel.removeTrack(track)

        // Then: Track should be removed
        XCTAssertTrue(mockPlaylistManager.removeTrackCalled)
        XCTAssertEqual(mockPlaylistManager.removeTrackId, playlist.id)
        XCTAssertEqual(mockPlaylistManager.removeTrackTrack?.id, track.id)
        XCTAssertEqual(viewModel.tracks.count, 0)
    }

    func testCreatePlaylist() async throws {
        // Given: ViewModel is initialized
        try await createMockPlaylists()
        await viewModel.loadPlaylists()
        let initialCount = viewModel.playlists.count

        // When: Creating a new playlist
        let newPlaylist = try await viewModel.createPlaylist(name: "New Playlist")

        // Then: Playlist should be created and added to list
        XCTAssertEqual(newPlaylist.name, "New Playlist")
        XCTAssertEqual(viewModel.playlists.count, initialCount + 1)
        XCTAssertTrue(mockPlaylistManager.createPlaylistCalled)
    }

    func testDeletePlaylist() async throws {
        // Given: Playlists exist
        try await createMockPlaylists()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first else {
            XCTFail("Expected playlist to exist")
            return
        }
        let initialCount = viewModel.playlists.count

        // When: Deleting a playlist
        try await viewModel.deletePlaylist(playlist)

        // Then: Playlist should be deleted
        XCTAssertTrue(mockPlaylistManager.deletePlaylistCalled)
        XCTAssertEqual(mockPlaylistManager.deletePlaylistId, playlist.id)
        XCTAssertEqual(viewModel.playlists.count, initialCount - 1)
    }

    // MARK: - Boundary Conditions

    func testLoadEmptyPlaylists() async throws {
        // Given: No playlists exist
        // When: Loading playlists
        await viewModel.loadPlaylists()

        // Then: Should have empty list
        XCTAssertTrue(viewModel.playlists.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSelectNonexistentPlaylist() async throws {
        // Given: Playlists are loaded
        try await createMockPlaylists()
        await viewModel.loadPlaylists()

        let fakePlaylist = Playlist(name: "Fake", trackCount: 0, totalDuration: 0.0, isSmart: false)

        // When: Selecting a non-existent playlist
        await viewModel.selectPlaylist(fakePlaylist)

        // Then: Should handle gracefully (tracks should be empty)
        XCTAssertEqual(viewModel.selectedPlaylist?.id, fakePlaylist.id)
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }

    func testAddDuplicateTrack() async throws {
        // Given: Playlist with a track
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        await viewModel.selectPlaylist(playlist)
        try await viewModel.addTrack(track)

        // When: Adding the same track again
        // Then: Should throw duplicate error
        do {
            try await viewModel.addTrack(track)
            XCTFail("Should have thrown duplicateTrack error")
        } catch PlaylistManagerError.duplicateTrack {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Error Conditions

    func testLoadPlaylistsWithError() async throws {
        // Given: Manager that fails
        mockPlaylistManager.shouldFailCreate = true

        // When: Creating a playlist
        // Then: Should handle error
        do {
            _ = try await viewModel.createPlaylist(name: "")
            XCTFail("Should have thrown error")
        } catch PlaylistManagerError.invalidPlaylistName {
            // Expected
            XCTAssertNotNil(viewModel.lastError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAddTrackWithError() async throws {
        // Given: Playlist selected, manager set to fail
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        await viewModel.selectPlaylist(playlist)
        mockPlaylistManager.shouldFailAddTrack = true

        // When: Adding a track
        // Then: Should handle error
        do {
            try await viewModel.addTrack(track)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(viewModel.lastError)
        }
    }

    func testRemoveTrackWithError() async throws {
        // Given: Playlist selected, manager set to fail
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        await viewModel.selectPlaylist(playlist)
        mockPlaylistManager.shouldFailRemoveTrack = true

        // When: Removing a track
        // Then: Should handle error
        do {
            try await viewModel.removeTrack(track)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(viewModel.lastError)
        }
    }

    // MARK: - Cross-Checking

    func testPlaylistCountMatchesManager() async throws {
        // Given: Playlists in manager
        try await createMockPlaylists()

        // When: Loading playlists
        await viewModel.loadPlaylists()

        // Then: Count should match manager
        let managerPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(viewModel.playlists.count, managerPlaylists.count)
    }

    // MARK: - Performance Characteristics

    func testLoadManyPlaylists() async throws {
        // Given: Many playlists
        for i in 0..<100 {
            _ = try await mockPlaylistManager.createPlaylist(name: "Playlist \(i)")
        }

        // When: Loading playlists
        let startTime = Date()
        await viewModel.loadPlaylists()
        let duration = Date().timeIntervalSince(startTime)

        // Then: Should complete in reasonable time (< 1 second)
        XCTAssertLessThan(duration, 1.0)
        XCTAssertEqual(viewModel.playlists.count, 100)
    }
}
