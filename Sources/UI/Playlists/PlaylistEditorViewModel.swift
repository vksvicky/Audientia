//
//  PlaylistEditorViewModel.swift
//  Audientia - Playlist Editor ViewModel
//
//  ViewModel for editing individual playlists
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import DataLayer
import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for playlist editing
/// Manages playlist details, tracks, and editing operations
@MainActor
public final class PlaylistEditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current playlist being edited
    @Published public private(set) var playlist: Shared.Playlist?
    
    /// Tracks in the playlist
    @Published public private(set) var tracks: [Shared.Track] = []
    
    /// Whether tracks are currently being loaded
    @Published public private(set) var isLoading = false
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let playlistManager: any PlaylistManagerProtocol
    private var currentPlaylistId: UUID?
    
    // MARK: - Initialization
    
    /// Initialize with PlaylistManager
    /// - Parameter playlistManager: The playlist manager to use
    public init(playlistManager: any PlaylistManagerProtocol) {
        self.playlistManager = playlistManager
        Logger.userInterface.info("PlaylistEditorViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    /// Load a playlist and its tracks
    /// - Parameter id: Playlist ID
    public func loadPlaylist(id: UUID) async {
        isLoading = true
        lastError = nil
        currentPlaylistId = id
        
        playlist = await playlistManager.getPlaylist(by: id)
        if let playlist = playlist {
            do {
                tracks = try await playlistManager.getTracks(in: playlist.id)
                Logger.userInterface.debug("Loaded playlist: \(playlist.name) with \(self.tracks.count) tracks")
            } catch {
                lastError = error
                Logger.userInterface.error("Failed to load playlist tracks: \(error.localizedDescription)")
                tracks = []
            }
        } else {
            tracks = []
            Logger.userInterface.warning("Playlist not found: \(id)")
        }
        
        isLoading = false
    }
    
    /// Add a track to the playlist
    /// - Parameter track: Track to add
    /// - Throws: Error if addition fails
    public func addTrack(_ track: Shared.Track) async throws {
        guard let playlistId = currentPlaylistId else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        lastError = nil
        
        do {
            try await playlistManager.addTrack(track, to: playlistId)
            await loadPlaylist(id: playlistId) // Reload to get updated tracks
            Logger.userInterface.info("Added track: \(track.title) to playlist")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to add track: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Remove a track from the playlist
    /// - Parameter track: Track to remove
    /// - Throws: Error if removal fails
    public func removeTrack(_ track: Shared.Track) async throws {
        guard let playlistId = currentPlaylistId else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        lastError = nil
        
        do {
            try await playlistManager.removeTrack(track, from: playlistId)
            await loadPlaylist(id: playlistId) // Reload to get updated tracks
            Logger.userInterface.info("Removed track: \(track.title) from playlist")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to remove track: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update the playlist's name
    /// - Parameter name: New playlist name
    /// - Throws: Error if update fails
    public func updatePlaylistName(_ name: String) async throws {
        guard let playlistId = currentPlaylistId else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        lastError = nil
        
        do {
            try await playlistManager.updatePlaylist(id: playlistId, name: name)
            await loadPlaylist(id: playlistId) // Reload to get updated playlist
            Logger.userInterface.info("Updated playlist name to: \(name)")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to update playlist name: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Reorder tracks in the playlist
    /// - Parameter trackIds: Array of track IDs in the desired order
    /// - Throws: Error if reordering fails
    public func reorderTracks(_ trackIds: [UUID]) async throws {
        guard let playlistId = currentPlaylistId else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        lastError = nil
        
        do {
            try await playlistManager.reorderTracks(in: playlistId, trackIds: trackIds)
            await loadPlaylist(id: playlistId) // Reload to get updated tracks
            Logger.userInterface.info("Reordered tracks in playlist")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to reorder tracks: \(error.localizedDescription)")
            throw error
        }
    }
}
