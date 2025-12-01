//
//  PlaylistPanelViewModel.swift
//  Audientia - Playlist Panel ViewModel
//
//  ViewModel for the playlist panel in the multi-pane layout
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for the playlist panel
/// Manages playlist browsing, selection, and track management
@MainActor
public final class PlaylistPanelViewModel: ObservableObject {
    // MARK: - Published Properties

    /// List of all playlists
    @Published public private(set) var playlists: [Playlist] = []

    /// Currently selected playlist
    @Published public private(set) var selectedPlaylist: Playlist?

    /// Tracks in the selected playlist
    @Published public private(set) var tracks: [Track] = []

    /// Whether data is currently being loaded
    @Published public private(set) var isLoading = false

    /// Last error that occurred
    @Published public private(set) var lastError: Error?

    // MARK: - Private Properties

    private let playlistManager: any PlaylistManagerProtocol
    private let indexer: any LibraryIndexerProtocol
    private let logger = Logger.userInterface

    // MARK: - Initialisation

    /// Initialise with dependencies
    /// - Parameters:
    ///   - playlistManager: The playlist manager to use
    ///   - indexer: The library indexer for track lookups
    public init(
        playlistManager: (any PlaylistManagerProtocol)? = nil,
        indexer: (any LibraryIndexerProtocol)? = nil
    ) {
        self.playlistManager = playlistManager ?? PlaylistManager(indexer: LibraryIndexer())
        self.indexer = indexer ?? LibraryIndexer()
        logger.info("PlaylistPanelViewModel initialised")
    }

    // MARK: - Public Methods

    /// Load all playlists
    public func loadPlaylists() async {
        isLoading = true
        lastError = nil

        playlists = await playlistManager.getAllPlaylists()
        logger.debug("Loaded \(self.playlists.count) playlists")

        isLoading = false
    }

    /// Select a playlist and load its tracks
    /// - Parameter playlist: The playlist to select
    public func selectPlaylist(_ playlist: Playlist) async {
        selectedPlaylist = playlist
        lastError = nil

        do {
            tracks = try await playlistManager.getTracks(in: playlist.id)
            logger.debug("Loaded \(self.tracks.count) tracks for playlist: \(playlist.name)")
        } catch {
            lastError = error
            logger.error("Failed to load playlist tracks: \(error.localizedDescription)")
            tracks = []
        }
    }

    /// Add a track to the selected playlist
    /// - Parameter track: The track to add
    /// - Throws: Error if addition fails
    public func addTrack(_ track: Track) async throws {
        guard let playlistId = selectedPlaylist?.id else {
            throw PlaylistManagerError.playlistNotFound
        }

        lastError = nil

        do {
            try await playlistManager.addTrack(track, to: playlistId)
            if let playlist = selectedPlaylist {
                await selectPlaylist(playlist) // Reload tracks
            }
            logger.info("Added track: \(track.title) to playlist")
        } catch {
            lastError = error
            logger.error("Failed to add track: \(error.localizedDescription)")
            throw error
        }
    }

    /// Remove a track from the selected playlist
    /// - Parameter track: The track to remove
    /// - Throws: Error if removal fails
    public func removeTrack(_ track: Track) async throws {
        guard let playlistId = selectedPlaylist?.id else {
            throw PlaylistManagerError.playlistNotFound
        }

        lastError = nil

        do {
            try await playlistManager.removeTrack(track, from: playlistId)
            if let playlist = selectedPlaylist {
                await selectPlaylist(playlist) // Reload tracks
            }
            logger.info("Removed track: \(track.title) from playlist")
        } catch {
            lastError = error
            logger.error("Failed to remove track: \(error.localizedDescription)")
            throw error
        }
    }

    /// Create a new playlist
    /// - Parameter name: The name of the playlist
    /// - Returns: The created playlist
    /// - Throws: Error if creation fails
    @discardableResult
    public func createPlaylist(name: String) async throws -> Playlist {
        lastError = nil

        do {
            let playlist = try await playlistManager.createPlaylist(name: name)
            await loadPlaylists() // Reload to get updated list
            logger.info("Created playlist: \(name)")
            return playlist
        } catch {
            lastError = error
            logger.error("Failed to create playlist: \(error.localizedDescription)")
            throw error
        }
    }

    /// Delete a playlist
    /// - Parameter playlist: The playlist to delete
    /// - Throws: Error if deletion fails
    public func deletePlaylist(_ playlist: Playlist) async throws {
        lastError = nil

        do {
            try await playlistManager.deletePlaylist(id: playlist.id)
            if selectedPlaylist?.id == playlist.id {
                selectedPlaylist = nil
                tracks = []
            }
            await loadPlaylists() // Reload to get updated list
            logger.info("Deleted playlist: \(playlist.name)")
        } catch {
            lastError = error
            logger.error("Failed to delete playlist: \(error.localizedDescription)")
            throw error
        }
    }

    /// Clear the last error
    public func clearLastError() {
        lastError = nil
    }
}
