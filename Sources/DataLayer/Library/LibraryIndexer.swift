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

// Import SearchField from LibrarySearch (same module, so we can reference it directly)
// SearchField is defined in LibrarySearch.swift as a public enum

/// Library indexer for managing indexed tracks
/// Uses in-memory storage for fast lookups
public final class LibraryIndexer: LibraryIndexerProtocol, @unchecked Sendable {
    
    /// Actor for thread-safe index operations
    private let indexActor = IndexActor()
    
    /// Initialize the indexer
    public init() {}
    
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
    
    /// Search tracks using optimized search index
    /// - Parameters:
    ///   - query: Normalized search query string (lowercased)
    ///   - field: Field to search in
    /// - Returns: Array of matching track IDs
    internal func searchTracks(query: String, field: SearchField) async -> [UUID] {
        await indexActor.search(query: query, field: field)
    }
}

/// Actor for thread-safe index operations
/// Optimized: Only indexes full words and numbers (minimal index size)
/// Prefix matching done at search time for better performance
private actor IndexActor {
    /// In-memory index of tracks by ID
    private var tracksById: [UUID: Track] = [:]
    
    /// In-memory index of tracks by file path (for duplicate detection)
    private var tracksByPath: [String: UUID] = [:]
    
    /// Minimal inverted index: only full words (no prefixes to reduce index size)
    private var wordIndex: [String: Set<UUID>] = [:]
    
    /// Number index: separate index for numeric searches
    private var numberIndex: [String: Set<UUID>] = [:]
    
    /// Minimum search term length to index (to avoid indexing single characters)
    private let minSearchTermLength = 2
    
    func index(tracks: [Track]) async throws {
        // Use optimized sequential processing - parallel overhead is too expensive
        // Process in batches to avoid memory issues with very large libraries
        let batchSize = 5000
        
        for batchStart in stride(from: 0, to: tracks.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, tracks.count)
            let batch = Array(tracks[batchStart..<batchEnd])
            
            // Process batch sequentially - much faster than parallel for this workload
            try processBatchSequentially(tracks: batch)
        }
    }
    
    /// Process tracks sequentially (optimized for performance)
    /// Only indexes full words and numbers - minimal overhead
    private func processBatchSequentially(tracks: [Track]) throws {
        var tracksToRemove: [UUID] = []
        
        for track in tracks {
            // Validate track has non-empty file path
            guard !track.filePath.isEmpty else {
                throw LibraryIndexerError.invalidTrack
            }
            
            // Handle duplicates
            if let existingId = tracksByPath[track.filePath], existingId != track.id {
                tracksToRemove.append(existingId)
                removeTrackFromIndex(trackId: existingId)
            }
            
            // Index only essential terms: full words and numbers
            indexTrackMinimal(track: track)
            
            // Add/update track
            tracksById[track.id] = track
            tracksByPath[track.filePath] = track.id
        }
        
        // Remove old duplicate tracks from main indexes
        for trackId in tracksToRemove {
            tracksById.removeValue(forKey: trackId)
            // Note: tracksByPath is already updated with the new track's ID above
        }
    }
    
    /// Index a track with minimal overhead - only full words and numbers
    private func indexTrackMinimal(track: Track) {
        let fields = [track.title, track.artist, track.album]
        
        for text in fields {
            let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Index words (full words only, no prefixes)
            let wordSeparators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_"))
            let words = normalized.components(separatedBy: wordSeparators)
                .filter { $0.count >= minSearchTermLength }
            
            for word in words {
                wordIndex[word, default: Set<UUID>()].insert(track.id)
            }
            
            // Index numbers separately
            let numbers = extractNumbers(from: normalized)
            for number in numbers {
                numberIndex[number, default: Set<UUID>()].insert(track.id)
            }
        }
    }
    
    /// Extract numbers from text
    private func extractNumbers(from text: String) -> [String] {
        var numbers: [String] = []
        let digitPattern = CharacterSet.decimalDigits
        var currentNumber = ""
        
        for char in text {
            guard let scalar = char.unicodeScalars.first, digitPattern.contains(scalar) else {
                if currentNumber.count >= minSearchTermLength {
                    numbers.append(currentNumber)
                }
                currentNumber = ""
                continue
            }
            currentNumber.append(char)
        }
        if currentNumber.count >= minSearchTermLength {
            numbers.append(currentNumber)
        }
        
        return numbers
    }
    
    /// Remove track from all indexes
    private func removeTrackFromIndex(trackId: UUID) {
        // Remove from word index
        for (word, trackIds) in wordIndex {
            var updated = trackIds
            updated.remove(trackId)
            if updated.isEmpty {
                wordIndex.removeValue(forKey: word)
            } else {
                wordIndex[word] = updated
            }
        }
        
        // Remove from number index
        for (number, trackIds) in numberIndex {
            var updated = trackIds
            updated.remove(trackId)
            if updated.isEmpty {
                numberIndex.removeValue(forKey: number)
            } else {
                numberIndex[number] = updated
            }
        }
    }
    
    func remove(track: Track) throws {
        guard tracksById[track.id] != nil else {
            throw LibraryIndexerError.trackNotFound
        }
        
        removeTrackFromIndex(trackId: track.id)
        tracksById.removeValue(forKey: track.id)
        tracksByPath.removeValue(forKey: track.filePath)
    }
    
    func clear() {
        tracksById.removeAll()
        tracksByPath.removeAll()
        wordIndex.removeAll()
        numberIndex.removeAll()
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
    
    /// Fast search using minimal index - exact matches only for performance
    /// - Parameters:
    ///   - query: Normalized search query (lowercased)
    ///   - field: Field to search in
    /// - Returns: Array of matching track IDs
    func search(query: String, field: SearchField) -> [UUID] {
        guard !query.isEmpty else {
            return []
        }

        if query.count < minSearchTermLength {
            return linearSearch(query: query, field: field)
        }
        
        let allTermMatches = collectTermMatches(from: query)
        
        guard !allTermMatches.isEmpty else {
            return linearSearch(query: query, field: field)
        }
        
        let candidates = intersectTermMatches(allTermMatches)
        return filterResults(candidates: candidates, query: query, field: field)
    }
    
    /// Collect all term matches from query words and numbers
    private func collectTermMatches(from query: String) -> [Set<UUID>] {
        let wordSeparators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_"))
        let queryWords = query.components(separatedBy: wordSeparators)
            .filter { $0.count >= minSearchTermLength }
        let queryNumbers = extractNumbers(from: query)
        
        var allTermMatches: [Set<UUID>] = []
        
        for word in queryWords {
            if let wordMatches = wordIndex[word] {
                allTermMatches.append(wordMatches)
            }
        }
        
        for number in queryNumbers {
            if let numberMatches = numberIndex[number] {
                allTermMatches.append(numberMatches)
            }
        }
        
        return allTermMatches
    }
    
    /// Intersect all term matches efficiently
    private func intersectTermMatches(_ allTermMatches: [Set<UUID>]) -> Set<UUID> {
        guard !allTermMatches.isEmpty else {
            return []
        }
        
        // Sort by size - start intersection with smallest set for efficiency
        let sortedMatches = allTermMatches.sorted { $0.count < $1.count }
        
        var candidates = sortedMatches[0]
        for termMatches in sortedMatches.dropFirst() {
            candidates = candidates.intersection(termMatches)
            if candidates.isEmpty {
                return []
            }
        }
        
        return candidates
    }
    
    /// Filter results by field and apply limits
    private func filterResults(candidates: Set<UUID>, query: String, field: SearchField) -> [UUID] {
        // Limit results early for performance
        let limitedCandidates = candidates.count > 1000 ? Set(candidates.prefix(1000)) : candidates
        
        if field == .all {
            return Array(limitedCandidates)
        }
        
        return limitedCandidates.filter { trackId in
            guard let track = tracksById[trackId] else { return false }
            return matchesQuery(track: track, query: query, field: field)
        }
    }
    
    /// Linear search fallback for queries that don't match indexed terms
    /// - Parameters:
    ///   - query: Normalized search query (lowercased)
    ///   - field: Field to search in
    /// - Returns: Array of matching track IDs
    private func linearSearch(query: String, field: SearchField) -> [UUID] {
        var matchingIds: [UUID] = []
        let limit = 1000 // Limit linear search results
        
        for (trackId, track) in tracksById where matchesQuery(track: track, query: query, field: field) {
            matchingIds.append(trackId)
            if matchingIds.count >= limit {
                break
            }
        }
        
        return matchingIds
    }
    
    /// Check if a track matches the search query
    private func matchesQuery(track: Track, query: String, field: SearchField) -> Bool {
        let normalizedQuery = query.lowercased()
        
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
}
