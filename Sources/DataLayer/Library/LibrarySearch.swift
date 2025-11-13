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
        
        // Use optimized search index if available (LibraryIndexer)
        if let optimizedIndexer = indexer as? LibraryIndexer {
            let matchingIds = await optimizedIndexer.searchTracks(query: normalizedQuery, field: field)
            // Convert IDs to tracks in parallel for better performance
            return await withTaskGroup(of: Track?.self) { group in
                for id in matchingIds {
                    group.addTask {
                        await optimizedIndexer.getTrack(by: id)
                    }
                }
                
                var matchingTracks: [Track] = []
                for await track in group {
                    if let track = track {
                        matchingTracks.append(track)
                    }
                }
                return matchingTracks
            }
        }
        
        // Fallback to linear search for other indexer implementations
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
