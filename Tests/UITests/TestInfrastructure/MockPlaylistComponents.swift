//
//  MockPlaylistComponents.swift
//  Audientia - UI Test Infrastructure
//
//  Mock implementations of playlist components for UI testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

@testable import DataLayer
@testable import Shared

// MARK: - Mock PlaylistManager

@MainActor
public final class MockPlaylistManager: PlaylistManagerProtocol {
    public var playlists: [Shared.Playlist] = []
    
    public var createPlaylistCalled = false
    public var createPlaylistName: String?
    public var shouldFailCreate = false
    
    public var deletePlaylistCalled = false
    public var deletePlaylistId: UUID?
    public var shouldFailDelete = false
    
    public var updatePlaylistCalled = false
    public var updatePlaylistId: UUID?
    public var updatePlaylistName: String?
    public var shouldFailUpdate = false
    
    public init() {}
    
    public func createPlaylist(name: String) async throws -> Shared.Playlist {
        createPlaylistCalled = true
        createPlaylistName = name
        
        if shouldFailCreate || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        let playlist = Shared.Playlist(name: name, trackCount: 0, totalDuration: 0.0, isSmart: false)
        playlists.append(playlist)
        return playlist
    }
    
    public func createSmartPlaylist(name: String, rules: SmartPlaylistRules) async throws -> Shared.Playlist {
        if shouldFailCreate || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        let playlist = Shared.Playlist(name: name, trackCount: 0, totalDuration: 0.0, isSmart: true)
        playlists.append(playlist)
        return playlist
    }
    
    public func getPlaylist(by id: UUID) async -> Shared.Playlist? {
        playlists.first { $0.id == id }
    }
    
    public func getAllPlaylists() async -> [Shared.Playlist] {
        playlists
    }
    
    public func updatePlaylist(id: UUID, name: String) async throws {
        updatePlaylistCalled = true
        updatePlaylistId = id
        updatePlaylistName = name
        
        if shouldFailUpdate {
            throw PlaylistManagerError.playlistNotFound
        }
        
        guard var playlist = playlists.first(where: { $0.id == id }) else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        let updatedPlaylist = Shared.Playlist(
            id: playlist.id,
            name: name,
            trackCount: playlist.trackCount,
            totalDuration: playlist.totalDuration,
            isSmart: playlist.isSmart
        )
        
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            playlists[index] = updatedPlaylist
        }
    }
    
    public func deletePlaylist(id: UUID) async throws {
        deletePlaylistCalled = true
        deletePlaylistId = id
        
        if shouldFailDelete {
            throw PlaylistManagerError.playlistNotFound
        }
        
        guard playlists.contains(where: { $0.id == id }) else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        playlists.removeAll { $0.id == id }
    }
    
    public func addTrack(_ track: Track, to playlistId: UUID) async throws {
        // Mock implementation
    }
    
    public func removeTrack(_ track: Track, from playlistId: UUID) async throws {
        // Mock implementation
    }
    
    public func getTracks(in playlistId: UUID) async throws -> [Track] {
        []
    }
    
    public func reorderTracks(in playlistId: UUID, trackIds: [UUID]) async throws {
        // Mock implementation
    }
}
