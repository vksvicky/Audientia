//
//  PlaylistManager.swift
//  DataLayer
//
//  Playlist management implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Playlist manager implementation
public final class PlaylistManager: PlaylistManagerProtocol, @unchecked Sendable {
    
    private let indexer: LibraryIndexerProtocol
    private let playlistActor = PlaylistActor()
    
    /// Initialize with a library indexer
    /// - Parameter indexer: Library indexer for track lookups
    public init(indexer: LibraryIndexerProtocol) {
        self.indexer = indexer
    }
    
    /// Create a new regular playlist
    public func createPlaylist(name: String) async throws -> Playlist {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        return try await playlistActor.createPlaylist(name: name, isSmart: false, rules: nil)
    }
    
    /// Create a new smart playlist with rules
    public func createSmartPlaylist(name: String, rules: SmartPlaylistRules) async throws -> Playlist {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        guard rules.isValid else {
            throw PlaylistManagerError.invalidRules
        }
        
        return try await playlistActor.createPlaylist(name: name, isSmart: true, rules: rules)
    }
    
    /// Get a playlist by ID
    public func getPlaylist(by id: UUID) async -> Playlist? {
        await playlistActor.getPlaylist(by: id)
    }
    
    /// Get all playlists
    public func getAllPlaylists() async -> [Playlist] {
        await playlistActor.getAllPlaylists()
    }
    
    /// Update a playlist's name
    public func updatePlaylist(id: UUID, name: String) async throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlaylistManagerError.invalidPlaylistName
        }
        
        try await playlistActor.updatePlaylist(id: id, name: name)
    }
    
    /// Delete a playlist
    public func deletePlaylist(id: UUID) async throws {
        try await playlistActor.deletePlaylist(id: id)
    }
    
    /// Add a track to a playlist
    public func addTrack(_ track: Track, to playlistId: UUID) async throws {
        // Verify track exists in indexer
        let existingTrack = await indexer.getTrack(by: track.id)
        guard existingTrack != nil else {
            throw PlaylistManagerError.trackNotFound
        }
        
        try await playlistActor.addTrack(track, to: playlistId)
        
        // Update playlist statistics
        let trackIds = try await playlistActor.getTrackIds(in: playlistId)
        var totalDuration: TimeInterval = 0.0
        for trackId in trackIds {
            if let resolvedTrack = await indexer.getTrack(by: trackId) {
                totalDuration += resolvedTrack.duration
            }
        }
        await playlistActor.updatePlaylistStatistics(
            playlistId: playlistId,
            trackCount: trackIds.count,
            totalDuration: totalDuration
        )
    }
    
    /// Remove a track from a playlist
    public func removeTrack(_ track: Track, from playlistId: UUID) async throws {
        try await playlistActor.removeTrack(track, from: playlistId)
        
        // Update playlist statistics
        let trackIds = try await playlistActor.getTrackIds(in: playlistId)
        var totalDuration: TimeInterval = 0.0
        for trackId in trackIds {
            if let resolvedTrack = await indexer.getTrack(by: trackId) {
                totalDuration += resolvedTrack.duration
            }
        }
        await playlistActor.updatePlaylistStatistics(
            playlistId: playlistId,
            trackCount: trackIds.count,
            totalDuration: totalDuration
        )
    }
    
    /// Get all tracks in a playlist
    public func getTracks(in playlistId: UUID) async throws -> [Track] {
        let trackIds = try await playlistActor.getTrackIds(in: playlistId)
        
        // Resolve track IDs to actual Track objects using indexer
        var tracks: [Track] = []
        for trackId in trackIds {
            if let track = await indexer.getTrack(by: trackId) {
                tracks.append(track)
            }
        }
        
        return tracks
    }
    
    /// Reorder tracks in a playlist
    public func reorderTracks(in playlistId: UUID, trackIds: [UUID]) async throws {
        try await playlistActor.reorderTracks(in: playlistId, trackIds: trackIds)
    }
}

