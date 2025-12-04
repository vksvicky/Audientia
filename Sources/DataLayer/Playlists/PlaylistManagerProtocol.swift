//
//  PlaylistManagerProtocol.swift
//  DataLayer
//
//  Protocol for playlist management functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for managing playlists
public protocol PlaylistManagerProtocol: Sendable {
    /// Create a new regular playlist
    /// - Parameter name: Playlist name
    /// - Returns: Created playlist
    /// - Throws: Error if creation fails
    func createPlaylist(name: String) async throws -> Playlist
    
    /// Create a new smart playlist with rules
    /// - Parameters:
    ///   - name: Playlist name
    ///   - rules: Smart playlist rules
    /// - Returns: Created smart playlist
    /// - Throws: Error if creation fails
    func createSmartPlaylist(name: String, rules: SmartPlaylistRules) async throws -> Playlist
    
    /// Get a playlist by ID
    /// - Parameter id: Playlist ID
    /// - Returns: Playlist if found, nil otherwise
    func getPlaylist(by id: UUID) async -> Playlist?
    
    /// Get all playlists
    /// - Returns: Array of all playlists
    func getAllPlaylists() async -> [Playlist]
    
    /// Update a playlist's name
    /// - Parameters:
    ///   - id: Playlist ID
    ///   - name: New playlist name
    /// - Throws: Error if update fails
    func updatePlaylist(id: UUID, name: String) async throws
    
    /// Delete a playlist
    /// - Parameter id: Playlist ID
    /// - Throws: Error if deletion fails
    func deletePlaylist(id: UUID) async throws
    
    /// Add a track to a playlist
    /// - Parameters:
    ///   - track: Track to add
    ///   - playlistId: Playlist ID
    /// - Throws: Error if addition fails
    func addTrack(_ track: Track, to playlistId: UUID) async throws
    
    /// Remove a track from a playlist
    /// - Parameters:
    ///   - track: Track to remove
    ///   - playlistId: Playlist ID
    /// - Throws: Error if removal fails
    func removeTrack(_ track: Track, from playlistId: UUID) async throws
    
    /// Get all tracks in a playlist
    /// - Parameter playlistId: Playlist ID
    /// - Returns: Array of tracks in the playlist
    /// - Throws: Error if retrieval fails
    func getTracks(in playlistId: UUID) async throws -> [Track]
    
    /// Reorder tracks in a playlist
    /// - Parameters:
    ///   - playlistId: Playlist ID
    ///   - trackIds: Array of track IDs in the desired order
    /// - Throws: Error if reordering fails
    func reorderTracks(in playlistId: UUID, trackIds: [UUID]) async throws
}

/// Errors that can occur during playlist operations
public enum PlaylistManagerError: Error {
    case playlistNotFound
    case invalidPlaylistName
    case duplicatePlaylist
    case trackNotFound
    case duplicateTrack
    case invalidRules
    case operationFailed
}
