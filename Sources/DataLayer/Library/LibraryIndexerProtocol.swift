//
//  LibraryIndexerProtocol.swift
//  DataLayer
//
//  Protocol for library indexing functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for indexing tracks in the library
public protocol LibraryIndexerProtocol: Sendable {
    /// Index a collection of tracks
    /// - Parameter tracks: Array of tracks to index
    /// - Throws: Error if indexing fails
    func index(tracks: [Track]) async throws
    
    /// Remove a track from the index
    /// - Parameter track: Track to remove
    /// - Throws: Error if removal fails
    func remove(track: Track) async throws
    
    /// Clear all tracks from the index
    /// - Throws: Error if clearing fails
    func clear() async throws
    
    /// Get a track by its ID
    /// - Parameter id: Track ID
    /// - Returns: Track if found, nil otherwise
    func getTrack(by id: UUID) async -> Track?
    
    /// Get the count of indexed tracks
    /// - Returns: Number of indexed tracks
    func getIndexedTrackCount() async -> Int
    
    /// Get all indexed tracks
    /// - Returns: Array of all indexed tracks
    func getAllTracks() async -> [Track]
}

/// Errors that can occur during indexing
public enum LibraryIndexerError: Error {
    case invalidTrack
    case indexingFailed
    case trackNotFound
}