/// Actor for thread-safe playlist operations
private actor PlaylistActor {
    /// In-memory storage of playlists
    private var playlists: [UUID: PlaylistData] = [:]
    
    /// In-memory storage of playlist tracks (playlist ID -> ordered track IDs)
    private var playlistTracks: [UUID: [UUID]] = [:]
    
    /// Structure to hold playlist data
    private struct PlaylistData {
        var playlist: Playlist
        var rules: SmartPlaylistRules?
        
        init(playlist: Playlist, rules: SmartPlaylistRules? = nil) {
            self.playlist = playlist
            self.rules = rules
        }
    }
    
    func createPlaylist(name: String, isSmart: Bool, rules: SmartPlaylistRules?) throws -> Playlist {
        let playlist = Playlist(
            id: UUID(),
            name: name,
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: isSmart
        )
        
        playlists[playlist.id] = PlaylistData(playlist: playlist, rules: rules)
        playlistTracks[playlist.id] = []
        
        return playlist
    }
    
    func getPlaylist(by id: UUID) -> Playlist? {
        playlists[id]?.playlist
    }
    
    func getAllPlaylists() -> [Playlist] {
        Array(playlists.values.map { $0.playlist })
    }
    
    func updatePlaylist(id: UUID, name: String) throws {
        guard var playlistData = playlists[id] else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        let updatedPlaylist = Playlist(
            id: playlistData.playlist.id,
            name: name,
            trackCount: playlistData.playlist.trackCount,
            totalDuration: playlistData.playlist.totalDuration,
            isSmart: playlistData.playlist.isSmart
        )
        
        playlistData.playlist = updatedPlaylist
        playlists[id] = playlistData
    }
    
    func deletePlaylist(id: UUID) throws {
        guard playlists[id] != nil else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        playlists.removeValue(forKey: id)
        playlistTracks.removeValue(forKey: id)
    }
    
    func addTrack(_ track: Track, to playlistId: UUID) throws {
        guard playlists[playlistId] != nil else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        guard var trackIds = playlistTracks[playlistId] else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        // Check for duplicate
        if trackIds.contains(track.id) {
            throw PlaylistManagerError.duplicateTrack
        }
        
        // Add track
        trackIds.append(track.id)
        playlistTracks[playlistId] = trackIds
    }
    
    func removeTrack(_ track: Track, from playlistId: UUID) throws {
        guard playlists[playlistId] != nil else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        guard var trackIds = playlistTracks[playlistId] else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        guard let index = trackIds.firstIndex(of: track.id) else {
            throw PlaylistManagerError.trackNotFound
        }
        
        trackIds.remove(at: index)
        playlistTracks[playlistId] = trackIds
    }
    
    func getTrackIds(in playlistId: UUID) throws -> [UUID] {
        guard playlists[playlistId] != nil else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        guard let trackIds = playlistTracks[playlistId] else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        return trackIds
    }
    
    func reorderTracks(in playlistId: UUID, trackIds: [UUID]) throws {
        guard playlists[playlistId] != nil else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        // Validate all track IDs exist in current playlist
        guard let currentTrackIds = playlistTracks[playlistId] else {
            throw PlaylistManagerError.playlistNotFound
        }
        
        // Verify all provided track IDs are in the playlist
        let currentSet = Set(currentTrackIds)
        let providedSet = Set(trackIds)
        
        guard currentSet == providedSet else {
            throw PlaylistManagerError.trackNotFound
        }
        
        playlistTracks[playlistId] = trackIds
    }
    
    /// Update playlist statistics (track count and duration)
    /// Note: Duration calculation requires track data, which will be updated
    /// when tracks are added/removed via the manager
    func updatePlaylistStatistics(playlistId: UUID, trackCount: Int, totalDuration: TimeInterval) {
        guard var playlistData = playlists[playlistId] else {
            return
        }
        
        let updatedPlaylist = Playlist(
            id: playlistData.playlist.id,
            name: playlistData.playlist.name,
            trackCount: trackCount,
            totalDuration: totalDuration,
            isSmart: playlistData.playlist.isSmart
        )
        
        playlistData.playlist = updatedPlaylist
        playlists[playlistId] = playlistData
    }
}
