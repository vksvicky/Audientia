//
//  PlaylistPanelViewModelBDDTests.swift
//  Audientia - UI Tests
//
//  BDD tests for PlaylistPanelViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
import Shared
import XCTest

@testable import Audientia

@MainActor
final class PlaylistPanelViewModelBDDTests: XCTestCase {
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

    private func createMockPlaylists() async throws {
        _ = try await mockPlaylistManager.createPlaylist(name: "My Favorites")
        _ = try await mockPlaylistManager.createPlaylist(name: "Workout Mix")
    }

    private func createMockTracks() async {
        let tracks = [
            Track(title: "The First Song", artist: "Artist Alpha", album: "Album One", duration: 200, filePath: "/a.mp3", fileSize: 100, bitrate: 320, sampleRate: 44100, year: 2020, trackNumber: 1, discNumber: 1, genre: "Pop", rating: 5),
            Track(title: "Second Track", artist: "Artist Beta", album: "Album Two", duration: 250, filePath: "/b.mp3", fileSize: 120, bitrate: 320, sampleRate: 44100, year: 2019, trackNumber: 2, discNumber: 1, genre: "Rock", rating: 4)
        ]
        await mockIndexer.setTracks(tracks)
    }

    // MARK: - BDD Scenarios

    func testAsAUserIWantToViewAllMyPlaylists() async throws {
        // Given: I have created several playlists
        try await createMockPlaylists()

        // When: I open the playlist panel
        await viewModel.loadPlaylists()

        // Then: I should see all my playlists listed
        XCTAssertFalse(viewModel.playlists.isEmpty)
        XCTAssertEqual(viewModel.playlists.count, 2)
        XCTAssertTrue(viewModel.playlists.contains(where: { $0.name == "My Favorites" }))
        XCTAssertTrue(viewModel.playlists.contains(where: { $0.name == "Workout Mix" }))
    }

    func testAsAUserIWantToSelectAPlaylistAndViewItsTracks() async throws {
        // Given: I have a playlist with tracks
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        try await mockPlaylistManager.addTrack(track, to: playlist.id)

        // When: I select a playlist
        await viewModel.selectPlaylist(playlist)

        // Then: I should see the tracks in that playlist
        XCTAssertEqual(viewModel.selectedPlaylist?.id, playlist.id)
        XCTAssertEqual(viewModel.tracks.count, 1)
        XCTAssertEqual(viewModel.tracks.first?.id, track.id)
    }

    func testAsAUserIWantToAddTracksToAPlaylist() async throws {
        // Given: I have a playlist and some tracks available
        try await createMockPlaylists()
        await createMockTracks()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first,
              let track = await mockIndexer.getAllTracks().first else {
            XCTFail("Expected playlist and track to exist")
            return
        }

        await viewModel.selectPlaylist(playlist)

        // When: I add a track to the playlist
        try await viewModel.addTrack(track)

        // Then: The track should appear in the playlist
        XCTAssertEqual(viewModel.tracks.count, 1)
        XCTAssertTrue(viewModel.tracks.contains(where: { $0.id == track.id }))
    }

    func testAsAUserIWantToRemoveTracksFromAPlaylist() async throws {
        // Given: I have a playlist with tracks
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
        XCTAssertEqual(viewModel.tracks.count, 1)

        // When: I remove a track from the playlist
        try await viewModel.removeTrack(track)

        // Then: The track should no longer appear in the playlist
        XCTAssertEqual(viewModel.tracks.count, 0)
        XCTAssertFalse(viewModel.tracks.contains(where: { $0.id == track.id }))
    }

    func testAsAUserIWantToCreateANewPlaylist() async throws {
        // Given: I am viewing my playlists
        try await createMockPlaylists()
        await viewModel.loadPlaylists()
        let initialCount = viewModel.playlists.count

        // When: I create a new playlist called "Road Trip"
        let newPlaylist = try await viewModel.createPlaylist(name: "Road Trip")

        // Then: The new playlist should appear in my list
        XCTAssertEqual(newPlaylist.name, "Road Trip")
        XCTAssertEqual(viewModel.playlists.count, initialCount + 1)
        XCTAssertTrue(viewModel.playlists.contains(where: { $0.name == "Road Trip" }))
    }

    func testAsAUserIWantToDeleteAPlaylist() async throws {
        // Given: I have a playlist I no longer want
        try await createMockPlaylists()
        await viewModel.loadPlaylists()

        guard let playlist = viewModel.playlists.first else {
            XCTFail("Expected playlist to exist")
            return
        }
        let initialCount = viewModel.playlists.count

        // When: I delete the playlist
        try await viewModel.deletePlaylist(playlist)

        // Then: The playlist should be removed from my list
        XCTAssertEqual(viewModel.playlists.count, initialCount - 1)
        XCTAssertFalse(viewModel.playlists.contains(where: { $0.id == playlist.id }))
    }

    func testAsAUserIWantToSeeAnEmptyStateWhenNoPlaylistsExist() async throws {
        // Given: I have not created any playlists yet
        // When: I open the playlist panel
        await viewModel.loadPlaylists()

        // Then: I should see an empty state message
        XCTAssertTrue(viewModel.playlists.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.lastError)
    }
}
