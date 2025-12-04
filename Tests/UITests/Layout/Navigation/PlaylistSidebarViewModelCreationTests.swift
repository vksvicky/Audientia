//
//  PlaylistSidebarViewModelCreationTests.swift
//  Audientia
//
//  TDD tests for PlaylistSidebarViewModel playlist creation functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class PlaylistSidebarViewModelCreationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockPlaylistManager: PlaylistSidebarMockPlaylistManager!
    private var viewModel: PlaylistSidebarViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockPlaylistManager = PlaylistSidebarMockPlaylistManager()
        viewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPlaylistManager = nil
        super.tearDown()
    }
    
    // MARK: - Create Playlist Tests
    
    func testCreatePlaylist_WithValidName_CreatesPlaylist() async throws {
        // Given: No existing playlists
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        
        // When: Creating a playlist with valid name
        try await viewModel.createPlaylist(name: "My New Playlist")
        
        // Then: Playlist should be created and loaded
        let allPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(allPlaylists.count, 1)
        XCTAssertEqual(allPlaylists[0].name, "My New Playlist")
        XCTAssertEqual(viewModel.allPlaylists.count, 1)
        XCTAssertEqual(viewModel.allPlaylists[0].name, "My New Playlist")
    }
    
    func testCreatePlaylist_TrimsWhitespace() async throws {
        // Given: No existing playlists
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        
        // When: Creating a playlist with whitespace
        try await viewModel.createPlaylist(name: "  My Playlist  ")
        
        // Then: Playlist should be created with trimmed name
        let allPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(allPlaylists[0].name, "My Playlist")
    }
    
    func testCreatePlaylist_WithEmptyName_ThrowsError() async {
        // Given: No existing playlists
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        
        // When/Then: Creating a playlist with empty name should throw
        do {
            try await viewModel.createPlaylist(name: "")
            XCTFail("Expected error for empty name")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .invalidPlaylistName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreatePlaylist_WithWhitespaceOnlyName_ThrowsError() async {
        // Given: No existing playlists
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        
        // When/Then: Creating a playlist with whitespace-only name should throw
        do {
            try await viewModel.createPlaylist(name: "   ")
            XCTFail("Expected error for whitespace-only name")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .invalidPlaylistName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreatePlaylist_WithDuplicateName_ThrowsError() async {
        // Given: Existing playlist with name "My Playlist"
        let existingPlaylist = createTestPlaylist(name: "My Playlist")
        await mockPlaylistManager.setPlaylists([existingPlaylist])
        await viewModel.loadPlaylists()
        
        // When/Then: Creating a playlist with duplicate name should throw
        do {
            try await viewModel.createPlaylist(name: "My Playlist")
            XCTFail("Expected error for duplicate name")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .duplicatePlaylist)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreatePlaylist_WithDuplicateNameCaseInsensitive_ThrowsError() async {
        // Given: Existing playlist with name "My Playlist"
        let existingPlaylist = createTestPlaylist(name: "My Playlist")
        await mockPlaylistManager.setPlaylists([existingPlaylist])
        await viewModel.loadPlaylists()
        
        // When/Then: Creating a playlist with duplicate name (case-insensitive) should throw
        do {
            try await viewModel.createPlaylist(name: "my playlist")
            XCTFail("Expected error for duplicate name (case-insensitive)")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .duplicatePlaylist)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreatePlaylist_WhenManagerFails_ThrowsError() async {
        // Given: Manager configured to fail
        await mockPlaylistManager.setPlaylists([])
        await mockPlaylistManager.setShouldFailCreate(true)
        await viewModel.loadPlaylists()
        
        // When/Then: Creating a playlist should throw
        do {
            try await viewModel.createPlaylist(name: "My Playlist")
            XCTFail("Expected error when manager fails")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    func testCreatePlaylist_ReloadsPlaylistsAfterCreation() async throws {
        // Given: Existing playlists
        let playlist1 = createTestPlaylist(name: "Existing Playlist")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.allPlaylists.count, 1)
        
        // When: Creating a new playlist
        try await viewModel.createPlaylist(name: "New Playlist")
        
        // Then: Playlists should be reloaded to include the new one
        XCTAssertEqual(viewModel.allPlaylists.count, 2)
        let playlistNames = viewModel.allPlaylists.map { $0.name }.sorted()
        XCTAssertEqual(playlistNames, ["Existing Playlist", "New Playlist"])
    }
    
    // MARK: - Create Smart Playlist Tests
    
    func testCreateSmartPlaylist_WithValidNameAndRules_CreatesSmartPlaylist() async throws {
        // Given: No existing playlists and valid rules
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When: Creating a smart playlist with valid name and rules
        try await viewModel.createSmartPlaylist(name: "My Smart Playlist", rules: rules)
        
        // Then: Smart playlist should be created and loaded
        let allPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(allPlaylists.count, 1)
        XCTAssertEqual(allPlaylists[0].name, "My Smart Playlist")
        XCTAssertTrue(allPlaylists[0].isSmart)
        XCTAssertEqual(viewModel.allPlaylists.count, 1)
        XCTAssertEqual(viewModel.allPlaylists[0].name, "My Smart Playlist")
        XCTAssertTrue(viewModel.allPlaylists[0].isSmart)
    }
    
    func testCreateSmartPlaylist_TrimsWhitespace() async throws {
        // Given: No existing playlists and valid rules
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When: Creating a smart playlist with whitespace
        try await viewModel.createSmartPlaylist(name: "  My Smart Playlist  ", rules: rules)
        
        // Then: Smart playlist should be created with trimmed name
        let allPlaylists = await mockPlaylistManager.getAllPlaylists()
        XCTAssertEqual(allPlaylists[0].name, "My Smart Playlist")
    }
    
    func testCreateSmartPlaylist_WithEmptyName_ThrowsError() async {
        // Given: No existing playlists and valid rules
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When/Then: Creating a smart playlist with empty name should throw
        do {
            try await viewModel.createSmartPlaylist(name: "", rules: rules)
            XCTFail("Expected error for empty name")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .invalidPlaylistName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreateSmartPlaylist_WithInvalidRules_ThrowsError() async {
        // Given: No existing playlists and invalid rules (empty)
        await mockPlaylistManager.setPlaylists([])
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [])
        
        // When/Then: Creating a smart playlist with invalid rules should throw
        do {
            try await viewModel.createSmartPlaylist(name: "My Smart Playlist", rules: rules)
            XCTFail("Expected error for invalid rules")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .invalidRules)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreateSmartPlaylist_WithDuplicateName_ThrowsError() async {
        // Given: Existing playlist with name "My Playlist"
        let existingPlaylist = createTestPlaylist(name: "My Playlist")
        await mockPlaylistManager.setPlaylists([existingPlaylist])
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When/Then: Creating a smart playlist with duplicate name should throw
        do {
            try await viewModel.createSmartPlaylist(name: "My Playlist", rules: rules)
            XCTFail("Expected error for duplicate name")
        } catch let error as PlaylistManagerError {
            XCTAssertEqual(error, .duplicatePlaylist)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreateSmartPlaylist_WhenManagerFails_ThrowsError() async {
        // Given: Manager configured to fail
        await mockPlaylistManager.setPlaylists([])
        await mockPlaylistManager.setShouldFailCreate(true)
        await viewModel.loadPlaylists()
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When/Then: Creating a smart playlist should throw
        do {
            try await viewModel.createSmartPlaylist(name: "My Smart Playlist", rules: rules)
            XCTFail("Expected error when manager fails")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is PlaylistManagerError)
        }
    }
    
    func testCreateSmartPlaylist_ReloadsPlaylistsAfterCreation() async throws {
        // Given: Existing playlists
        let playlist1 = createTestPlaylist(name: "Existing Playlist")
        await mockPlaylistManager.setPlaylists([playlist1])
        await viewModel.loadPlaylists()
        XCTAssertEqual(viewModel.allPlaylists.count, 1)
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .rating, operator: .equals, value: "5")
        ])
        
        // When: Creating a new smart playlist
        try await viewModel.createSmartPlaylist(name: "New Smart Playlist", rules: rules)
        
        // Then: Playlists should be reloaded to include the new one
        XCTAssertEqual(viewModel.allPlaylists.count, 2)
        let playlistNames = viewModel.allPlaylists.map { $0.name }.sorted()
        XCTAssertEqual(playlistNames, ["Existing Playlist", "New Smart Playlist"])
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlaylist(name: String, isSmart: Bool = false) -> Playlist {
        Playlist(
            id: UUID(),
            name: name,
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: isSmart
        )
    }
}
