//
//  PlaylistViewModel.swift
//  Audientia - Playlist ViewModel
//
//  ViewModel for playlist management UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import DataLayer
import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for playlist management
/// Manages playlist list, creation, deletion, and updates
@MainActor
public final class PlaylistViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of all playlists
    @Published public private(set) var playlists: [Shared.Playlist] = []
    
    /// Whether playlists are currently being loaded
    @Published public private(set) var isLoading = false
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let playlistManager: any PlaylistManagerProtocol
    
    // MARK: - Initialization
    
    /// Initialize with PlaylistManager
    /// - Parameter playlistManager: The playlist manager to use
    public init(playlistManager: any PlaylistManagerProtocol) {
        self.playlistManager = playlistManager
        Logger.userInterface.info("PlaylistViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    /// Load all playlists
    public func loadPlaylists() async {
        isLoading = true
        lastError = nil
        
        playlists = await playlistManager.getAllPlaylists()
        Logger.userInterface.debug("Loaded \(self.playlists.count) playlists")
        
        isLoading = false
    }
    
    /// Create a new playlist
    /// - Parameter name: Playlist name
    /// - Returns: Created playlist
    /// - Throws: Error if creation fails
    @discardableResult
    public func createPlaylist(name: String) async throws -> Shared.Playlist {
        lastError = nil
        
        do {
            let playlist = try await playlistManager.createPlaylist(name: name)
            await loadPlaylists() // Reload to get updated list
            Logger.userInterface.info("Created playlist: \(name)")
            return playlist
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to create playlist: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Delete a playlist
    /// - Parameter id: Playlist ID
    /// - Throws: Error if deletion fails
    public func deletePlaylist(id: UUID) async throws {
        lastError = nil
        
        do {
            try await playlistManager.deletePlaylist(id: id)
            await loadPlaylists() // Reload to get updated list
            Logger.userInterface.info("Deleted playlist: \(id)")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to delete playlist: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update a playlist's name
    /// - Parameters:
    ///   - id: Playlist ID
    ///   - name: New playlist name
    /// - Throws: Error if update fails
    public func updatePlaylistName(id: UUID, name: String) async throws {
        lastError = nil
        
        do {
            try await playlistManager.updatePlaylist(id: id, name: name)
            await loadPlaylists() // Reload to get updated list
            Logger.userInterface.info("Updated playlist: \(id) to name: \(name)")
        } catch {
            lastError = error
            Logger.userInterface.error("Failed to update playlist: \(error.localizedDescription)")
            throw error
        }
    }
}
