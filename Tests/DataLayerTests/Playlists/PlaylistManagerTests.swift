//
//  PlaylistManagerTests.swift
//  DataLayerTests
//
//  TDD tests for PlaylistManager following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// TDD tests for PlaylistManager
/// Following Right-BICEP principles:
/// - [Right]: Verify playlist operations produce correct results
/// - [B]oundary: Empty playlists, very large playlists, edge cases
/// - [I]nverse: Add track → Remove → Verify not in playlist
/// - [C]ross-check: Compare with manual operations
/// - [E]rror: Invalid operations, missing playlists, duplicate tracks
/// - [P]erformance: Large playlists, many operations
final class PlaylistManagerTests: XCTestCase {
    
    var playlistManager: PlaylistManager!
    private var mockIndexer: MockLibraryIndexer!
    
    override func setUp() {
        super.setUp()
        mockIndexer = MockLibraryIndexer()
        playlistManager = PlaylistManager(indexer: mockIndexer)
    }
    
    override func tearDown() {
        playlistManager = nil
        mockIndexer = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper to create a track for testing
    private func createTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3",
        fileSize: Int64 = 5_000_000,
        bitrate: Int = 320,
        sampleRate: Int = 44100,
        year: Int? = nil,
        genre: String? = nil,
        rating: Int? = nil
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate,
            year: year,
            trackNumber: nil,
            discNumber: nil,
            genre: genre,
            rating: rating
        )
    }
    
    // MARK: - [Right] Tests - Verify Correct Results
    
    /// Test creating a regular playlist
    func testCreateRegularPlaylist() async throws {
        // Given
        let playlistName = "My Playlist"
        
        // When
        let playlist = try await playlistManager.createPlaylist(name: playlistName)
        
        // Then
        XCTAssertEqual(playlist.name, playlistName)
        XCTAssertFalse(playlist.isSmart)
        XCTAssertEqual(playlist.trackCount, 0)
        XCTAssertEqual(playlist.totalDuration, 0.0)
    }
    
    /// Test creating a smart playlist
    func testCreateSmartPlaylist() async throws {
        // Given
        let playlistName = "Smart Playlist"
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .artist, operator: .equals, value: "Test Artist")
        ])
        
        // When
        let playlist = try await playlistManager.createSmartPlaylist(name: playlistName, rules: rules)
        
        // Then
        XCTAssertEqual(playlist.name, playlistName)
        XCTAssertTrue(playlist.isSmart)
        XCTAssertEqual(playlist.trackCount, 0)
    }
    
    /// Test getting a playlist by ID
    func testGetPlaylistById() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        
        // When
        let retrieved = await playlistManager.getPlaylist(by: playlist.id)
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, playlist.id)
        XCTAssertEqual(retrieved?.name, playlist.name)
    }
    
    /// Test getting all playlists
    func testGetAllPlaylists() async throws {
        // Given
        let playlist1 = try await playlistManager.createPlaylist(name: "Playlist 1")
        let playlist2 = try await playlistManager.createPlaylist(name: "Playlist 2")
        
        // When
        let allPlaylists = await playlistManager.getAllPlaylists()
        
        // Then
        XCTAssertEqual(allPlaylists.count, 2)
        XCTAssertTrue(allPlaylists.contains { $0.id == playlist1.id })
        XCTAssertTrue(allPlaylists.contains { $0.id == playlist2.id })
    }
    
    /// Test updating playlist name
    func testUpdatePlaylistName() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Old Name")
        let newName = "New Name"
        
        // When
        try await playlistManager.updatePlaylist(id: playlist.id, name: newName)
        
        // Then
        let updated = await playlistManager.getPlaylist(by: playlist.id)
        XCTAssertEqual(updated?.name, newName)
    }
    
    /// Test adding a track to a playlist
    func testAddTrackToPlaylist() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track", artist: "Test Artist")
        await mockIndexer.addTrack(track)
        
        // When
        try await playlistManager.addTrack(track, to: playlist.id)
        
        // Then
        let tracks = try await playlistManager.getTracks(in: playlist.id)
        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks.first?.id, track.id)
    }
    
    /// Test removing a track from a playlist
    func testRemoveTrackFromPlaylist() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track", artist: "Test Artist")
        await mockIndexer.addTrack(track)
        try await playlistManager.addTrack(track, to: playlist.id)
        
        // When
        try await playlistManager.removeTrack(track, from: playlist.id)
        
        // Then
        let tracks = try await playlistManager.getTracks(in: playlist.id)
        XCTAssertEqual(tracks.count, 0)
    }
    
    // MARK: - [B]oundary Tests
    
    /// Test creating playlist with empty name
    func testCreatePlaylistWithEmptyName() async {
        // Given
        let emptyName = ""
        
        // When/Then
        do {
            _ = try await playlistManager.createPlaylist(name: emptyName)
            XCTFail("Should have thrown error for empty name")
        } catch PlaylistManagerError.invalidPlaylistName {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test getting non-existent playlist
    func testGetNonExistentPlaylist() async {
        // Given
        let nonExistentId = UUID()
        
        // When
        let playlist = await playlistManager.getPlaylist(by: nonExistentId)
        
        // Then
        XCTAssertNil(playlist)
    }
    
    /// Test adding track to non-existent playlist
    func testAddTrackToNonExistentPlaylist() async {
        // Given
        let nonExistentId = UUID()
        let track = createTrack(title: "Test Track")
        await mockIndexer.addTrack(track)
        
        // When/Then
        do {
            try await playlistManager.addTrack(track, to: nonExistentId)
            XCTFail("Should have thrown error for non-existent playlist")
        } catch PlaylistManagerError.playlistNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test removing track from non-existent playlist
    func testRemoveTrackFromNonExistentPlaylist() async {
        // Given
        let nonExistentId = UUID()
        let track = createTrack(title: "Test Track")
        
        // When/Then
        do {
            try await playlistManager.removeTrack(track, from: nonExistentId)
            XCTFail("Should have thrown error for non-existent playlist")
        } catch PlaylistManagerError.playlistNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - [I]nverse Tests
    
    /// Test inverse relationship: Add track → Remove → Verify not in playlist
    func testAddThenRemoveTrack() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        await mockIndexer.addTrack(track)
        
        // When - Add track
        try await playlistManager.addTrack(track, to: playlist.id)
        let tracksAfterAdd = try await playlistManager.getTracks(in: playlist.id)
        XCTAssertEqual(tracksAfterAdd.count, 1)
        
        // When - Remove track
        try await playlistManager.removeTrack(track, from: playlist.id)
        
        // Then - Verify track is not in playlist
        let tracksAfterRemove = try await playlistManager.getTracks(in: playlist.id)
        XCTAssertEqual(tracksAfterRemove.count, 0)
        XCTAssertFalse(tracksAfterRemove.contains { $0.id == track.id })
    }
    
    /// Test inverse relationship: Create playlist → Delete → Verify not in list
    func testCreateThenDeletePlaylist() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        var allPlaylists = await playlistManager.getAllPlaylists()
        XCTAssertTrue(allPlaylists.contains { $0.id == playlist.id })
        
        // When
        try await playlistManager.deletePlaylist(id: playlist.id)
        
        // Then
        allPlaylists = await playlistManager.getAllPlaylists()
        XCTAssertFalse(allPlaylists.contains { $0.id == playlist.id })
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test cross-check: Manual track count vs playlist track count
    func testCrossCheckTrackCount() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        let tracks = [
            createTrack(title: "Track 1"),
            createTrack(title: "Track 2"),
            createTrack(title: "Track 3")
        ]
        for track in tracks {
            await mockIndexer.addTrack(track)
            try await playlistManager.addTrack(track, to: playlist.id)
        }
        
        // When
        let playlistTracks = try await playlistManager.getTracks(in: playlist.id)
        let retrievedPlaylist = await playlistManager.getPlaylist(by: playlist.id)
        
        // Then - Cross-check counts
        XCTAssertEqual(playlistTracks.count, tracks.count)
        XCTAssertEqual(retrievedPlaylist?.trackCount, tracks.count)
    }
    
    // MARK: - [E]rror Tests
    
    /// Test deleting non-existent playlist
    func testDeleteNonExistentPlaylist() async {
        // Given
        let nonExistentId = UUID()
        
        // When/Then
        do {
            try await playlistManager.deletePlaylist(id: nonExistentId)
            XCTFail("Should have thrown error for non-existent playlist")
        } catch PlaylistManagerError.playlistNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test updating non-existent playlist
    func testUpdateNonExistentPlaylist() async {
        // Given
        let nonExistentId = UUID()
        
        // When/Then
        do {
            try await playlistManager.updatePlaylist(id: nonExistentId, name: "New Name")
            XCTFail("Should have thrown error for non-existent playlist")
        } catch PlaylistManagerError.playlistNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test adding duplicate track to playlist
    func testAddDuplicateTrack() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Test Playlist")
        let track = createTrack(title: "Test Track")
        await mockIndexer.addTrack(track)
        try await playlistManager.addTrack(track, to: playlist.id)
        
        // When/Then
        do {
            try await playlistManager.addTrack(track, to: playlist.id)
            XCTFail("Should have thrown error for duplicate track")
        } catch PlaylistManagerError.duplicateTrack {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test performance: Adding many tracks to playlist
    func testPerformanceAddManyTracks() async throws {
        // Given
        let playlist = try await playlistManager.createPlaylist(name: "Large Playlist")
        let trackCount = 1000
        var tracks: [Track] = []
        
        for i in 0..<trackCount {
            let track = createTrack(title: "Track \(i)")
            await mockIndexer.addTrack(track)
            tracks.append(track)
        }
        
        // When
        let startTime = Date()
        for track in tracks {
            try await playlistManager.addTrack(track, to: playlist.id)
        }
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        let playlistTracks = try await playlistManager.getTracks(in: playlist.id)
        XCTAssertEqual(playlistTracks.count, trackCount)
        XCTAssertLessThan(duration, 2.0, "Adding 1000 tracks should take less than 2 seconds")
    }
    
    /// Test performance: Getting all playlists with many playlists
    func testPerformanceGetAllPlaylists() async throws {
        // Given
        let playlistCount = 100
        for i in 0..<playlistCount {
            _ = try await playlistManager.createPlaylist(name: "Playlist \(i)")
        }
        
        // When
        let startTime = Date()
        let allPlaylists = await playlistManager.getAllPlaylists()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(allPlaylists.count, playlistCount)
        XCTAssertLessThan(duration, 0.2, "Getting 100 playlists should take less than 200ms")
    }
    
    // MARK: - Mock Library Indexer
    
    private actor MockLibraryIndexer: LibraryIndexerProtocol {
    private var tracks: [UUID: Track] = [:]
    
    func addTrack(_ track: Track) {
        tracks[track.id] = track
    }
    
    func index(tracks: [Track]) async throws {
        for track in tracks {
            self.tracks[track.id] = track
        }
    }
    
    func remove(track: Track) async throws {
        tracks.removeValue(forKey: track.id)
    }
    
    func clear() async throws {
        tracks.removeAll()
    }
    
    func getTrack(by id: UUID) async -> Track? {
        tracks[id]
    }
    
    func getIndexedTrackCount() async -> Int {
        tracks.count
    }
    
    func getAllTracks() async -> [Track] {
        Array(tracks.values)
    }
    }
}
