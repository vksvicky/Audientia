//
//  PlaylistEditorViewTests.swift
//  Audientia - UI Tests
//
//  TDD tests for PlaylistEditorView following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import DataLayer
@testable import Shared

/// TDD tests for PlaylistEditorView
/// Following Right-BICEP principles:
/// - [Right]: Verify view displays playlist and tracks correctly
/// - [B]oundary: Empty playlist, very large playlist, edge cases
/// - [I]nverse: Add track → Remove → Verify not displayed
/// - [C]ross-check: Compare view state with ViewModel state
/// - [E]rror: Network errors, invalid operations
/// - [P]erformance: View renders quickly with many tracks
@MainActor
final class PlaylistEditorViewTests: XCTestCase {
    
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
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: View should initialize with PlaylistManager and playlist ID
    func testViewInitializesWithPlaylistManagerAndId() {
        // Given - A PlaylistManager and playlist ID
        let playlistId = UUID()
        
        // When - Creating view
        let view = PlaylistEditorView(playlistManager: mockPlaylistManager, playlistId: playlistId)
        
        // Then - View should be created
        XCTAssertNotNil(view)
    }
    
    /// Test: View should load playlist on appear
    func testViewLoadsPlaylistOnAppear() async {
        // Given - PlaylistManager has a playlist
        let playlist = createPlaylist(name: "Test Playlist")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        
        // When - View appears (we test the ViewModel behavior)
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel should have loaded playlist
        XCTAssertNotNil(viewModel.playlist)
        XCTAssertEqual(viewModel.playlist?.name, "Test Playlist")
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: View should handle empty playlist
    func testViewHandlesEmptyPlaylist() async {
        // Given - An empty playlist
        let playlist = createPlaylist(name: "Empty Playlist", trackCount: 0)
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        
        // When - Loading playlist
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel should have empty tracks
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    /// Test: View should handle playlist with many tracks
    func testViewHandlesPlaylistWithManyTracks() async {
        // Given - A playlist with many tracks
        let playlist = createPlaylist(name: "Large Playlist")
        var tracks: [Track] = []
        for i in 0..<100 {
            tracks.append(createTrack(title: "Track \(i)"))
        }
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = tracks
        
        // When - Loading playlist
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel should have all tracks
        XCTAssertEqual(viewModel.tracks.count, 100)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Add track then remove should result in empty list
    func testAddThenRemoveTrack() async throws {
        // Given - An empty playlist
        let playlist = createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = []
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertTrue(viewModel.tracks.isEmpty)
        
        // When - Adding then removing track
        try await viewModel.addTrack(track)
        try await viewModel.removeTrack(track)
        
        // Then - List should be empty again
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: View state should match ViewModel state
    func testViewStateMatchesViewModelState() async {
        // Given - ViewModel has tracks
        let playlist = createPlaylist(name: "Test Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        
        // When - Loading playlist
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        
        // Then - ViewModel state should match manager state
        let managerTracks = try? await mockPlaylistManager.getTracks(in: playlist.id)
        XCTAssertEqual(viewModel.tracks.count, managerTracks?.count ?? 0)
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: View should handle loading errors
    func testViewHandlesLoadingErrors() async {
        // Given - PlaylistManager will fail
        let playlist = createPlaylist(name: "Test Playlist")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.shouldFailAddTrack = true
        
        // When - Adding track
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        let track = createTrack(title: "Test Track")
        
        do {
            try await viewModel.addTrack(track)
            XCTFail("Should have thrown error")
        } catch {
            // Then - Error should be set
            XCTAssertNotNil(viewModel.lastError)
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: View should handle large track lists efficiently
    func testViewHandlesLargeTrackListEfficiently() async {
        // Given - Large number of tracks
        let playlist = createPlaylist(name: "Large Playlist")
        var tracks: [Track] = []
        for i in 0..<1000 {
            tracks.append(createTrack(title: "Track \(i)"))
        }
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = tracks
        
        // When - Loading playlist
        let startTime = Date()
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: playlist.id)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time
        XCTAssertLessThan(duration, 0.2, "Loading should complete within 200ms")
        XCTAssertEqual(viewModel.tracks.count, 1000)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test: View should handle missing playlist
    func testViewHandlesMissingPlaylist() async {
        // Given - Playlist doesn't exist
        let nonExistentId = UUID()
        
        // When - Loading playlist
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: nonExistentId)
        
        // Then - Playlist should be nil
        XCTAssertNil(viewModel.playlist)
        XCTAssertTrue(viewModel.tracks.isEmpty)
    }
    
    /// Test: View should handle smart playlists
    func testViewHandlesSmartPlaylists() async {
        // Given - A smart playlist
        let smartPlaylist = createPlaylist(name: "Smart Playlist", isSmart: true)
        mockPlaylistManager.playlists = [smartPlaylist]
        mockPlaylistManager.tracks[smartPlaylist.id] = []
        
        // When - Loading playlist
        let viewModel = PlaylistEditorViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylist(id: smartPlaylist.id)
        
        // Then - Smart playlist should be loaded
        XCTAssertTrue(viewModel.playlist?.isSmart ?? false)
    }
}
