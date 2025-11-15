//
//  LibrarySearch.swift
//  DataLayer
//
//  Library search implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Search field options
public enum SearchField {
    case title
    case artist
    case album
    case all
}

/// Library search implementation
public final class LibrarySearch: @unchecked Sendable {
    
    private let indexer: LibraryIndexerProtocol
    
    /// Initialize with an indexer
    /// - Parameter indexer: The indexer to search
    public init(indexer: LibraryIndexerProtocol) {
        self.indexer = indexer
    }
    
    /// Search for tracks
    /// - Parameters:
    ///   - query: Search query string
    ///   - field: Field to search in (defaults to .all)
    /// - Returns: Array of matching tracks
    /// - Throws: Error if search fails
    public func search(query: String, field: SearchField = .all) async throws -> [Track] {
        // Normalize query: trim whitespace and convert to lowercase
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Empty query returns empty results
        guard !normalizedQuery.isEmpty else {
            return []
        }
        
        // Get all tracks from indexer (for now, we'll need to add a method to get all tracks)
        // For this implementation, we'll use a simple approach: get tracks by iterating
        // In a real implementation, we'd have a more efficient way to get all tracks
        let allTracks = await getAllTracks()
        
        // Filter tracks based on search field
        let matchingTracks = allTracks.filter { track in
            switch field {
            case .title:
                return track.title.lowercased().contains(normalizedQuery)
            case .artist:
                return track.artist.lowercased().contains(normalizedQuery)
            case .album:
                return track.album.lowercased().contains(normalizedQuery)
            case .all:
                return track.title.lowercased().contains(normalizedQuery) ||
                       track.artist.lowercased().contains(normalizedQuery) ||
                       track.album.lowercased().contains(normalizedQuery)
            }
        }
        
        return matchingTracks
    }
    
    /// Get all tracks from the indexer
    /// - Returns: Array of all indexed tracks
    private func getAllTracks() async -> [Track] {
        await indexer.getAllTracks()
    }
}
