//
//  MockPlaylistSidebarComponents.swift
//  UITests
//
//  Shared mock implementation of PlaylistManagerProtocol for PlaylistSidebarViewModel tests
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

@testable import DataLayer
@testable import Shared

/// Mock playlist manager for PlaylistSidebarViewModel tests
actor PlaylistSidebarMockPlaylistManager: PlaylistManagerProtocol {
    private var playlists: [Playlist] = []
    private var shouldThrowError = false
    private var shouldFailCreate = false
    private(set) var lastError: Error?
    
    func setPlaylists(_ playlists: [Playlist]) async {
        self.playlists = playlists
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) async {
        shouldThrowError = shouldThrow
    }
    
    func setShouldFailCreate(_ shouldFail: Bool) async {
        shouldFailCreate = shouldFail
    }
    
    func getAllPlaylists() async -> [Playlist] {
        // Note: Protocol doesn't allow throwing, so return empty array when error should occur
        if shouldThrowError {
            lastError = PlaylistManagerError.operationFailed
            return []
        }
        lastError = nil
        return playlists
    }
    
    // MARK: - Playlist Creation
    
    func createPlaylist(name: String) async throws -> Playlist {
        if shouldFailCreate {
            throw PlaylistManagerError.operationFailed
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        // Check for duplicates (case-insensitive)
        if playlists.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PlaylistManagerError.duplicatePlaylist
        }
        
        let newPlaylist = Playlist(
            id: UUID(),
            name: trimmedName,
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: false
        )
        
        playlists.append(newPlaylist)
        return newPlaylist
    }
    
    func createSmartPlaylist(name: String, rules: SmartPlaylistRules) async throws -> Playlist {
        if shouldFailCreate {
            throw PlaylistManagerError.operationFailed
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        guard rules.isValid else {
            throw PlaylistManagerError.invalidRules
        }
        
        // Check for duplicates (case-insensitive)
        if playlists.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PlaylistManagerError.duplicatePlaylist
        }
        
        let newPlaylist = Playlist(
            id: UUID(),
            name: trimmedName,
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: true
        )
        
        playlists.append(newPlaylist)
        return newPlaylist
    }
    
    func getPlaylist(by id: UUID) async -> Playlist? {
        nil
    }
    
    func updatePlaylist(id: UUID, name: String) async throws {
        throw PlaylistManagerError.operationFailed
    }
    
    func deletePlaylist(id: UUID) async throws {
        throw PlaylistManagerError.operationFailed
    }
    
    func addTrack(_ track: Track, to playlistId: UUID) async throws {
        throw PlaylistManagerError.operationFailed
    }
    
    func removeTrack(_ track: Track, from playlistId: UUID) async throws {
        throw PlaylistManagerError.operationFailed
    }
    
    func getTracks(in playlistId: UUID) async throws -> [Track] {
        throw PlaylistManagerError.operationFailed
    }
    
    func reorderTracks(in playlistId: UUID, trackIds: [UUID]) async throws {
        throw PlaylistManagerError.operationFailed
    }
}
