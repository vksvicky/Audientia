//
//  LibraryIndexer.swift
//  DataLayer
//
//  Library indexer implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Library indexer for managing indexed tracks
/// Uses in-memory storage for fast lookups
public final class LibraryIndexer: LibraryIndexerProtocol, @unchecked Sendable {
    
    /// Actor for thread-safe index operations
    private let indexActor: IndexActor
    
    /// Initialize the indexer
    public init(normalizer: MetadataNormalizerProtocol = MetadataNormalizer()) {
        self.indexActor = IndexActor(normalizer: normalizer)
    }
    
    /// Index a collection of tracks
    /// - Parameter tracks: Array of tracks to index
    /// - Throws: Error if indexing fails
    public func index(tracks: [Track]) async throws {
        try await indexActor.index(tracks: tracks)
    }
    
    /// Remove a track from the index
    /// - Parameter track: Track to remove
    /// - Throws: Error if removal fails
    public func remove(track: Track) async throws {
        try await indexActor.remove(track: track)
    }
    
    /// Clear all tracks from the index
    /// - Throws: Error if clearing fails
    public func clear() async throws {
        await indexActor.clear()
    }
    
    /// Get a track by its ID
    /// - Parameter id: Track ID
    /// - Returns: Track if found, nil otherwise
    public func getTrack(by id: UUID) async -> Track? {
        await indexActor.getTrack(by: id)
    }
    
    /// Get the count of indexed tracks
    /// - Returns: Number of indexed tracks
    public func getIndexedTrackCount() async -> Int {
        await indexActor.getCount()
    }
    
    /// Get all indexed tracks
    /// - Returns: Array of all indexed tracks
    public func getAllTracks() async -> [Track] {
        await indexActor.getAllTracks()
    }
}

/// Actor for thread-safe index operations
private actor IndexActor {
    /// In-memory index of tracks by ID
    private var tracksById: [UUID: Track] = [:]
    
    /// In-memory index of tracks by file path (for duplicate detection)
    private var tracksByPath: [String: UUID] = [:]
    
    /// Normalizer applied before storing tracks
    private let normalizer: MetadataNormalizerProtocol
    
    init(normalizer: MetadataNormalizerProtocol) {
        self.normalizer = normalizer
    }
    
    func index(tracks: [Track]) throws {
        for original in tracks {
            let track = normalizer.normalize(track: original)
            // Validate track has non-empty file path
            guard !track.filePath.isEmpty else {
                throw LibraryIndexerError.invalidTrack
            }
            
            // Handle duplicates: if track with same path exists, replace it
            if let existingId = tracksByPath[track.filePath], existingId != track.id {
                // Remove old track
                tracksById.removeValue(forKey: existingId)
            }
            
            // Add/update track
            tracksById[track.id] = track
            tracksByPath[track.filePath] = track.id
        }
    }
    
    func remove(track: Track) throws {
        guard tracksById[track.id] != nil else {
            throw LibraryIndexerError.trackNotFound
        }
        
        tracksById.removeValue(forKey: track.id)
        tracksByPath.removeValue(forKey: track.filePath)
    }
    
    func clear() {
        tracksById.removeAll()
        tracksByPath.removeAll()
    }
    
    func getTrack(by id: UUID) -> Track? {
        tracksById[id]
    }
    
    func getCount() -> Int {
        tracksById.count
    }
    
    func getAllTracks() -> [Track] {
        Array(tracksById.values)
    }
}
