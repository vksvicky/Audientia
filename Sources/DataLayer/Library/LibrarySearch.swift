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
    
    /// Search for tracks with relevance ranking
    /// - Parameters:
    ///   - query: Search query string
    ///   - field: Field to search in (defaults to .all)
    /// - Returns: Array of matching tracks, sorted by relevance (title matches > artist > album, exact matches first)
    /// - Throws: Error if search fails
    public func search(query: String, field: SearchField = .all) async throws -> [Track] {
        // Normalize query: trim whitespace and convert to lowercase
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Empty query returns empty results
        guard !normalizedQuery.isEmpty else {
            return []
        }
        
        // Get all tracks from indexer
        let allTracks = await getAllTracks()
        
        // Filter and score tracks based on search field
        let scoredTracks = allTracks.compactMap { track -> (Track, Int)? in
            scoreTrack(track, query: normalizedQuery, field: field)
        }
        
        // Sort by score (descending) and return tracks
        return scoredTracks
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    
    /// Score a track based on search query and field
    /// - Parameters:
    ///   - track: The track to score
    ///   - query: The normalized search query
    ///   - field: The field to search in
    /// - Returns: Tuple of (track, score) if match found, nil otherwise
    private func scoreTrack(_ track: Track, query: String, field: SearchField) -> (Track, Int)? {
        let titleLower = track.title.lowercased()
        let artistLower = track.artist.lowercased()
        let albumLower = track.album.lowercased()
        
        var score = 0
        var matches = false
        
        switch field {
        case .title:
            if titleLower.contains(query) {
                matches = true
                score = calculateRelevanceScore(fieldValue: titleLower, query: query, baseScore: 100)
            }
        case .artist:
            if artistLower.contains(query) {
                matches = true
                score = calculateRelevanceScore(fieldValue: artistLower, query: query, baseScore: 50)
            }
        case .album:
            if albumLower.contains(query) {
                matches = true
                score = calculateRelevanceScore(fieldValue: albumLower, query: query, baseScore: 25)
            }
        case .all:
            (matches, score) = scoreAllFields(title: titleLower, artist: artistLower, album: albumLower, query: query)
        }
        
        return matches ? (track, score) : nil
    }
    
    /// Score a track when searching all fields
    /// - Parameters:
    ///   - title: Lowercased title
    ///   - artist: Lowercased artist
    ///   - album: Lowercased album
    ///   - query: The normalized search query
    /// - Returns: Tuple of (hasMatch, totalScore)
    private func scoreAllFields(title: String, artist: String, album: String, query: String) -> (Bool, Int) {
        var hasMatch = false
        var score = 0
        
        if title.contains(query) {
            hasMatch = true
            score += calculateRelevanceScore(fieldValue: title, query: query, baseScore: 100)
        }
        if artist.contains(query) {
            hasMatch = true
            score += calculateRelevanceScore(fieldValue: artist, query: query, baseScore: 50)
        }
        if album.contains(query) {
            hasMatch = true
            score += calculateRelevanceScore(fieldValue: album, query: query, baseScore: 25)
        }
        
        return (hasMatch, score)
    }
    
    /// Calculate relevance score for a field match
    /// - Parameters:
    ///   - fieldValue: The field value to check
    ///   - query: The search query
    ///   - baseScore: Base score for this field type
    /// - Returns: Relevance score (higher = more relevant)
    private func calculateRelevanceScore(fieldValue: String, query: String, baseScore: Int) -> Int {
        // Exact match gets highest score
        if fieldValue == query {
            return baseScore * 2
        }
        
        // Starts with query gets high score
        if fieldValue.hasPrefix(query) {
            return baseScore + 10
        }
        
        // Contains query gets base score
        return baseScore
    }
    
    /// Get all tracks from the indexer
    /// - Returns: Array of all indexed tracks
    private func getAllTracks() async -> [Track] {
        await indexer.getAllTracks()
    }
}
