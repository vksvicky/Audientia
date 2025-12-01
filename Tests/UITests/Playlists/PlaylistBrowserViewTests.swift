//
//  PlaylistBrowserViewTests.swift
//  Audientia - UI Tests
//
//  TDD tests for PlaylistBrowserView following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import DataLayer
@testable import Shared

/// TDD tests for PlaylistBrowserView
/// Following Right-BICEP principles:
/// - [Right]: Verify view displays playlists correctly
/// - [B]oundary: Empty list, very large list, edge cases
/// - [I]nverse: Add playlist → Remove → Verify not displayed
/// - [C]ross-check: Compare view state with ViewModel state
/// - [E]rror: Network errors, invalid operations
/// - [P]erformance: View renders quickly with many playlists
@MainActor
final class PlaylistBrowserViewTests: XCTestCase {
    
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
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: View should initialise with PlaylistManager
    func testViewInitialisesWithPlaylistManager() {
        // Given - A PlaylistManager
        // When - Creating view with PlaylistManager
        let view = PlaylistBrowserView(playlistManager: mockPlaylistManager)
        
        // Then - View should be created
        XCTAssertNotNil(view)
    }
    
    /// Test: View should load playlists on appear
    func testViewLoadsPlaylistsOnAppear() async {
        // Given - PlaylistManager has playlists
        let playlist = createPlaylist(name: "Test Playlist")
        mockPlaylistManager.playlists = [playlist]
        
        // When - View appears (we test the ViewModel behavior)
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - ViewModel should have loaded playlists
        XCTAssertEqual(viewModel.playlists.count, 1)
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: View should handle empty playlist list
    func testViewHandlesEmptyPlaylistList() async {
        // Given - No playlists exist
        mockPlaylistManager.playlists = []
        
        // When - Loading playlists
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - ViewModel should have empty list
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    /// Test: View should handle many playlists
    func testViewHandlesManyPlaylists() async {
        // Given - Many playlists
        var playlists: [Playlist] = []
        for i in 0..<100 {
            playlists.append(createPlaylist(name: "Playlist \(i)"))
        }
        mockPlaylistManager.playlists = playlists
        
        // When - Loading playlists
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - ViewModel should have all playlists
        XCTAssertEqual(viewModel.playlists.count, 100)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Create then delete playlist should result in empty list
    func testCreateThenDeletePlaylist() async throws {
        // Given - No playlists
        mockPlaylistManager.playlists = []
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        XCTAssertTrue(viewModel.playlists.isEmpty)
        
        // When - Creating then deleting
        let playlist = try await viewModel.createPlaylist(name: "Temp")
        try await viewModel.deletePlaylist(id: playlist.id)
        
        // Then - List should be empty
        XCTAssertTrue(viewModel.playlists.isEmpty)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: View state should match ViewModel state
    func testViewStateMatchesViewModelState() async {
        // Given - ViewModel has playlists
        let playlist1 = createPlaylist(name: "Playlist 1")
        let playlist2 = createPlaylist(name: "Playlist 2")
        mockPlaylistManager.playlists = [playlist1, playlist2]
        
        // When - Loading playlists
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - ViewModel state should match manager state
        let managerPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(viewModel.playlists.count, managerPlaylists.count)
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: View should handle loading errors
    func testViewHandlesLoadingErrors() async {
        // Given - PlaylistManager will fail
        mockPlaylistManager.shouldFailCreate = true
        
        // When - Creating playlist
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        do {
            _ = try await viewModel.createPlaylist(name: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Then - Error should be set
            XCTAssertNotNil(viewModel.lastError)
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: View should handle large playlist lists efficiently
    func testViewHandlesLargePlaylistListEfficiently() async {
        // Given - Large number of playlists
        var playlists: [Playlist] = []
        for i in 0..<1000 {
            playlists.append(createPlaylist(name: "Playlist \(i)"))
        }
        mockPlaylistManager.playlists = playlists
        
        // When - Loading playlists
        let startTime = Date()
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time
        XCTAssertLessThan(duration, 0.2, "Loading should complete within 200ms")
        XCTAssertEqual(viewModel.playlists.count, 1000)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test: View should handle Unicode playlist names
    func testViewHandlesUnicodePlaylistNames() async throws {
        // Given - Unicode playlist name
        let unicodeName = "プレイリスト 🎵 播放列表"
        
        // When - Creating playlist
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        let playlist = try await viewModel.createPlaylist(name: unicodeName)
        
        // Then - Playlist should be created
        XCTAssertEqual(playlist.name, unicodeName)
    }
    
    /// Test: View should handle smart playlists
    func testViewHandlesSmartPlaylists() async {
        // Given - Smart playlists
        let smartPlaylist = createPlaylist(name: "Smart Playlist", isSmart: true)
        mockPlaylistManager.playlists = [smartPlaylist]
        
        // When - Loading playlists
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // Then - Smart playlist should be loaded
        XCTAssertTrue(viewModel.playlists.first?.isSmart ?? false)
    }
}
