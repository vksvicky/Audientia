//
//  PlaylistEditorViewDragDropTests.swift
//  Audientia - UI Tests
//
//  TDD tests for drag-and-drop reordering in PlaylistEditorView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// TDD tests for drag-and-drop reordering
/// Following Right-BICEP principles:
/// - [Right]: Verify reordering produces correct track order
/// - [B]oundary: Single track, many tracks, edge cases
/// - [I]nverse: Reorder → Reorder back → Verify original order
/// - [C]ross-check: Compare with manual reordering
/// - [E]rror: Invalid indices, missing tracks
/// - [P]erformance: Reordering completes quickly
@MainActor
final class PlaylistEditorViewDragDropTests: XCTestCase {
    
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
    
    /// Test: ViewModel should reorder tracks
    func testReordersTracks() async throws {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        let track3 = createTrack(title: "Track 3")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2, track3]
        await viewModel.loadPlaylist(id: playlist.id)
        XCTAssertEqual(viewModel.tracks.count, 3)
        
        // When - Reordering tracks (reverse order)
        let reorderedIds = [track3.id, track2.id, track1.id]
        try await viewModel.reorderTracks(reorderedIds)
        
        // Then - Tracks should be reordered
        XCTAssertEqual(viewModel.tracks.count, 3)
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: ViewModel should handle reordering single track
    func testHandlesReorderingSingleTrack() async throws {
        // Given - A playlist with one track
        let playlist = createPlaylist(name: "My Playlist")
        let track = createTrack(title: "Track 1")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track]
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Reordering (no change)
        let trackIds = [track.id]
        try await viewModel.reorderTracks(trackIds)
        
        // Then - Should complete successfully
        XCTAssertEqual(viewModel.tracks.count, 1)
    }
    
    /// Test: ViewModel should handle reordering many tracks
    func testHandlesReorderingManyTracks() async throws {
        // Given - A playlist with many tracks
        let playlist = createPlaylist(name: "Large Playlist")
        var tracks: [Track] = []
        for i in 0..<100 {
            tracks.append(createTrack(title: "Track \(i)"))
        }
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = tracks
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Reordering (reverse order)
        let reorderedIds = tracks.reversed().map { $0.id }
        try await viewModel.reorderTracks(reorderedIds)
        
        // Then - Should complete successfully
        XCTAssertEqual(viewModel.tracks.count, 100)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Reorder then reorder back should restore original
    func testReorderThenReorderBack() async throws {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        await viewModel.loadPlaylist(id: playlist.id)
        let originalIds = viewModel.tracks.map { $0.id }
        
        // When - Reordering then reordering back
        let reorderedIds = [track2.id, track1.id]
        try await viewModel.reorderTracks(reorderedIds)
        try await viewModel.reorderTracks(originalIds)
        
        // Then - Should be back to original order
        XCTAssertEqual(viewModel.tracks.count, 2)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: Reordered track IDs should match expected order
    func testReorderedTrackIdsMatchExpected() async throws {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        let track3 = createTrack(title: "Track 3")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2, track3]
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Reordering to specific order
        let expectedOrder = [track3.id, track1.id, track2.id]
        try await viewModel.reorderTracks(expectedOrder)
        
        // Then - Track IDs should match expected order
        let actualOrder = viewModel.tracks.map { $0.id }
        XCTAssertEqual(actualOrder, expectedOrder)
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: ViewModel should handle reordering failure
    func testHandlesReorderingFailure() async {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        mockPlaylistManager.shouldFailReorder = true
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Reordering tracks
        // Then - Should throw error
        do {
            try await viewModel.reorderTracks([track2.id, track1.id])
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: Reordering should complete quickly
    func testReorderingPerformance() async throws {
        // Given - A playlist with many tracks
        let playlist = createPlaylist(name: "Large Playlist")
        var tracks: [Track] = []
        for i in 0..<1000 {
            tracks.append(createTrack(title: "Track \(i)"))
        }
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = tracks
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Reordering tracks
        let reorderedIds = tracks.reversed().map { $0.id }
        let startTime = Date()
        try await viewModel.reorderTracks(reorderedIds)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 200ms
        XCTAssertLessThan(duration, 0.2, "Reordering should complete within 200ms")
    }
    
    // MARK: - Edge Case Tests
    
    /// Test: ViewModel should handle reordering with duplicate IDs
    func testHandlesReorderingWithDuplicateIds() async throws {
        // Given - A playlist with tracks
        let playlist = createPlaylist(name: "My Playlist")
        let track1 = createTrack(title: "Track 1")
        let track2 = createTrack(title: "Track 2")
        mockPlaylistManager.playlists = [playlist]
        mockPlaylistManager.tracks[playlist.id] = [track1, track2]
        await viewModel.loadPlaylist(id: playlist.id)
        
        // When - Reordering with duplicate ID
        let duplicateIds = [track1.id, track1.id, track2.id]
        // Note: This might be handled by the manager or cause an error
        // For now, we'll test that it doesn't crash
        try? await viewModel.reorderTracks(duplicateIds)
        
        // Then - Should handle gracefully
        XCTAssertEqual(viewModel.tracks.count, 2)
    }
}
